import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, shallowRef } from 'vue'
import {
  api,
  type Organization,
  type OrganizationInput,
  type ManagedUser,
  type UserListParams,
  type UserPaginationMeta,
  type UserProfileInput,
} from '@/services/api'

const defaultUsersMeta: UserPaginationMeta = {
  current_page: 1,
  total_pages: 1,
  total_count: 0,
  per_page: 10,
}

function sortOrganizations(organizations: readonly Organization[]) {
  return [...organizations].sort((first, second) => first.name.localeCompare(second.name))
}

function syncOrganizationMembership(users: readonly ManagedUser[], organization: Organization) {
  return users.map((user) => {
    const organizationIds = organization.user_ids.includes(user.id)
      ? [...new Set([...user.organization_ids, organization.id])]
      : user.organization_ids.filter((organizationId) => organizationId !== organization.id)

    return {
      ...user,
      organization_ids: organizationIds,
      organizations_count: organizationIds.length,
    }
  })
}

export const useOrganizationsStore = defineStore('organizations', () => {
  const users = shallowRef<ManagedUser[]>([])
  const usersMeta = shallowRef<UserPaginationMeta>({ ...defaultUsersMeta })
  const organizations = shallowRef<Organization[]>([])
  const loadingUsers = shallowRef(false)
  const loadingOrganizations = shallowRef(false)
  const saving = shallowRef(false)
  const error = shallowRef<string | null>(null)

  const organizationLookup = computed(() => new Map(organizations.value.map((organization) => [organization.id, organization])))
  const loading = computed(() => loadingUsers.value || loadingOrganizations.value)

  async function loadDirectory() {
    error.value = null

    try {
      await Promise.all([loadUsers({ page: 1 }), loadOrganizations()])
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load users and organizations'
    }
  }

  async function loadUsers(params: UserListParams = {}) {
    loadingUsers.value = true
    error.value = null

    try {
      const response = await api.listUsers({
        page: params.page ?? usersMeta.value.current_page,
        perPage: params.perPage ?? usersMeta.value.per_page,
      })
      users.value = response.users
      usersMeta.value = response.meta
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load users'
    } finally {
      loadingUsers.value = false
    }
  }

  async function loadOrganizations() {
    loadingOrganizations.value = true
    error.value = null

    try {
      organizations.value = sortOrganizations(await api.listOrganizations())
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load organizations'
    } finally {
      loadingOrganizations.value = false
    }
  }

  async function updateUserProfile(userId: number, input: UserProfileInput) {
    saving.value = true
    error.value = null

    try {
      const user = await api.updateUser(userId, input)
      users.value = users.value.map((item) => (item.id === user.id ? user : item))
      return user
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to update user profile'
      throw err
    } finally {
      saving.value = false
    }
  }

  async function loadUser(userId: number) {
    loadingUsers.value = true
    error.value = null

    try {
      const user = await api.getUser(userId)
      users.value = users.value.some((item) => item.id === user.id)
        ? users.value.map((item) => (item.id === user.id ? user : item))
        : [user, ...users.value]
      return user
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load user profile'
      throw err
    } finally {
      loadingUsers.value = false
    }
  }

  async function createOrganization(input: OrganizationInput) {
    saving.value = true
    error.value = null

    try {
      const organization = await api.createOrganization(input)
      organizations.value = sortOrganizations([...organizations.value, organization])
      users.value = syncOrganizationMembership(users.value, organization)
      return organization
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to create organization'
      throw err
    } finally {
      saving.value = false
    }
  }

  async function updateOrganization(organizationId: number, input: OrganizationInput) {
    saving.value = true
    error.value = null

    try {
      const organization = await api.updateOrganization(organizationId, input)
      organizations.value = sortOrganizations(organizations.value.map((item) => (item.id === organization.id ? organization : item)))
      users.value = syncOrganizationMembership(users.value, organization)
      return organization
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to update organization'
      throw err
    } finally {
      saving.value = false
    }
  }

  async function deleteOrganization(organizationId: number) {
    saving.value = true
    error.value = null

    try {
      await api.deleteOrganization(organizationId)
      organizations.value = organizations.value.filter((organization) => organization.id !== organizationId)
      users.value = users.value.map((user) => {
        const organizationIds = user.organization_ids.filter((id) => id !== organizationId)

        return {
          ...user,
          organization_ids: organizationIds,
          organizations_count: organizationIds.length,
        }
      })
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to delete organization'
      throw err
    } finally {
      saving.value = false
    }
  }

  function clearDirectory() {
    users.value = []
    usersMeta.value = { ...defaultUsersMeta }
    organizations.value = []
    error.value = null
  }

  return {
    users,
    usersMeta,
    organizations,
    loading,
    loadingUsers,
    loadingOrganizations,
    saving,
    error,
    organizationLookup,
    loadDirectory,
    loadUsers,
    loadUser,
    loadOrganizations,
    updateUserProfile,
    createOrganization,
    updateOrganization,
    deleteOrganization,
    clearDirectory,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useOrganizationsStore, import.meta.hot))
}
