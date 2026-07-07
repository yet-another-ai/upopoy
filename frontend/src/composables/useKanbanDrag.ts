import { createGlobalState } from '@vueuse/core'
import { onScopeDispose, readonly, shallowRef } from 'vue'

export const useKanbanDrag = createGlobalState(() => {
  const draggingTaskId = shallowRef<number | null>(null)
  const previousBodyUserSelect = shallowRef<string | null>(null)
  const previousBodyWebkitUserSelect = shallowRef<string | null>(null)

  function disableDocumentTextSelection() {
    if (typeof document === 'undefined') return

    if (previousBodyUserSelect.value === null)
      previousBodyUserSelect.value = document.body.style.userSelect
    if (previousBodyWebkitUserSelect.value === null)
      previousBodyWebkitUserSelect.value =
        document.body.style.getPropertyValue('-webkit-user-select')

    document.body.style.userSelect = 'none'
    document.body.style.setProperty('-webkit-user-select', 'none')
    window.getSelection()?.removeAllRanges()
  }

  function restoreDocumentTextSelection() {
    if (typeof document === 'undefined') return
    if (previousBodyUserSelect.value === null) return

    document.body.style.userSelect = previousBodyUserSelect.value
    document.body.style.setProperty('-webkit-user-select', previousBodyWebkitUserSelect.value ?? '')
    previousBodyUserSelect.value = null
    previousBodyWebkitUserSelect.value = null
  }

  function startTaskDrag(taskId: number) {
    draggingTaskId.value = taskId
    disableDocumentTextSelection()
  }

  function stopTaskDrag() {
    draggingTaskId.value = null
    restoreDocumentTextSelection()
  }

  onScopeDispose(restoreDocumentTextSelection)

  return {
    draggingTaskId: readonly(draggingTaskId),
    startTaskDrag,
    stopTaskDrag,
  }
})
