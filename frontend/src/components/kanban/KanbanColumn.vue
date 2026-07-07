<script setup lang="ts">
import { PlusIcon } from '@lucide/vue'
import { useElementHover } from '@vueuse/core'
import { computed, shallowRef, useTemplateRef } from 'vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { useKanbanDrag } from '@/composables/useKanbanDrag'
import TaskCard from './TaskCard.vue'
import TaskForm from './TaskForm.vue'
import type { BoardStatus, TaskInput, TaskStatusOption } from '@/services/api'

const props = defineProps<{
  status: BoardStatus
  statuses: readonly TaskStatusOption[]
}>()

const emit = defineEmits<{
  createTask: [status: TaskStatusOption['id'], input: TaskInput]
  updateTask: [taskId: number, input: Partial<TaskInput>]
  deleteTask: [taskId: number]
}>()

const creatingTask = shallowRef(false)
const dropZoneRef = useTemplateRef<HTMLElement>('dropZoneRef')
const kanbanDrag = useKanbanDrag()
const isHovered = useElementHover(dropZoneRef)

const isDragTarget = computed(() => {
  const taskId = kanbanDrag.draggingTaskId.value
  return Boolean(
    taskId && isHovered.value && !props.status.tasks.some((task) => task.id === taskId),
  )
})

function submitTask(input: TaskInput) {
  emit('createTask', props.status.id, {
    ...input,
    status: props.status.id,
  })
  creatingTask.value = false
}

function dropDraggedTask() {
  const taskId = kanbanDrag.draggingTaskId.value
  if (!taskId) return

  if (props.status.tasks.some((task) => task.id === taskId)) {
    kanbanDrag.stopTaskDrag()
    return
  }

  emit('updateTask', taskId, {
    status: props.status.id,
    position: props.status.tasks.length + 1,
  })
  kanbanDrag.stopTaskDrag()
}

function forwardTaskUpdate(taskId: number, input: Partial<TaskInput>) {
  emit('updateTask', taskId, input)
}
</script>

<template>
  <section
    ref="dropZoneRef"
    class="bg-muted/40 flex max-h-full min-h-0 w-80 shrink-0 flex-col rounded-lg border transition"
    :class="{ 'border-primary bg-primary/5 ring-primary/30 ring-2': isDragTarget }"
    :data-task-status="props.status.id"
    data-testid="kanban-column"
    @pointerup="dropDraggedTask"
  >
    <header class="flex items-center justify-between gap-3 border-b p-3">
      <div class="min-w-0">
        <div class="flex items-center gap-2">
          <h2 class="truncate text-sm font-semibold">
            {{ props.status.name }}
          </h2>
          <Badge variant="outline">
            {{ props.status.tasks.length }}
          </Badge>
        </div>
      </div>
      <div class="flex shrink-0 gap-1">
        <Button size="icon-sm" variant="ghost" aria-label="New task" @click="creatingTask = true">
          <PlusIcon />
        </Button>
      </div>
    </header>

    <div class="grid min-h-0 gap-3 overflow-y-auto p-3">
      <TaskCard
        v-for="task in props.status.tasks"
        :key="task.id"
        :task="task"
        @update-task="forwardTaskUpdate"
        @delete-task="emit('deleteTask', $event)"
      />
      <Card v-if="props.status.tasks.length === 0" class="border-dashed bg-transparent shadow-none">
        <CardHeader class="p-4">
          <CardTitle class="text-muted-foreground text-sm font-normal">
            No tasks here yet.
          </CardTitle>
        </CardHeader>
        <CardContent class="p-4 pt-0">
          <Button size="sm" variant="outline" @click="creatingTask = true">
            <PlusIcon />
            Add task
          </Button>
        </CardContent>
      </Card>
    </div>
  </section>

  <Dialog v-model:open="creatingTask">
    <DialogContent>
      <DialogHeader>
        <DialogTitle>New task</DialogTitle>
        <DialogDescription> Add a task to {{ props.status.name }}. </DialogDescription>
      </DialogHeader>
      <TaskForm
        :statuses="props.statuses"
        :default-status="props.status.id"
        submit-label="Create task"
        @submit="submitTask"
        @cancel="creatingTask = false"
      />
    </DialogContent>
  </Dialog>
</template>
