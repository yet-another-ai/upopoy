<script setup lang="ts">
import {
  CalendarRangeIcon,
  ChevronDownIcon,
  InboxIcon,
  PlusIcon,
  RefreshCwIcon,
} from '@lucide/vue'
import { computed, reactive, shallowRef, watch } from 'vue'
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
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import DeadlinePicker from './DeadlinePicker.vue'
import IterationTaskRow from './IterationTaskRow.vue'
import TaskForm from './TaskForm.vue'
import { formatDeadline } from '@/lib/deadline'
import type {
  BoardStatus,
  Iteration,
  IterationInput,
  Project,
  Task,
  TaskInput,
  TaskStatusOption,
} from '@/services/api'

const props = defineProps<{
  project: Project | null
  iterations: readonly Iteration[]
  statuses: readonly BoardStatus[]
  loading: boolean
}>()

const emit = defineEmits<{
  refresh: []
  createIteration: [input: IterationInput]
  createTask: [status: TaskStatusOption['id'], input: TaskInput]
  deleteTask: [taskId: number]
}>()

const form = reactive({
  name: '',
  startsAt: null as string | null,
  deadline: null as string | null,
})
const creating = shallowRef(false)
const creatingTaskIteration = shallowRef<Iteration | null>(null)
const knownIterationIds = shallowRef<Set<number>>(new Set())
const openIterationIds = shallowRef<Set<number>>(new Set())

const inboxIteration = computed(() => props.iterations.find((iteration) => iteration.inbox) ?? null)
const tasksByIteration = computed(() => {
  const grouped = new Map<number, Task[]>()

  for (const status of props.statuses) {
    for (const task of status.tasks) {
      const tasks = grouped.get(task.iteration_id) ?? []
      tasks.push(task)
      grouped.set(task.iteration_id, tasks)
    }
  }

  return grouped
})
const iterationSections = computed(() =>
  props.iterations.map((iteration) => ({
    iteration,
    tasks: tasksByIteration.value.get(iteration.id) ?? [],
  })),
)
const defaultTaskStatus = computed(() => props.statuses[0]?.id)

watch(
  () => props.iterations.map((iteration) => iteration.id),
  (iterationIds) => {
    const knownIds = knownIterationIds.value
    const nextOpenIds = new Set(
      [...openIterationIds.value].filter((iterationId) => iterationIds.includes(iterationId)),
    )

    for (const iterationId of iterationIds) {
      if (!knownIds.has(iterationId)) nextOpenIds.add(iterationId)
    }

    knownIterationIds.value = new Set(iterationIds)
    openIterationIds.value = nextOpenIds
  },
  { immediate: true },
)

function submitIteration() {
  if (!form.name.trim() || !form.startsAt || !form.deadline) return

  emit('createIteration', {
    name: form.name.trim(),
    starts_at: form.startsAt,
    deadline: form.deadline,
  })
  form.name = ''
  form.startsAt = null
  form.deadline = null
  creating.value = false
}

function isIterationOpen(iterationId: number) {
  return openIterationIds.value.has(iterationId)
}

function toggleIteration(iterationId: number) {
  const nextOpenIds = new Set(openIterationIds.value)

  if (nextOpenIds.has(iterationId)) nextOpenIds.delete(iterationId)
  else nextOpenIds.add(iterationId)

  openIterationIds.value = nextOpenIds
}

function startTaskCreation(iteration: Iteration) {
  creatingTaskIteration.value = iteration
}

function submitTask(input: TaskInput) {
  const iteration = creatingTaskIteration.value
  const status = input.status ?? defaultTaskStatus.value
  if (!iteration || !status) return

  emit('createTask', status, {
    ...input,
    status,
    iteration_id: input.iteration_id ?? iteration.id,
  })
  creatingTaskIteration.value = null
}

function updateTaskDialogOpen(open: boolean) {
  if (!open) creatingTaskIteration.value = null
}
</script>

<template>
  <main class="flex min-h-0 flex-1 flex-col">
    <header class="flex flex-col gap-4 border-b p-5 md:flex-row md:items-center md:justify-between">
      <div class="min-w-0">
        <p class="text-muted-foreground text-xs font-medium tracking-wider uppercase">
          Iterations
        </p>
        <h1 class="truncate text-2xl font-semibold">
          {{ props.project?.name ?? 'No project selected' }}
        </h1>
      </div>
      <div class="flex shrink-0 items-center gap-2">
        <Button
          variant="outline"
          :disabled="!props.project || props.loading"
          @click="emit('refresh')"
        >
          <RefreshCwIcon :class="{ 'animate-spin': props.loading }" />
          Refresh
        </Button>
        <Button :disabled="!props.project" @click="creating = !creating">
          <PlusIcon />
          Iteration
        </Button>
      </div>
    </header>

    <div v-if="props.project" class="grid min-h-0 flex-1 content-start gap-4 overflow-y-auto p-5">
      <Card v-if="creating" class="rounded-lg shadow-none">
        <CardHeader>
          <CardTitle class="text-base">New iteration</CardTitle>
        </CardHeader>
        <CardContent>
          <form class="grid max-w-4xl gap-4" @submit.prevent="submitIteration">
            <div class="grid gap-1.5">
              <Label for="iteration-name">Name</Label>
              <Input id="iteration-name" v-model="form.name" placeholder="Sprint 1" />
            </div>

            <div class="grid gap-4 lg:grid-cols-2">
              <div class="grid min-w-0 gap-1.5">
                <Label for="iteration-start">Start time</Label>
                <DeadlinePicker id="iteration-start" v-model="form.startsAt" label="Start" />
              </div>
              <div class="grid min-w-0 gap-1.5">
                <Label for="iteration-deadline">Deadline</Label>
                <DeadlinePicker id="iteration-deadline" v-model="form.deadline" />
              </div>
            </div>

            <div class="flex justify-end gap-2">
              <Button type="button" variant="ghost" @click="creating = false">Cancel</Button>
              <Button
                type="submit"
                :disabled="!form.name.trim() || !form.startsAt || !form.deadline"
              >
                Create
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <div class="grid gap-3">
        <Card
          v-for="section in iterationSections"
          :key="section.iteration.id"
          class="rounded-lg shadow-none"
          data-testid="iteration-section"
        >
          <CardHeader class="grid gap-3 p-4">
            <div class="flex items-start justify-between gap-3">
              <button
                type="button"
                class="focus-visible:ring-primary flex min-w-0 flex-1 items-center gap-3 rounded-md text-left outline-none focus-visible:ring-2"
                :aria-expanded="isIterationOpen(section.iteration.id)"
                @click="toggleIteration(section.iteration.id)"
              >
                <span class="bg-muted grid size-9 place-items-center rounded-md" aria-hidden="true">
                  <InboxIcon v-if="section.iteration.inbox" class="size-4" />
                  <CalendarRangeIcon v-else class="size-4" />
                </span>
                <span class="min-w-0">
                  <CardTitle class="truncate text-base">{{ section.iteration.name }}</CardTitle>
                  <span class="text-muted-foreground mt-1 block text-sm">
                    <template v-if="section.iteration.inbox">
                      Tasks that still need planning details.
                    </template>
                    <template v-else>
                      {{ formatDeadline(section.iteration.starts_at) }} -
                      {{ formatDeadline(section.iteration.deadline) }}
                    </template>
                  </span>
                </span>
                <ChevronDownIcon
                  class="text-muted-foreground ml-auto size-4 shrink-0 transition"
                  :class="{ '-rotate-90': !isIterationOpen(section.iteration.id) }"
                />
              </button>

              <div class="flex shrink-0 items-center gap-2">
                <Badge variant="outline">{{ section.tasks.length }} tasks</Badge>
                <Button
                  size="sm"
                  variant="outline"
                  @click="startTaskCreation(section.iteration)"
                >
                  <PlusIcon />
                  Task
                </Button>
              </div>
            </div>
          </CardHeader>

          <CardContent v-if="isIterationOpen(section.iteration.id)" class="grid gap-3 p-4 pt-0">
            <IterationTaskRow
              v-for="task in section.tasks"
              :key="task.id"
              :task="task"
              :statuses="props.statuses"
              @delete-task="emit('deleteTask', $event)"
            />

            <div v-if="section.tasks.length === 0" class="rounded-lg border border-dashed p-4">
              <p class="text-muted-foreground text-sm">No tasks in this iteration yet.</p>
              <Button
                size="sm"
                variant="outline"
                class="mt-3"
                @click="startTaskCreation(section.iteration)"
              >
                <PlusIcon />
                Add task
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card
        v-if="!inboxIteration && iterationSections.length === 0"
        class="border-dashed bg-transparent shadow-none"
      >
        <CardHeader>
          <CardTitle class="text-muted-foreground text-sm font-normal">
            No planned iterations yet.
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Button size="sm" variant="outline" @click="creating = true">
            <PlusIcon />
            Add iteration
          </Button>
        </CardContent>
      </Card>
    </div>

    <div v-else class="grid flex-1 place-items-center p-8">
      <div class="max-w-sm text-center">
        <h2 class="text-lg font-semibold">Create a project to begin.</h2>
        <p class="text-muted-foreground mt-2 text-sm">
          Iterations are created inside a project.
        </p>
      </div>
    </div>

    <Dialog :open="Boolean(creatingTaskIteration)" @update:open="updateTaskDialogOpen">
      <DialogContent>
        <DialogHeader>
          <DialogTitle>New task</DialogTitle>
          <DialogDescription>
            Add a task to {{ creatingTaskIteration?.name ?? 'this iteration' }}.
          </DialogDescription>
        </DialogHeader>
        <TaskForm
          v-if="creatingTaskIteration"
          :statuses="props.statuses"
          :iterations="props.iterations"
          :default-status="defaultTaskStatus"
          :default-iteration-id="creatingTaskIteration.id"
          submit-label="Create task"
          show-status
          show-iteration
          @submit="submitTask"
          @cancel="creatingTaskIteration = null"
        />
      </DialogContent>
    </Dialog>
  </main>
</template>
