<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, onMounted, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { TabsContent, TabsList, TabsRoot, TabsTrigger } from 'reka-ui'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import OrganizationCreateDialog from '@/components/organizations/OrganizationCreateDialog.vue'
import OrganizationsTab from '@/components/organizations/OrganizationsTab.vue'
import UsersTab from '@/components/organizations/UsersTab.vue'
import { positiveIntegerRouteParam } from '@/lib/route'
import { useToastsStore } from '@/stores/toasts'
import { useAuthStore } from '@/stores/auth'
import { useOrganizationsStore } from '@/stores/organizations'
import OrganizationEditorView from '@/views/OrganizationEditorView.vue'
import UserProfileView from '@/views/UserProfileView.vue'
import type { OrganizationInput, UserProfileInput } from '@/services/api'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const organizationsStore = useOrganizationsStore()
const toasts = useToastsStore()
const auth = storeToRefs(authStore)
const organizations = storeToRefs(organizationsStore)
const { t } = useI18n()

const section = computed<'users' | 'organizations'>(() =>
  route.name === 'organizations' || route.name === 'organization-new' || route.name === 'organization-detail'
    ? 'organizations'
    : 'users',
)
const activeTab = computed(() => section.value)
const userId = computed(() => positiveIntegerRouteParam(route, 'userId'))
const organizationId = computed(() => positiveIntegerRouteParam(route, 'organizationId'))
const editingUser = computed(() => route.name === 'user-edit')
const creatingOrganization = computed(() => route.name === 'organization-new')
const canManageSystemAdmins = computed(() => Boolean(auth.user.value?.system_admin))

onMounted(() => {
  void organizationsStore.loadDirectory()
})

watch(
  () => route.name,
  () => {
    if (organizations.organizations.value.length === 0 && organizations.users.value.length === 0) {
      void organizationsStore.loadDirectory()
    }
  },
)

async function saveUserProfile(userId: number, input: UserProfileInput) {
  try {
    await organizationsStore.updateUserProfile(userId, input)
  } catch (err) {
    notifyError(err, 'Unable to update user profile')
    return
  }

  await router.push({ name: 'user-profile', params: { userId } })
}

async function saveOrganization(organizationId: number | null, input: OrganizationInput) {
  try {
    if (organizationId) await organizationsStore.updateOrganization(organizationId, input)
    else await organizationsStore.createOrganization(input)
  } catch (err) {
    notifyError(err, organizationId ? 'Unable to update organization' : 'Unable to create organization')
    return
  }

  await router.push({ name: 'organizations' })
}

async function deleteOrganization(organizationId: number) {
  try {
    await organizationsStore.deleteOrganization(organizationId)
  } catch (err) {
    notifyError(err, 'Unable to delete organization')
  }
}

function editUser(userId: number) {
  void router.push({ name: 'user-profile', params: { userId } })
}

function cancelUserEdit() {
  if (userId.value) void router.push({ name: 'user-profile', params: { userId: userId.value } })
  else void router.push({ name: 'users' })
}

function selectOrganization(organizationId: number) {
  void router.push({ name: 'organization-detail', params: { organizationId } })
}

function createOrganization() {
  void router.push({ name: 'organization-new' })
}

function closeOrganizationEditor() {
  void router.push({ name: 'organizations' })
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
        value="organizations"
        as-child
        class="data-[state=active]:bg-background data-[state=active]:text-foreground focus-visible:ring-ring rounded-md px-3 py-1.5 text-sm font-medium transition outline-none focus-visible:ring-2 data-[state=active]:shadow-xs"
      >
        <RouterLink :to="{ name: 'organizations' }">{{ t('users.organizations') }}</RouterLink>
      </TabsTrigger>
    </TabsList>

    <TabsContent value="users" class="outline-none">
      <UserProfileView
        v-if="userId"
        :user-id="userId"
        :users="organizations.users.value"
        :organizations="organizations.organizations.value"
        :loading="organizations.loadingUsers.value"
        :saving="organizations.saving.value"
        :editing="editingUser"
        :can-manage-system-admins="canManageSystemAdmins"
        @load-user="organizationsStore.loadUser"
        @load-organizations="organizationsStore.loadOrganizations"
        @save-user-profile="saveUserProfile"
        @cancel-edit="cancelUserEdit"
      />

      <UsersTab
        v-else
        :users="organizations.users.value"
        :organizations="organizations.organizations.value"
        :meta="organizations.usersMeta.value"
        :loading="organizations.loadingUsers.value"
        @load-users="organizationsStore.loadUsers"
        @edit-user="editUser"
      />
    </TabsContent>

    <TabsContent value="organizations" class="outline-none">
      <OrganizationEditorView
        v-if="organizationId"
        :organization-id="organizationId"
        :users="organizations.users.value"
        :organizations="organizations.organizations.value"
        :loading="organizations.loadingOrganizations.value || organizations.loading.value"
        :saving="organizations.saving.value"
        @load-organizations="organizationsStore.loadOrganizations"
        @save-organization="saveOrganization"
        @close-organization-editor="closeOrganizationEditor"
      />

      <template v-else>
        <OrganizationsTab
          :organizations="organizations.organizations.value"
          :loading="organizations.loadingOrganizations.value || organizations.loading.value"
          @create-organization="createOrganization"
          @select-organization="selectOrganization"
          @delete-organization="deleteOrganization"
        />

        <OrganizationCreateDialog
          :open="creatingOrganization"
          :users="organizations.users.value"
          :saving="organizations.saving.value"
          @close="closeOrganizationEditor"
          @save-organization="saveOrganization"
        />
      </template>
    </TabsContent>
  </TabsRoot>
</template>
