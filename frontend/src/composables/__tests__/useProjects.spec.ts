import { describe, expect, it, vi, beforeEach } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useProjects } from '../useProjects'
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
    name: 'MVP',
    description: 'Initial Kanban surface',
    created_at: '2026-07-06T00:00:00Z',
    updated_at: '2026-07-06T00:00:00Z',
  },
]

describe('useProjects', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('loads projects and selects the first project by default', async () => {
    vi.mocked(api.listProjects).mockResolvedValue(projects)
    const state = useProjects()

    await state.loadProjects()

    expect(state.projects.value).toEqual(projects)
    expect(state.selectedProjectId.value).toBe(1)
    expect(state.selectedProject.value?.name).toBe('MVP')
  })

  it('prepends and selects a newly created project', async () => {
    const created = { ...projects[0], id: 2, name: 'Agent workflows' }
    vi.mocked(api.createProject).mockResolvedValue(created)
    const state = useProjects()

    await state.createProject({ name: 'Agent workflows' })

    expect(state.projects.value).toEqual([created])
    expect(state.selectedProjectId.value).toBe(2)
  })
})
