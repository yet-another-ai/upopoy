import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useOrganizationsStore } from '../organizations'
import { api, type Organization, type ManagedUser, type PaginatedUsers } from '@/services/api'

vi.mock('@/services/api', () => ({
  api: {
    listUsers: vi.fn(),
    getUser: vi.fn(),
    updateUser: vi.fn(),
    listOrganizations: vi.fn(),
    createOrganization: vi.fn(),
    updateOrganization: vi.fn(),
    deleteOrganization: vi.fn(),
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
    system_admin: false,
    organization_ids: [],
    organizations_count: 0,
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

const organizations: Organization[] = [
  {
    id: 2,
    name: 'Product',
    description: null,
    user_ids: [],
    users_count: 0,
    admin_user_ids: [],
    admins_count: 0,
    can_admin: false,
    created_at: timestamp,
    updated_at: timestamp,
  },
  {
    id: 1,
    name: 'Engineering',
    description: null,
    user_ids: [1],
    users_count: 1,
    admin_user_ids: [1],
    admins_count: 1,
    can_admin: true,
    created_at: timestamp,
    updated_at: timestamp,
  },
]

describe('useOrganizationsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('loads users and organizations as a directory', async () => {
    vi.mocked(api.listUsers).mockResolvedValue(usersResponse)
    vi.mocked(api.listOrganizations).mockResolvedValue(organizations)
    const store = useOrganizationsStore()

    await store.loadDirectory()

    expect(store.users).toEqual(users)
    expect(store.organizations.map((organization) => organization.name)).toEqual(['Engineering', 'Product'])
    expect(store.organizationLookup.get(1)?.name).toBe('Engineering')
  })

  it('syncs user memberships when creating a organization', async () => {
    const organization = {
      ...organizations[0],
      id: 3,
      name: 'Research',
      user_ids: [1],
      users_count: 1,
      admin_user_ids: [1],
      admins_count: 1,
      can_admin: true,
    }
    vi.mocked(api.createOrganization).mockResolvedValue(organization)
    const store = useOrganizationsStore()
    store.users = users

    await store.createOrganization({ name: 'Research', user_ids: [1] })

    expect(store.organizations.map((item) => item.name)).toEqual(['Research'])
    expect(store.organizations[0].admin_user_ids).toEqual([1])
    expect(store.organizations[0].can_admin).toBe(true)
    expect(store.users[0].organization_ids).toEqual([3])
    expect(store.users[0].organizations_count).toBe(1)
  })

  it('removes deleted organizations from cached users', async () => {
    vi.mocked(api.deleteOrganization).mockResolvedValue(undefined)
    const store = useOrganizationsStore()
    store.organizations = [organizations[0]]
    store.users = [{ ...users[0], organization_ids: [2], organizations_count: 1 }]

    await store.deleteOrganization(2)

    expect(store.organizations).toEqual([])
    expect(store.users[0].organization_ids).toEqual([])
    expect(store.users[0].organizations_count).toBe(0)
  })

  it('throws save errors while exposing the message in state', async () => {
    vi.mocked(api.updateUser).mockRejectedValue(new Error('Email is invalid'))
    const store = useOrganizationsStore()

    await expect(store.updateUserProfile(1, { email: 'bad' })).rejects.toThrow('Email is invalid')

    expect(store.error).toBe('Email is invalid')
    expect(store.saving).toBe(false)
  })
})
