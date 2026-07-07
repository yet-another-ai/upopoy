<script setup lang="ts">
import { computed } from 'vue'
import { TabsContent, TabsList, TabsRoot, TabsTrigger } from 'reka-ui'
import { RouterLink } from 'vue-router'
import GroupCreateDialog from '@/components/user-groups/GroupCreateDialog.vue'
import GroupsTab from '@/components/user-groups/GroupsTab.vue'
import UsersTab from '@/components/user-groups/UsersTab.vue'
import GroupEditorView from '@/views/GroupEditorView.vue'
import UserProfileView from '@/views/UserProfileView.vue'
import type {
  Group,
  GroupInput,
  ManagedUser,
  UserListParams,
  UserPaginationMeta,
  UserProfileInput,
} from '@/services/api'

const props = defineProps<{
  users: readonly ManagedUser[]
  usersMeta: UserPaginationMeta
  groups: readonly Group[]
  loading: boolean
  loadingUsers: boolean
  loadingGroups: boolean
  saving: boolean
  section: 'users' | 'groups'
  userId: number | null
  groupId: number | null
  creatingGroup: boolean
}>()

const emit = defineEmits<{
  loadUsers: [params: UserListParams]
  loadUser: [userId: number]
  loadGroups: []
  editUser: [userId: number]
  createGroup: []
  selectGroup: [groupId: number]
  closeGroupEditor: []
  saveUserProfile: [userId: number, input: UserProfileInput]
  saveGroup: [groupId: number | null, input: GroupInput]
  deleteGroup: [groupId: number]
}>()

const activeTab = computed(() => props.section)

function saveUserProfile(userId: number, input: UserProfileInput) {
  emit('saveUserProfile', userId, input)
}

function saveGroup(groupId: number | null, input: GroupInput) {
  emit('saveGroup', groupId, input)
}
</script>

<template>
  <TabsRoot :model-value="activeTab" class="grid gap-5">
    <TabsList
      class="bg-muted text-muted-foreground grid w-full max-w-sm grid-cols-2 rounded-lg p-1"
      aria-label="Users and groups sections"
    >
      <TabsTrigger
        value="users"
        as-child
        class="data-[state=active]:bg-background data-[state=active]:text-foreground focus-visible:ring-ring rounded-md px-3 py-1.5 text-sm font-medium transition outline-none focus-visible:ring-2 data-[state=active]:shadow-xs"
      >
        <RouterLink :to="{ name: 'users' }">Users</RouterLink>
      </TabsTrigger>
      <TabsTrigger
        value="groups"
        as-child
        class="data-[state=active]:bg-background data-[state=active]:text-foreground focus-visible:ring-ring rounded-md px-3 py-1.5 text-sm font-medium transition outline-none focus-visible:ring-2 data-[state=active]:shadow-xs"
      >
        <RouterLink :to="{ name: 'groups' }">Groups</RouterLink>
      </TabsTrigger>
    </TabsList>

    <TabsContent value="users" class="outline-none">
      <UserProfileView
        v-if="props.userId"
        :user-id="props.userId"
        :users="props.users"
        :groups="props.groups"
        :loading="props.loadingUsers"
        :saving="props.saving"
        @load-user="emit('loadUser', $event)"
        @load-groups="emit('loadGroups')"
        @save-user-profile="saveUserProfile"
      />

      <UsersTab
        v-else
        :users="props.users"
        :groups="props.groups"
        :meta="props.usersMeta"
        :loading="props.loadingUsers"
        @load-users="emit('loadUsers', $event)"
        @edit-user="emit('editUser', $event)"
      />
    </TabsContent>

    <TabsContent value="groups" class="outline-none">
      <GroupEditorView
        v-if="props.groupId"
        :group-id="props.groupId"
        :users="props.users"
        :groups="props.groups"
        :loading="props.loadingGroups || props.loading"
        :saving="props.saving"
        @load-groups="emit('loadGroups')"
        @save-group="saveGroup"
        @close-group-editor="emit('closeGroupEditor')"
      />

      <template v-else>
        <GroupsTab
          :groups="props.groups"
          :loading="props.loadingGroups || props.loading"
          @create-group="emit('createGroup')"
          @select-group="emit('selectGroup', $event)"
          @delete-group="emit('deleteGroup', $event)"
        />

        <GroupCreateDialog
          :open="props.creatingGroup"
          :users="props.users"
          :groups="props.groups"
          :saving="props.saving"
          @close="emit('closeGroupEditor')"
          @save-group="saveGroup"
        />
      </template>
    </TabsContent>
  </TabsRoot>
</template>
