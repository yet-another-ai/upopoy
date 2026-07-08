<script setup lang="ts">
import { reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'
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
import UserMultiSelect from '@/components/search/UserMultiSelect.vue'
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

const { t } = useI18n()

const form = reactive({
  title: '',
  description: '',
  status: '',
  iterationId: '',
  priority: 'medium' as TaskPriority,
  deadline: null as string | null,
  estimatedMinutes: '',
  developerIds: [] as number[],
  reviewerIds: [] as number[],
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
    form.developerIds = props.task?.developer_ids ? [...props.task.developer_ids] : []
    form.reviewerIds = props.task?.reviewer_ids ? [...props.task.reviewer_ids] : []
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
    developer_ids: form.developerIds,
    reviewer_ids: form.reviewerIds,
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
      <Label for="task-title">{{ t('tasks.title') }}</Label>
      <Input id="task-title" v-model="form.title" :placeholder="t('tasks.titlePlaceholder')" />
    </div>

    <div class="grid gap-1.5">
      <Label for="task-description">{{ t('tasks.description') }}</Label>
      <Textarea id="task-description" v-model="form.description" rows="4" />
    </div>

    <div v-if="props.showStatus" class="grid gap-1.5">
      <Label>{{ t('tasks.status') }}</Label>
      <Select v-model="form.status">
        <SelectTrigger class="w-full" :aria-label="t('tasks.status')">
          <SelectValue :placeholder="t('tasks.selectStatus')" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem v-for="status in props.statuses" :key="status.id" :value="status.id">
            {{ status.name }}
          </SelectItem>
        </SelectContent>
      </Select>
    </div>

    <div class="grid gap-1.5">
      <Label>{{ t('tasks.priority') }}</Label>
      <Select v-model="form.priority">
        <SelectTrigger class="w-full" :aria-label="t('tasks.priority')">
          <SelectValue :placeholder="t('tasks.selectPriority')" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem v-for="priority in TASK_PRIORITIES" :key="priority.id" :value="priority.id">
            {{ t(`tasks.priorities.${priority.id}`) }}
          </SelectItem>
        </SelectContent>
      </Select>
    </div>

    <div class="grid gap-4 md:grid-cols-2">
      <UserMultiSelect
        v-model="form.developerIds"
        label="Developers"
        placeholder="Search developers"
        search-aria-label="Search users to add as developers"
        :selected-users="props.task?.developers ?? []"
        empty-text="No developers selected."
      />
      <UserMultiSelect
        v-model="form.reviewerIds"
        label="Reviewers"
        placeholder="Search reviewers"
        search-aria-label="Search users to add as reviewers"
        :selected-users="props.task?.reviewers ?? []"
        empty-text="No reviewers selected."
      />
    </div>

    <div v-if="props.showIteration" class="grid gap-1.5">
      <Label>{{ t('tasks.iteration') }}</Label>
      <Select v-model="form.iterationId">
        <SelectTrigger class="w-full" :aria-label="t('tasks.iteration')">
          <SelectValue :placeholder="t('tasks.selectIteration')" />
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
        <Label for="task-deadline">{{ t('tasks.deadline') }}</Label>
        <DeadlinePicker id="task-deadline" v-model="form.deadline" />
      </div>

      <div class="grid gap-1.5">
        <Label for="task-estimate">{{ t('tasks.estimatedTime') }}</Label>
        <Input
          id="task-estimate"
          v-model="form.estimatedMinutes"
          type="number"
          min="0"
          step="15"
          :placeholder="t('tasks.minutesPlaceholder')"
        />
      </div>
    </div>

    <div class="flex justify-end gap-2">
      <Button type="button" variant="ghost" @click="emit('cancel')">
        {{ t('common.cancel') }}
      </Button>
      <Button type="submit">
        {{ props.submitLabel }}
      </Button>
    </div>
  </form>
</template>
