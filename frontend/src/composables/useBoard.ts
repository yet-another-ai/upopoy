import { storeToRefs } from 'pinia'
import { useBoardStore } from '@/stores/board'

export function useBoard() {
  const store = useBoardStore()
  const { project, statuses, iterations, inboxIteration, taskCount, loading, error } =
    storeToRefs(store)

  return {
    project,
    statuses,
    iterations,
    inboxIteration,
    taskCount,
    loading,
    error,
    loadBoard: store.loadBoard,
    createIteration: store.createIteration,
    createTask: store.createTask,
    updateTask: store.updateTask,
    deleteTask: store.deleteTask,
    clearBoard: store.clearBoard,
  }
}
