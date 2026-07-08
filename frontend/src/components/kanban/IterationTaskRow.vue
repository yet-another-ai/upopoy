<script setup lang="ts">
import { MoreHorizontalIcon } from '@lucide/vue'
import { computed, shallowRef } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import ConfirmDeleteDialog from '@/components/common/ConfirmDeleteDialog.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { formatDeadline } from '@/lib/deadline'
import { formatPriority, priorityBadgeVariant } from '@/lib/priority'
import type { Task, TaskStatusOption } from '@/services/api'

const props = defineProps<{
  task: Task
  statuses: readonly TaskStatusOption[]
}>()

const emit = defineEmits<{
  deleteTask: [taskId: number]
}>()

const router = useRouter()
const deleteDialogOpen = shallowRef(false)
const { t } = useI18n()

const statusName = computed(
  () => props.statuses.find((status) => status.id === props.task.status)?.name ?? props.task.status,
)

function openTaskDetails() {
  void router.push({ name: 'task-detail', params: { taskId: props.task.id } })
}

function openTaskDetailsFromKeyboard(event: KeyboardEvent) {
  event.preventDefault()
  openTaskDetails()
}
</script>

<template>
  <div
    class="hover:bg-accent focus-visible:ring-primary grid cursor-pointer items-center gap-3 rounded-lg border px-3 py-2 transition outline-none focus-visible:ring-2 md:grid-cols-[minmax(0,1fr)_auto]"
    role="link"
    tabindex="0"
    :aria-label="t('tasks.openTask', { title: props.task.title })"
    data-testid="iteration-task-row"
    @click="openTaskDetails"
    @keydown.enter="openTaskDetailsFromKeyboard"
    @keydown.space.prevent="openTaskDetailsFromKeyboard"
  >
    <div class="min-w-0 self-center">
      <div class="flex min-w-0 items-baseline gap-2">
        <span class="text-muted-foreground shrink-0 text-xs leading-5">#{{ props.task.id }}</span>
        <span class="truncate text-sm leading-5 font-medium">{{ props.task.title }}</span>
      </div>
      <p v-if="props.task.description" class="text-muted-foreground mt-1 truncate text-xs">
        {{ props.task.description }}
      </p>
    </div>

    <div class="flex flex-wrap items-center gap-2 md:justify-end">
      <Badge variant="secondary">{{ statusName }}</Badge>
      <Badge :variant="priorityBadgeVariant(props.task.priority)">
        {{ formatPriority(props.task.priority) }}
      </Badge>
      <Badge v-if="props.task.deadline" variant="outline">
        {{ t('tasks.due', { date: formatDeadline(props.task.deadline) }) }}
      </Badge>
      <DropdownMenu>
        <DropdownMenuTrigger as-child>
          <Button
            size="icon-sm"
            variant="ghost"
            :aria-label="t('tasks.taskActions')"
            @click.stop
            @keydown.stop
          >
            <MoreHorizontalIcon />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem @click="openTaskDetails">{{ t('tasks.edit') }}</DropdownMenuItem>
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
    </div>
  </div>
</template>
