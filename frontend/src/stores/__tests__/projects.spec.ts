import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useProjectsStore } from '../projects'
import { api, type Project } from '@/services/api'

vi.mock('@/services/api', () => ({
  api: {
    listProjects: vi.fn(),
    createProject: vi.fn(),
  },
}))

const projects: Project[] = [
  {
    id: 1,
    group_id: 1,
    group_name: 'Engineering',
    name: 'MVP',
    description: 'Initial Kanban surface',
    created_at: '2026-07-06T00:00:00Z',
    updated_at: '2026-07-06T00:00:00Z',
  },
]

describe('useProjectsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('loads projects and selects the first project by default', async () => {
    vi.mocked(api.listProjects).mockResolvedValue(projects)
    const store = useProjectsStore()

    await store.loadProjects()

    expect(store.projects).toEqual(projects)
    expect(store.selectedProjectId).toBe(1)
    expect(store.selectedProject?.name).toBe('MVP')
  })

  it('prepends and selects a newly created project', async () => {
    const created = { ...projects[0], id: 2, name: 'Agent workflows' }
    vi.mocked(api.createProject).mockResolvedValue(created)
    const store = useProjectsStore()

    await store.createProject({ name: 'Agent workflows', group_id: 1 })

    expect(store.projects).toEqual([created])
    expect(store.selectedProjectId).toBe(2)
  })

  it('captures load failures without replacing existing project state', async () => {
    vi.mocked(api.listProjects).mockRejectedValue(new Error('Network down'))
    const store = useProjectsStore()
    store.projects = projects

    await store.loadProjects()

    expect(store.projects).toEqual(projects)
    expect(store.error).toBe('Network down')
    expect(store.loading).toBe(false)
  })
})
