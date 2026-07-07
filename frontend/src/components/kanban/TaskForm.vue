<script setup lang="ts">
import { reactive, watch } from 'vue'
import { Button } from '@/components/ui/button'
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
import DeadlinePicker from './DeadlinePicker.vue'
import {
  TASK_PRIORITIES,
  type Iteration,
  type Task,
  type TaskInput,
  type TaskPriority,
  type TaskStatusOption,
} from '@/services/api'

const props = defineProps<{
  task?: Task | null
  statuses: readonly TaskStatusOption[]
  iterations?: readonly Iteration[]
  defaultStatus?: TaskStatusOption['id']
  defaultIterationId?: number | null
  submitLabel: string
  showStatus?: boolean
  showIteration?: boolean
  showSchedule?: boolean
}>()

const emit = defineEmits<{
  submit: [input: TaskInput]
  cancel: []
}>()

const form = reactive({
  title: '',
  description: '',
  status: '',
  iterationId: '',
  priority: 'medium' as TaskPriority,
  deadline: null as string | null,
  estimatedMinutes: '',
})

watch(
  () => [props.task, props.defaultStatus, props.statuses, props.defaultIterationId] as const,
  () => {
    form.title = props.task?.title ?? ''
    form.description = props.task?.description ?? ''
    form.priority = props.task?.priority ?? 'medium'
    form.deadline = props.task?.deadline ?? null
    form.estimatedMinutes =
      props.task?.estimated_minutes == null ? '' : String(props.task.estimated_minutes)
    form.status = props.task?.status ?? props.defaultStatus ?? props.statuses[0]?.id ?? ''
    form.iterationId = String(props.task?.iteration_id ?? props.defaultIterationId ?? '')
  },
  { immediate: true },
)

function submitForm() {
  if (!form.title.trim()) return

  const input: TaskInput = {
    title: form.title.trim(),
    description: form.description.trim(),
    status: form.status ? (form.status as TaskStatusOption['id']) : undefined,
    priority: form.priority,
  }

  if (props.showIteration) {
    input.iteration_id = form.iterationId ? Number(form.iterationId) : null
  }

  if (props.showSchedule) {
    input.deadline = form.deadline
    input.estimated_minutes = form.estimatedMinutes !== '' ? Number(form.estimatedMinutes) : null
  }

  emit('submit', input)
}
</script>

<template>
  <form class="grid gap-4" @submit.prevent="submitForm">
    <div class="grid gap-1.5">
      <Label for="task-title">Title</Label>
      <Input id="task-title" v-model="form.title" placeholder="Write acceptance criteria" />
    </div>

    <div class="grid gap-1.5">
      <Label for="task-description">Description</Label>
      <Textarea id="task-description" v-model="form.description" rows="4" />
    </div>

    <div v-if="props.showStatus" class="grid gap-1.5">
      <Label>Status</Label>
      <Select v-model="form.status">
        <SelectTrigger class="w-full" aria-label="Status">
          <SelectValue placeholder="Select status" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem v-for="status in props.statuses" :key="status.id" :value="status.id">
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
          <SelectItem v-for="priority in TASK_PRIORITIES" :key="priority.id" :value="priority.id">
            {{ priority.name }}
          </SelectItem>
        </SelectContent>
      </Select>
    </div>

    <div v-if="props.showIteration" class="grid gap-1.5">
      <Label>Iteration</Label>
      <Select v-model="form.iterationId">
        <SelectTrigger class="w-full" aria-label="Iteration">
          <SelectValue placeholder="Select iteration" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem
            v-for="iteration in props.iterations ?? []"
            :key="iteration.id"
            :value="String(iteration.id)"
          >
            {{ iteration.name }}
          </SelectItem>
        </SelectContent>
      </Select>
    </div>

    <div v-if="props.showSchedule" class="grid gap-4 md:grid-cols-2">
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
      <Button type="button" variant="ghost" @click="emit('cancel')"> Cancel </Button>
      <Button type="submit">
        {{ props.submitLabel }}
      </Button>
    </div>
  </form>
</template>
