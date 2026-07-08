<script setup lang="ts">
import { MoreHorizontalIcon } from '@lucide/vue'
import { useDraggable } from '@vueuse/core'
import { computed, shallowRef, useTemplateRef } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import ConfirmDeleteDialog from '@/components/common/ConfirmDeleteDialog.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { useKanbanDrag } from '@/composables/useKanbanDrag'
import { formatDeadline } from '@/lib/deadline'
import { formatPriority, priorityBadgeVariant } from '@/lib/priority'
import type { CSSProperties } from 'vue'
import type { Task, TaskInput, TaskStatusOption } from '@/services/api'

const props = defineProps<{
  task: Task
}>()

const emit = defineEmits<{
  updateTask: [taskId: number, input: Partial<TaskInput>]
  deleteTask: [taskId: number]
}>()

const dragSize = shallowRef<{ width: number; height: number } | null>(null)
const movedDuringDrag = shallowRef(false)
const openPointerStart = shallowRef<{ x: number; y: number } | null>(null)
const openPointerMoved = shallowRef(false)
const deleteDialogOpen = shallowRef(false)
const cardRef = useTemplateRef<HTMLElement>('cardRef')
const kanbanDrag = useKanbanDrag()
const router = useRouter()
const { t } = useI18n()

const { x, y } = useDraggable(cardRef, {
  capture: false,
  preventDefault: false,
  onStart: (_position, event) => {
    if ((event.target as HTMLElement).closest('[data-no-drag]')) return false

    movedDuringDrag.value = false
    const cardBox = cardRef.value?.getBoundingClientRect()
    if (cardBox) {
      dragSize.value = {
        width: cardBox.width,
        height: cardBox.height,
      }
      x.value = cardBox.left
      y.value = cardBox.top
    }
  },
  onMove: () => {
    if (!movedDuringDrag.value) kanbanDrag.startTaskDrag(props.task.id)
    movedDuringDrag.value = true
  },
  onEnd: (_position, event) => {
    if (kanbanDrag.draggingTaskId.value === props.task.id) {
      const target = document
        .elementFromPoint(event.clientX, event.clientY)
        ?.closest<HTMLElement>('[data-task-status]')
      const status = target?.dataset.taskStatus as TaskStatusOption['id'] | undefined

      if (status && status !== props.task.status) emit('updateTask', props.task.id, { status })
    }

    kanbanDrag.stopTaskDrag()
    dragSize.value = null
    movedDuringDrag.value = false
  },
})

const isCardDragging = computed(
  () => kanbanDrag.draggingTaskId.value === props.task.id && Boolean(dragSize.value),
)

const placeholderStyle = computed<CSSProperties | undefined>(() => {
  if (!isCardDragging.value || !dragSize.value) return undefined

  return {
    height: `${dragSize.value.height}px`,
  }
})

const dragStyle = computed<CSSProperties>(() => {
  if (!isCardDragging.value || !dragSize.value)
    return {
      position: 'relative',
      pointerEvents: 'auto',
    }

  return {
    position: 'fixed',
    left: `${x.value}px`,
    top: `${y.value}px`,
    width: `${dragSize.value.width}px`,
    zIndex: 50,
    pointerEvents: 'none',
  }
})

function prepareTaskDetailsOpen(event: PointerEvent) {
  if ((event.target as HTMLElement).closest('[data-no-drag]')) return

  openPointerStart.value = { x: event.clientX, y: event.clientY }
  openPointerMoved.value = false
}

function trackTaskDetailsOpen(event: PointerEvent) {
  if (!openPointerStart.value) return

  const deltaX = event.clientX - openPointerStart.value.x
  const deltaY = event.clientY - openPointerStart.value.y
  openPointerMoved.value = Math.hypot(deltaX, deltaY) > 4
}

function openTaskDetailsFromPointer(event: PointerEvent) {
  if (!openPointerStart.value || openPointerMoved.value) {
    openPointerStart.value = null
    return
  }

  if ((event.target as HTMLElement).closest('[data-no-drag]')) {
    openPointerStart.value = null
    return
  }

  openPointerStart.value = null
  openTaskDetails()
}

function openTaskDetails() {
  void router.push({ name: 'task-detail', params: { taskId: props.task.id } })
}

function openTaskDetailsFromKeyboard(event: KeyboardEvent) {
  event.preventDefault()
  openTaskDetails()
}

function formatEstimate(minutes: number | null) {
  if (minutes == null) return null
  if (minutes < 60) return `${minutes}m`

  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60
  return remainingMinutes > 0 ? `${hours}h ${remainingMinutes}m` : `${hours}h`
}

function userNames(users: readonly { display_name: string | null; email: string }[]) {
  if (users.length === 0) return null

  return users.map((user) => user.display_name || user.email).join(', ')
}
</script>

<template>
  <div :style="placeholderStyle">
    <div
      ref="cardRef"
      class="text-foreground focus-visible:ring-primary cursor-pointer rounded-lg transition outline-none select-none focus-visible:ring-2 active:cursor-grabbing"
      :class="{ 'ring-primary/20 scale-[0.98] opacity-80 shadow-lg ring-2': isCardDragging }"
      :style="dragStyle"
      data-testid="task-card"
      :data-task-id="props.task.id"
      role="link"
      tabindex="0"
      :aria-label="t('tasks.openTask', { title: props.task.title })"
      @pointerdown="prepareTaskDetailsOpen"
      @pointermove="trackTaskDetailsOpen"
      @pointerup="openTaskDetailsFromPointer"
      @keydown.enter="openTaskDetailsFromKeyboard"
      @keydown.space.prevent="openTaskDetailsFromKeyboard"
    >
      <Card class="rounded-lg shadow-none">
        <CardHeader class="flex flex-row items-start justify-between gap-3 p-3">
          <CardTitle class="min-w-0 text-sm leading-snug font-medium">
            {{ props.task.title }}
          </CardTitle>
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <Button
                size="icon-sm"
                variant="ghost"
                :aria-label="t('tasks.taskActions')"
                data-no-drag
              >
                <MoreHorizontalIcon />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem @click="openTaskDetails">
                {{ t('tasks.edit') }}
              </DropdownMenuItem>
              <DropdownMenuItem class="text-destructive" @select="deleteDialogOpen = true">
                {{ t('tasks.delete') }}
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
          <ConfirmDeleteDialog
            v-model:open="deleteDialogOpen"
            :title="t('tasks.deleteTaskTitle')"
            :description="t('tasks.deleteTaskDescription', { title: props.task.title })"
            @confirm="emit('deleteTask', props.task.id)"
          />
        </CardHeader>
        <CardContent class="grid gap-3 p-3 pt-0">
          <div class="flex flex-wrap items-center gap-2">
            <Badge variant="secondary"> #{{ props.task.id }} </Badge>
            <Badge :variant="priorityBadgeVariant(props.task.priority)">
              {{ formatPriority(props.task.priority) }}
            </Badge>
            <Badge variant="outline">
              {{ props.task.iteration_name }}
            </Badge>
            <Badge v-if="props.task.deadline" variant="outline">
              {{ t('tasks.due', { date: formatDeadline(props.task.deadline) }) }}
            </Badge>
            <Badge v-if="formatEstimate(props.task.estimated_minutes)" variant="outline">
              {{ formatEstimate(props.task.estimated_minutes) }}
            </Badge>
            <Badge v-if="userNames(props.task.developers)" variant="outline">
              Dev: {{ userNames(props.task.developers) }}
            </Badge>
            <Badge v-if="userNames(props.task.reviewers)" variant="outline">
              Review: {{ userNames(props.task.reviewers) }}
            </Badge>
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</template>
