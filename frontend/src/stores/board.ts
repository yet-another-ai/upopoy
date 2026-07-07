import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, shallowRef } from 'vue'
import {
  api,
  type Board,
  type BoardStatus,
  type Iteration,
  type IterationInput,
  type Project,
  type Task,
  type TaskInput,
} from '@/services/api'

export const useBoardStore = defineStore('board', () => {
  const project = shallowRef<Project | null>(null)
  const statuses = shallowRef<BoardStatus[]>([])
  const iterations = shallowRef<Iteration[]>([])
  const inboxIteration = shallowRef<Iteration | null>(null)
  const loading = shallowRef(false)
  const error = shallowRef<string | null>(null)

  const taskCount = computed(() =>
    statuses.value.reduce((count, status) => count + status.tasks.length, 0),
  )

  async function loadBoard(projectId: number) {
    loading.value = true
    error.value = null

    try {
      const board = await api.getBoard(projectId)
      setBoard(board)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load board'
    } finally {
      loading.value = false
    }
  }

  async function createTask(projectId: number, input: TaskInput) {
    await api.createTask(projectId, input)
    await loadBoard(projectId)
  }

  async function createIteration(projectId: number, input: IterationInput) {
    await api.createIteration(projectId, input)
    await loadBoard(projectId)
  }

  async function updateTask(taskId: number, input: Partial<TaskInput>) {
    const task = await api.updateTask(taskId, input)
    replaceTask(task)
  }

  async function deleteTask(taskId: number) {
    await api.deleteTask(taskId)
    statuses.value = statuses.value.map((status) => ({
      ...status,
      tasks: status.tasks.filter((task) => task.id !== taskId),
    }))
  }

  function setBoard(board: Board) {
    project.value = board.project
    statuses.value = board.statuses
    iterations.value = board.iterations
    inboxIteration.value = board.inbox_iteration
  }

  function replaceTask(task: Task) {
    const nextStatuses = statuses.value.map((status) => ({
      ...status,
      tasks: status.tasks.filter((existingTask) => existingTask.id !== task.id),
    }))

    const targetIndex = nextStatuses.findIndex((status) => status.id === task.status)
    if (targetIndex >= 0) {
      nextStatuses[targetIndex] = {
        ...nextStatuses[targetIndex],
        tasks: [...nextStatuses[targetIndex].tasks, task].sort((a, b) => a.position - b.position),
      }
    }

    statuses.value = nextStatuses
  }

  function clearBoard() {
    project.value = null
    statuses.value = []
    iterations.value = []
    inboxIteration.value = null
    error.value = null
  }

  return {
    project,
    statuses,
    iterations,
    inboxIteration,
    taskCount,
    loading,
    error,
    loadBoard,
    createIteration,
    createTask,
    updateTask,
    deleteTask,
    clearBoard,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useBoardStore, import.meta.hot))
}
