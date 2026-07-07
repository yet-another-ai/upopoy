import { computed, readonly, shallowRef } from 'vue'
import {
  api,
  type Board,
  type BoardStatus,
  type Project,
  type Task,
  type TaskInput,
} from '@/services/api'

export function useBoard() {
  const project = shallowRef<Project | null>(null)
  const statuses = shallowRef<BoardStatus[]>([])
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

  return {
    project: readonly(project),
    statuses: readonly(statuses),
    taskCount,
    loading: readonly(loading),
    error: readonly(error),
    loadBoard,
    createTask,
    updateTask,
    deleteTask,
  }
}
