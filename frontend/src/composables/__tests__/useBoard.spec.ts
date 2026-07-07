import { describe, expect, it, vi, beforeEach } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useBoard } from '../useBoard'
import { api, type Board, type Task } from '@/services/api'

vi.mock('@/services/api', () => ({
  api: {
    getBoard: vi.fn(),
    createTask: vi.fn(),
    updateTask: vi.fn(),
    deleteTask: vi.fn(),
  },
}))

const task: Task = {
  id: 1,
  project_id: 1,
  status: 'todo',
  priority: 'medium',
  title: 'Define API resources',
  description: 'Keep MCP-friendly shapes.',
  deadline: null,
  estimated_minutes: null,
  position: 1,
  created_at: '2026-07-06T00:00:00Z',
  updated_at: '2026-07-06T00:00:00Z',
}

const board: Board = {
  project: {
    id: 1,
    group_id: 1,
    group_name: 'Engineering',
    name: 'MVP',
    description: 'Initial Kanban surface',
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

describe('useBoard', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('loads a board and derives the task count', async () => {
    vi.mocked(api.getBoard).mockResolvedValue(board)
    const state = useBoard()

    await state.loadBoard(1)

    expect(state.project.value?.name).toBe('MVP')
    expect(state.statuses.value).toHaveLength(2)
    expect(state.taskCount.value).toBe(1)
  })

  it('moves an updated task into its target status locally', async () => {
    vi.mocked(api.getBoard).mockResolvedValue(board)
    vi.mocked(api.updateTask).mockResolvedValue({ ...task, status: 'done', position: 0 })
    const state = useBoard()

    await state.loadBoard(1)
    await state.updateTask(1, { status: 'done', position: 0 })

    expect(state.statuses.value[0].tasks).toEqual([])
    expect(state.statuses.value[1].tasks.map((item) => item.id)).toEqual([1])
  })
})
