import { storeToRefs } from 'pinia'
import { useBoardStore } from '@/stores/board'

export function useBoard() {
  const store = useBoardStore()
  const { project, statuses, taskCount, loading, error } = storeToRefs(store)

  return {
    project,
    statuses,
    taskCount,
    loading,
    error,
    loadBoard: store.loadBoard,
    createTask: store.createTask,
    updateTask: store.updateTask,
    deleteTask: store.deleteTask,
    clearBoard: store.clearBoard,
  }
}
