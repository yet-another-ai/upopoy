<script setup lang="ts">
import { ArrowLeftIcon, CalendarIcon, ClockIcon, FlagIcon } from '@lucide/vue'
import { computed, nextTick, reactive, shallowRef, useTemplateRef, watch } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import DeadlinePicker from '@/components/kanban/DeadlinePicker.vue'
import MarkdownPreview from '@/components/markdown/MarkdownPreview.vue'
import { formatDeadline } from '@/lib/deadline'
import { formatPriority, priorityBadgeVariant } from '@/lib/priority'
import {
  api,
  TASK_PRIORITIES,
  type Board,
  type Task,
  type TaskInput,
  type TaskPriority,
  type TaskStatus,
} from '@/services/api'

const props = defineProps<{
  taskId: number
}>()

const emit = defineEmits<{
  taskUpdated: [task: Task]
}>()

const task = shallowRef<Task | null>(null)
const board = shallowRef<Board | null>(null)
const router = useRouter()
const loading = shallowRef(false)
const saving = shallowRef(false)
const error = shallowRef<string | null>(null)
const editingDescription = shallowRef(false)
const descriptionRef = useTemplateRef<HTMLTextAreaElement>('descriptionRef')

const form = reactive({
  title: '',
  description: '',
  status: '',
  iterationId: '',
  priority: 'medium' as TaskPriority,
  deadline: null as string | null,
  estimatedMinutes: '',
})

const statuses = computed(() => board.value?.statuses ?? [])
const iterations = computed(() => board.value?.iterations ?? [])
const currentStatus = computed(() =>
  statuses.value.find((status) => status.id === task.value?.status),
)
const currentIteration = computed(() =>
  iterations.value.find((iteration) => iteration.id === task.value?.iteration_id),
)

watch(
  () => props.taskId,
  (taskId) => {
    void loadTask(taskId)
  },
  { immediate: true },
)

async function loadTask(taskId: number) {
  loading.value = true
  error.value = null
  editingDescription.value = false

  try {
    const loadedTask = await api.getTask(taskId)
    task.value = loadedTask
    board.value = await api.getBoard(loadedTask.project_id)
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Unable to load task'
  } finally {
    loading.value = false
  }
}

watch(
  () => [task.value, statuses.value] as const,
  () => {
    form.title = task.value?.title ?? ''
    form.description = task.value?.description ?? ''
    form.status = task.value?.status ?? statuses.value[0]?.id ?? ''
    form.iterationId = String(task.value?.iteration_id ?? board.value?.inbox_iteration.id ?? '')
    form.priority = task.value?.priority ?? 'medium'
    form.deadline = task.value?.deadline ?? null
    form.estimatedMinutes =
      task.value?.estimated_minutes == null ? '' : String(task.value.estimated_minutes)
  },
  { immediate: true },
)

async function saveTask(input: TaskInput) {
  if (!task.value) return

  saving.value = true
  error.value = null

  try {
    const updatedTask = await api.updateTask(task.value.id, input)
    task.value = updatedTask
    editingDescription.value = false
    emit('taskUpdated', updatedTask)
    await router.push({ name: 'board' })
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Unable to save task'
  } finally {
    saving.value = false
  }
}

function submitTaskForm() {
  if (!form.title.trim()) return

  void saveTask({
    title: form.title.trim(),
    description: form.description.trim(),
    status: form.status ? (form.status as TaskStatus) : undefined,
    iteration_id: form.iterationId ? Number(form.iterationId) : null,
    priority: form.priority,
    deadline: form.deadline,
    estimated_minutes: form.estimatedMinutes !== '' ? Number(form.estimatedMinutes) : null,
  })
}

async function editDescription() {
  if (loading.value || !task.value) return

  editingDescription.value = true
  await nextTick()
  descriptionRef.value?.focus()
}

function cancelTaskForm() {
  editingDescription.value = false
  void router.push({ name: 'board' })
}

function formatEstimate(minutes: number | null) {
  if (minutes == null) return 'Not estimated'
  if (minutes < 60) return `${minutes} minutes`

  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60
  return remainingMinutes > 0 ? `${hours}h ${remainingMinutes}m` : `${hours}h`
}
</script>

<template>
  <main class="min-h-0 flex-1 overflow-y-auto">
    <header class="flex items-center justify-between gap-3 border-b p-5">
      <div class="min-w-0">
        <Button as-child variant="ghost" size="sm" class="mb-2 -ml-2">
          <RouterLink :to="{ name: 'board' }">
            <ArrowLeftIcon />
            Board
          </RouterLink>
        </Button>
        <p class="text-muted-foreground text-xs font-medium tracking-wider uppercase">
          Task detail
        </p>
        <h1 class="truncate text-2xl font-semibold">
          {{ task?.title ?? 'Loading task' }}
        </h1>
      </div>
      <div class="flex shrink-0 flex-wrap justify-end gap-2">
        <Badge v-if="currentStatus" variant="secondary">
          {{ currentStatus.name }}
        </Badge>
        <Badge v-if="task" :variant="priorityBadgeVariant(task.priority)">
          {{ formatPriority(task.priority) }}
        </Badge>
      </div>
    </header>

    <div class="grid gap-5 p-5 xl:grid-cols-[minmax(0,1fr)_22rem]">
      <div class="grid content-start gap-5">
        <Card class="rounded-lg shadow-none">
          <CardHeader>
            <CardTitle class="text-base">Task fields</CardTitle>
          </CardHeader>
          <CardContent>
            <p v-if="loading" class="text-muted-foreground text-sm">Loading...</p>
            <p v-else-if="error" class="text-destructive text-sm">
              {{ error }}
            </p>
            <form v-else-if="task" class="grid gap-4" @submit.prevent="submitTaskForm">
              <div class="grid gap-1.5">
                <Label for="task-title">Title</Label>
                <Input id="task-title" v-model="form.title" />
              </div>

              <div class="grid gap-1.5">
                <Label for="task-description">Description</Label>
                <Textarea
                  v-if="editingDescription"
                  id="task-description"
                  ref="descriptionRef"
                  v-model="form.description"
                  rows="8"
                />
                <div
                  v-else
                  class="hover:border-primary/50 focus-visible:ring-primary min-h-40 cursor-text rounded-lg border p-3 transition outline-none focus-visible:ring-2"
                  role="button"
                  tabindex="0"
                  aria-label="Edit description"
                  @click="editDescription"
                  @keydown.enter.prevent="editDescription"
                  @keydown.space.prevent="editDescription"
                >
                  <MarkdownPreview :source="form.description" />
                </div>
              </div>

              <div class="grid gap-4 md:grid-cols-2">
                <div class="grid gap-1.5">
                  <Label>Status</Label>
                  <Select v-model="form.status">
                    <SelectTrigger class="w-full" aria-label="Status">
                      <SelectValue placeholder="Select status" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem v-for="status in statuses" :key="status.id" :value="status.id">
                        {{ status.name }}
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div class="grid gap-1.5">
                  <Label>Priority</Label>
                  <Select v-model="form.priority">
                    <SelectTrigger class="w-full" aria-label="Priority">
                      <SelectValue placeholder="Select priority" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem
                        v-for="priority in TASK_PRIORITIES"
                        :key="priority.id"
                        :value="priority.id"
                      >
                        {{ priority.name }}
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div class="grid gap-4 md:grid-cols-2">
                <div class="grid gap-1.5">
                  <Label>Iteration</Label>
                  <Select v-model="form.iterationId">
                    <SelectTrigger class="w-full" aria-label="Iteration">
                      <SelectValue placeholder="Select iteration" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem
                        v-for="iteration in iterations"
                        :key="iteration.id"
                        :value="String(iteration.id)"
                      >
                        {{ iteration.name }}
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div class="grid gap-4 md:grid-cols-2">
                <div class="grid gap-1.5">
                  <Label for="task-deadline">Deadline</Label>
                  <DeadlinePicker id="task-deadline" v-model="form.deadline" />
                </div>

                <div class="grid gap-1.5">
                  <Label for="task-estimate">Estimated time</Label>
                  <Input
                    id="task-estimate"
                    v-model="form.estimatedMinutes"
                    type="number"
                    min="0"
                    step="15"
                    placeholder="Minutes"
                  />
                </div>
              </div>

              <div class="flex justify-end gap-2">
                <Button type="button" variant="ghost" :disabled="saving" @click="cancelTaskForm">
                  Cancel
                </Button>
                <Button type="submit" :disabled="saving"> Save task </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>

      <aside class="grid content-start gap-4">
        <Card class="rounded-lg shadow-none">
          <CardHeader>
            <CardTitle class="text-base">Planning</CardTitle>
          </CardHeader>
          <CardContent class="grid gap-3 text-sm">
            <div class="flex items-center gap-2">
              <FlagIcon class="text-muted-foreground size-4" />
              <span>{{ task ? `${formatPriority(task.priority)} priority` : 'No priority' }}</span>
            </div>
            <div class="flex items-center gap-2">
              <CalendarIcon class="text-muted-foreground size-4" />
              <span>{{ formatDeadline(task?.deadline) ?? 'No deadline' }}</span>
            </div>
            <div class="flex items-center gap-2">
              <CalendarIcon class="text-muted-foreground size-4" />
              <span>
                {{ currentIteration?.name ?? 'No iteration' }}
                <template v-if="currentIteration?.deadline">
                  - {{ formatDeadline(currentIteration.deadline) }}
                </template>
              </span>
            </div>
            <div class="flex items-center gap-2">
              <ClockIcon class="text-muted-foreground size-4" />
              <span>{{ formatEstimate(task?.estimated_minutes ?? null) }}</span>
            </div>
          </CardContent>
        </Card>
      </aside>
    </div>
  </main>
</template>
