import { TASK_PRIORITIES, type TaskPriority } from '@/services/api'
import type { BadgeVariants } from '@/components/ui/badge'

export function formatPriority(priority: TaskPriority | null | undefined) {
  return TASK_PRIORITIES.find((item) => item.id === priority)?.name ?? 'Medium'
}

export function priorityBadgeVariant(
  priority: TaskPriority | null | undefined,
): BadgeVariants['variant'] {
  if (priority === 'high') return 'destructive'
  if (priority === 'low') return 'outline'

  return 'secondary'
}
