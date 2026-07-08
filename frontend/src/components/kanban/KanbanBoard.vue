<script setup lang="ts">
import { RefreshCwIcon } from '@lucide/vue'
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import KanbanColumn from './KanbanColumn.vue'
import type { BoardStatus, Iteration, Project, TaskInput, TaskStatusOption } from '@/services/api'

const props = defineProps<{
  project: Project | null
  statuses: readonly BoardStatus[]
  iterations: readonly Iteration[]
  inboxIteration: Iteration | null
  taskCount: number
  loading: boolean
}>()

const emit = defineEmits<{
  refresh: []
  createTask: [status: TaskStatusOption['id'], input: TaskInput]
  updateTask: [taskId: number, input: Partial<TaskInput>]
  deleteTask: [taskId: number]
}>()

const { t } = useI18n()

function createTask(status: TaskStatusOption['id'], input: TaskInput) {
  emit('createTask', status, input)
}

function updateTask(taskId: number, input: Partial<TaskInput>) {
  emit('updateTask', taskId, input)
}
</script>

<template>
  <main class="flex min-h-0 flex-1 flex-col">
    <header class="flex flex-col gap-4 border-b p-5 md:flex-row md:items-center md:justify-between">
      <div class="min-w-0">
        <p class="text-muted-foreground text-xs font-medium tracking-wider uppercase">
          {{ t('tasks.kanbanBoard') }}
        </p>
        <h1 class="truncate text-2xl font-semibold">
          {{ props.project?.name ?? t('tasks.noProjectSelected') }}
        </h1>
        <p v-if="props.project?.description" class="text-muted-foreground mt-1 max-w-2xl text-sm">
          {{ props.project.description }}
        </p>
      </div>
      <div class="flex shrink-0 items-center gap-2">
        <Button
          variant="outline"
          :disabled="!props.project || props.loading"
          @click="emit('refresh')"
        >
          <RefreshCwIcon :class="{ 'animate-spin': props.loading }" />
          {{ t('common.refresh') }}
        </Button>
      </div>
    </header>

    <div v-if="props.project" class="flex items-center gap-3 px-5 py-3 text-sm">
      <span class="text-muted-foreground">{{
        t('tasks.statusesCount', { count: props.statuses.length })
      }}</span>
      <Separator orientation="vertical" class="h-4" />
      <span class="text-muted-foreground">{{
        t('tasks.tasksCount', { count: props.taskCount })
      }}</span>
    </div>

    <div v-if="props.project" class="min-h-0 flex-1 overflow-x-auto px-5 pb-5">
      <div class="flex h-full min-w-max gap-4">
        <KanbanColumn
          v-for="status in props.statuses"
          :key="status.id"
          :status="status"
          :statuses="props.statuses"
          :iterations="props.iterations"
          :inbox-iteration="props.inboxIteration"
          @create-task="createTask"
          @update-task="updateTask"
          @delete-task="emit('deleteTask', $event)"
        />
      </div>
    </div>

    <div v-else class="grid flex-1 place-items-center p-8">
      <div class="max-w-sm text-center">
        <h2 class="text-lg font-semibold">{{ t('tasks.createProjectTitle') }}</h2>
        <p class="text-muted-foreground mt-2 text-sm">
          {{ t('tasks.createProjectDescription') }}
        </p>
      </div>
    </div>
  </main>
</template>
