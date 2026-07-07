import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { useKanbanDrag } from '../useKanbanDrag'

describe('useKanbanDrag', () => {
  beforeEach(() => {
    document.body.style.userSelect = 'text'
    document.body.style.setProperty('-webkit-user-select', 'text')
  })

  afterEach(() => {
    useKanbanDrag().stopTaskDrag()
    document.body.style.userSelect = ''
    document.body.style.removeProperty('-webkit-user-select')
  })

  it('disables document text selection while dragging', () => {
    const drag = useKanbanDrag()

    drag.startTaskDrag(42)

    expect(drag.draggingTaskId.value).toBe(42)
    expect(document.body.style.userSelect).toBe('none')
    expect(document.body.style.getPropertyValue('-webkit-user-select')).toBe('none')

    drag.stopTaskDrag()

    expect(drag.draggingTaskId.value).toBeNull()
    expect(document.body.style.userSelect).toBe('text')
    expect(document.body.style.getPropertyValue('-webkit-user-select')).toBe('text')
  })
})
