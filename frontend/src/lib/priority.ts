import { TASK_PRIORITIES, type TaskPriority } from '@/services/api'
import type { BadgeVariants } from '@/components/ui/badge'
import { i18n } from '@/i18n'

export function formatPriority(priority: TaskPriority | null | undefined) {
  const priorityId = TASK_PRIORITIES.find((item) => item.id === priority)?.id ?? 'medium'

  return i18n.global.t(`tasks.priorities.${priorityId}`)
}

export function priorityBadgeVariant(
  priority: TaskPriority | null | undefined,
): BadgeVariants['variant'] {
  if (priority === 'high') return 'destructive'
  if (priority === 'low') return 'outline'

  return 'secondary'
}
