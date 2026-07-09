import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useBoardStore } from '../board'
import { api, type Board, type Task } from '@/services/api'

vi.mock('@/services/api', () => ({
  api: {
    getBoard: vi.fn(),
    createIteration: vi.fn(),
    createTask: vi.fn(),
    updateTask: vi.fn(),
    deleteTask: vi.fn(),
  },
}))

const task: Task = {
  id: 1,
  project_id: 1,
  iteration_id: 1,
  iteration_name: 'Inbox',
  iteration_starts_at: null,
  iteration_deadline: null,
  iteration_inbox: true,
  status: 'todo',
  priority: 'medium',
  title: 'Define API resources',
  description: 'Keep MCP-friendly shapes.',
  deadline: null,
  estimated_minutes: null,
  developer_ids: [],
  developers: [],
  reviewer_ids: [],
  reviewers: [],
  position: 1,
  created_at: '2026-07-06T00:00:00Z',
  updated_at: '2026-07-06T00:00:00Z',
}

const board: Board = {
  project: {
    id: 1,
    owner_type: 'Organization',
    owner_id: 1,
    owner_name: 'Engineering',
    name: 'MVP',
    description: 'Initial Kanban surface',
    created_at: '2026-07-06T00:00:00Z',
    updated_at: '2026-07-06T00:00:00Z',
  },
  iterations: [
    {
      id: 1,
      project_id: 1,
      name: 'Inbox',
      starts_at: null,
      deadline: null,
      inbox: true,
      task_count: 1,
      created_at: '2026-07-06T00:00:00Z',
      updated_at: '2026-07-06T00:00:00Z',
    },
  ],
  inbox_iteration: {
    id: 1,
    project_id: 1,
    name: 'Inbox',
    starts_at: null,
    deadline: null,
    inbox: true,
    task_count: 1,
    created_at: '2026-07-06T00:00:00Z',
    updated_at: '2026-07-06T00:00:00Z',
  },
  statuses: [
    {
      id: 'todo',
      name: 'To Do',
      slug: 'todo',
      position: 0,
      tasks: [task],
    },
    {
      id: 'done',
      name: 'Done',
      slug: 'done',
      position: 3,
      tasks: [],
    },
  ],
}

describe('useBoardStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('loads a board and derives the task count', async () => {
    vi.mocked(api.getBoard).mockResolvedValue(board)
    const store = useBoardStore()

    await store.loadBoard(1)

    expect(store.project?.name).toBe('MVP')
    expect(store.statuses).toHaveLength(2)
    expect(store.taskCount).toBe(1)
  })

  it('moves an updated task into its target status locally', async () => {
    vi.mocked(api.getBoard).mockResolvedValue(board)
    vi.mocked(api.updateTask).mockResolvedValue({ ...task, status: 'done', position: 0 })
    const store = useBoardStore()

    await store.loadBoard(1)
    await store.updateTask(1, { status: 'done', position: 0 })

    expect(store.statuses[0].tasks).toEqual([])
    expect(store.statuses[1].tasks.map((item) => item.id)).toEqual([1])
  })

  it('removes deleted tasks from every status', async () => {
    vi.mocked(api.getBoard).mockResolvedValue(board)
    vi.mocked(api.deleteTask).mockResolvedValue(undefined)
    const store = useBoardStore()

    await store.loadBoard(1)
    await store.deleteTask(1)

    expect(store.statuses.flatMap((status) => status.tasks)).toEqual([])
  })

  it('captures load errors and clears loading state', async () => {
    vi.mocked(api.getBoard).mockRejectedValue(new Error('Board unavailable'))
    const store = useBoardStore()

    await store.loadBoard(1)

    expect(store.error).toBe('Board unavailable')
    expect(store.loading).toBe(false)
  })
})
