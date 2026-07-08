import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useUserGroupsStore } from '../userGroups'
import { api, type Group, type ManagedUser, type PaginatedUsers } from '@/services/api'

vi.mock('@/services/api', () => ({
  api: {
    listUsers: vi.fn(),
    getUser: vi.fn(),
    updateUser: vi.fn(),
    listGroups: vi.fn(),
    createGroup: vi.fn(),
    updateGroup: vi.fn(),
    deleteGroup: vi.fn(),
  },
}))

const timestamp = '2026-07-06T00:00:00Z'

const users: ManagedUser[] = [
  {
    id: 1,
    email: 'ada@example.com',
    display_name: 'Ada Lovelace',
    title: null,
    bio: null,
    group_ids: [],
    groups_count: 0,
    created_at: timestamp,
    updated_at: timestamp,
  },
]

const usersResponse: PaginatedUsers = {
  users,
  meta: {
    current_page: 1,
    total_pages: 1,
    total_count: 1,
    per_page: 10,
  },
}

const groups: Group[] = [
  {
    id: 2,
    name: 'Product',
    description: null,
    parent_group_id: null,
    parent_group_name: null,
    user_ids: [],
    users_count: 0,
    created_at: timestamp,
    updated_at: timestamp,
  },
  {
    id: 1,
    name: 'Engineering',
    description: null,
    parent_group_id: null,
    parent_group_name: null,
    user_ids: [1],
    users_count: 1,
    created_at: timestamp,
    updated_at: timestamp,
  },
]

describe('useUserGroupsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('loads users and groups as a directory', async () => {
    vi.mocked(api.listUsers).mockResolvedValue(usersResponse)
    vi.mocked(api.listGroups).mockResolvedValue(groups)
    const store = useUserGroupsStore()

    await store.loadDirectory()

    expect(store.users).toEqual(users)
    expect(store.groups.map((group) => group.name)).toEqual(['Engineering', 'Product'])
    expect(store.groupLookup.get(1)?.name).toBe('Engineering')
  })

  it('syncs user memberships when creating a group', async () => {
    const group = { ...groups[0], id: 3, name: 'Research', user_ids: [1], users_count: 1 }
    vi.mocked(api.createGroup).mockResolvedValue(group)
    const store = useUserGroupsStore()
    store.users = users

    await store.createGroup({ name: 'Research', user_ids: [1] })

    expect(store.groups.map((item) => item.name)).toEqual(['Research'])
    expect(store.users[0].group_ids).toEqual([3])
    expect(store.users[0].groups_count).toBe(1)
  })

  it('removes deleted groups from cached users', async () => {
    vi.mocked(api.deleteGroup).mockResolvedValue(undefined)
    const store = useUserGroupsStore()
    store.groups = [groups[0]]
    store.users = [{ ...users[0], group_ids: [2], groups_count: 1 }]

    await store.deleteGroup(2)

    expect(store.groups).toEqual([])
    expect(store.users[0].group_ids).toEqual([])
    expect(store.users[0].groups_count).toBe(0)
  })

  it('throws save errors while exposing the message in state', async () => {
    vi.mocked(api.updateUser).mockRejectedValue(new Error('Email is invalid'))
    const store = useUserGroupsStore()

    await expect(store.updateUserProfile(1, { email: 'bad' })).rejects.toThrow('Email is invalid')

    expect(store.error).toBe('Email is invalid')
    expect(store.saving).toBe(false)
  })
})
