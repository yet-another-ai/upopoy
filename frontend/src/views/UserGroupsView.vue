<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, onMounted, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { TabsContent, TabsList, TabsRoot, TabsTrigger } from 'reka-ui'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import GroupCreateDialog from '@/components/user-groups/GroupCreateDialog.vue'
import GroupsTab from '@/components/user-groups/GroupsTab.vue'
import UsersTab from '@/components/user-groups/UsersTab.vue'
import { positiveIntegerRouteParam } from '@/lib/route'
import { useToastsStore } from '@/stores/toasts'
import { useAuthStore } from '@/stores/auth'
import { useUserGroupsStore } from '@/stores/userGroups'
import GroupEditorView from '@/views/GroupEditorView.vue'
import UserProfileView from '@/views/UserProfileView.vue'
import type { GroupInput, UserProfileInput } from '@/services/api'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const userGroupsStore = useUserGroupsStore()
const toasts = useToastsStore()
const auth = storeToRefs(authStore)
const userGroups = storeToRefs(userGroupsStore)
const { t } = useI18n()

const section = computed<'users' | 'groups'>(() =>
  route.name === 'groups' || route.name === 'group-new' || route.name === 'group-detail'
    ? 'groups'
    : 'users',
)
const activeTab = computed(() => section.value)
const userId = computed(() => positiveIntegerRouteParam(route, 'userId'))
const groupId = computed(() => positiveIntegerRouteParam(route, 'groupId'))
const editingUser = computed(() => route.name === 'user-edit')
const creatingGroup = computed(() => route.name === 'group-new')
const canManageSystemAdmins = computed(() => Boolean(auth.user.value?.system_admin))

onMounted(() => {
  void userGroupsStore.loadDirectory()
})

watch(
  () => route.name,
  () => {
    if (userGroups.groups.value.length === 0 && userGroups.users.value.length === 0) {
      void userGroupsStore.loadDirectory()
    }
  },
)

async function saveUserProfile(userId: number, input: UserProfileInput) {
  try {
    await userGroupsStore.updateUserProfile(userId, input)
  } catch (err) {
    notifyError(err, 'Unable to update user profile')
    return
  }

  await router.push({ name: 'user-profile', params: { userId } })
}

async function saveGroup(groupId: number | null, input: GroupInput) {
  try {
    if (groupId) await userGroupsStore.updateGroup(groupId, input)
    else await userGroupsStore.createGroup(input)
  } catch (err) {
    notifyError(err, groupId ? 'Unable to update group' : 'Unable to create group')
    return
  }

  await router.push({ name: 'groups' })
}

async function deleteGroup(groupId: number) {
  try {
    await userGroupsStore.deleteGroup(groupId)
  } catch (err) {
    notifyError(err, 'Unable to delete group')
  }
}

function editUser(userId: number) {
  void router.push({ name: 'user-profile', params: { userId } })
}

function cancelUserEdit() {
  if (userId.value) void router.push({ name: 'user-profile', params: { userId: userId.value } })
  else void router.push({ name: 'users' })
}

function selectGroup(groupId: number) {
  void router.push({ name: 'group-detail', params: { groupId } })
}

function createGroup() {
  void router.push({ name: 'group-new' })
}

function closeGroupEditor() {
  void router.push({ name: 'groups' })
}

function notifyError(err: unknown, fallback: string) {
  toasts.error(fallback, err instanceof Error ? err.message : fallback)
}
</script>

<template>
  <TabsRoot :model-value="activeTab" class="grid gap-5">
    <TabsList
      class="bg-muted text-muted-foreground grid w-full max-w-sm grid-cols-2 rounded-lg p-1"
      :aria-label="t('users.sectionsLabel')"
    >
      <TabsTrigger
        value="users"
        as-child
        class="data-[state=active]:bg-background data-[state=active]:text-foreground focus-visible:ring-ring rounded-md px-3 py-1.5 text-sm font-medium transition outline-none focus-visible:ring-2 data-[state=active]:shadow-xs"
      >
        <RouterLink :to="{ name: 'users' }">{{ t('users.users') }}</RouterLink>
      </TabsTrigger>
      <TabsTrigger
        value="groups"
        as-child
        class="data-[state=active]:bg-background data-[state=active]:text-foreground focus-visible:ring-ring rounded-md px-3 py-1.5 text-sm font-medium transition outline-none focus-visible:ring-2 data-[state=active]:shadow-xs"
      >
        <RouterLink :to="{ name: 'groups' }">{{ t('users.groups') }}</RouterLink>
      </TabsTrigger>
    </TabsList>

    <TabsContent value="users" class="outline-none">
      <UserProfileView
        v-if="userId"
        :user-id="userId"
        :users="userGroups.users.value"
        :groups="userGroups.groups.value"
        :loading="userGroups.loadingUsers.value"
        :saving="userGroups.saving.value"
        :editing="editingUser"
        :can-manage-system-admins="canManageSystemAdmins"
        @load-user="userGroupsStore.loadUser"
        @load-groups="userGroupsStore.loadGroups"
        @save-user-profile="saveUserProfile"
        @cancel-edit="cancelUserEdit"
      />

      <UsersTab
        v-else
        :users="userGroups.users.value"
        :groups="userGroups.groups.value"
        :meta="userGroups.usersMeta.value"
        :loading="userGroups.loadingUsers.value"
        @load-users="userGroupsStore.loadUsers"
        @edit-user="editUser"
      />
    </TabsContent>

    <TabsContent value="groups" class="outline-none">
      <GroupEditorView
        v-if="groupId"
        :group-id="groupId"
        :users="userGroups.users.value"
        :groups="userGroups.groups.value"
        :loading="userGroups.loadingGroups.value || userGroups.loading.value"
        :saving="userGroups.saving.value"
        @load-groups="userGroupsStore.loadGroups"
        @save-group="saveGroup"
        @close-group-editor="closeGroupEditor"
      />

      <template v-else>
        <GroupsTab
          :groups="userGroups.groups.value"
          :loading="userGroups.loadingGroups.value || userGroups.loading.value"
          @create-group="createGroup"
          @select-group="selectGroup"
          @delete-group="deleteGroup"
        />

        <GroupCreateDialog
          :open="creatingGroup"
          :users="userGroups.users.value"
          :groups="userGroups.groups.value"
          :saving="userGroups.saving.value"
          @close="closeGroupEditor"
          @save-group="saveGroup"
        />
      </template>
    </TabsContent>
  </TabsRoot>
</template>
