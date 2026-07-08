import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, shallowRef } from 'vue'
import {
  api,
  type Group,
  type GroupInput,
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

function sortGroups(groups: readonly Group[]) {
  return [...groups].sort((first, second) => first.name.localeCompare(second.name))
}

function syncGroupMembership(users: readonly ManagedUser[], group: Group) {
  return users.map((user) => {
    const groupIds = group.user_ids.includes(user.id)
      ? [...new Set([...user.group_ids, group.id])]
      : user.group_ids.filter((groupId) => groupId !== group.id)

    return {
      ...user,
      group_ids: groupIds,
      groups_count: groupIds.length,
    }
  })
}

export const useUserGroupsStore = defineStore('userGroups', () => {
  const users = shallowRef<ManagedUser[]>([])
  const usersMeta = shallowRef<UserPaginationMeta>({ ...defaultUsersMeta })
  const groups = shallowRef<Group[]>([])
  const loadingUsers = shallowRef(false)
  const loadingGroups = shallowRef(false)
  const saving = shallowRef(false)
  const error = shallowRef<string | null>(null)

  const groupLookup = computed(() => new Map(groups.value.map((group) => [group.id, group])))
  const loading = computed(() => loadingUsers.value || loadingGroups.value)

  async function loadDirectory() {
    error.value = null

    try {
      await Promise.all([loadUsers({ page: 1 }), loadGroups()])
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load users and groups'
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

  async function loadGroups() {
    loadingGroups.value = true
    error.value = null

    try {
      groups.value = sortGroups(await api.listGroups())
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load groups'
    } finally {
      loadingGroups.value = false
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

  async function createGroup(input: GroupInput) {
    saving.value = true
    error.value = null

    try {
      const group = await api.createGroup(input)
      groups.value = sortGroups([...groups.value, group])
      users.value = syncGroupMembership(users.value, group)
      return group
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to create group'
      throw err
    } finally {
      saving.value = false
    }
  }

  async function updateGroup(groupId: number, input: GroupInput) {
    saving.value = true
    error.value = null

    try {
      const group = await api.updateGroup(groupId, input)
      groups.value = sortGroups(groups.value.map((item) => (item.id === group.id ? group : item)))
      users.value = syncGroupMembership(users.value, group)
      return group
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to update group'
      throw err
    } finally {
      saving.value = false
    }
  }

  async function deleteGroup(groupId: number) {
    saving.value = true
    error.value = null

    try {
      await api.deleteGroup(groupId)
      groups.value = groups.value.filter((group) => group.id !== groupId)
      users.value = users.value.map((user) => {
        const groupIds = user.group_ids.filter((id) => id !== groupId)

        return {
          ...user,
          group_ids: groupIds,
          groups_count: groupIds.length,
        }
      })
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to delete group'
      throw err
    } finally {
      saving.value = false
    }
  }

  function clearDirectory() {
    users.value = []
    usersMeta.value = { ...defaultUsersMeta }
    groups.value = []
    error.value = null
  }

  return {
    users,
    usersMeta,
    groups,
    loading,
    loadingUsers,
    loadingGroups,
    saving,
    error,
    groupLookup,
    loadDirectory,
    loadUsers,
    loadUser,
    loadGroups,
    updateUserProfile,
    createGroup,
    updateGroup,
    deleteGroup,
    clearDirectory,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useUserGroupsStore, import.meta.hot))
}
