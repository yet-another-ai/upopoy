import type { ComposerTranslation } from 'vue-i18n'

interface NamedUser {
  display_name: string | null
  email: string
}

export function formatShortEstimate(minutes: number | null) {
  if (minutes == null) return null
  if (minutes < 60) return `${minutes}m`

  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60
  return remainingMinutes > 0 ? `${hours}h ${remainingMinutes}m` : `${hours}h`
}

export function formatEstimate(minutes: number | null, t: ComposerTranslation) {
  if (minutes == null) return t('tasks.notEstimated')
  if (minutes < 60) return t('tasks.minutes', { count: minutes })

  return formatShortEstimate(minutes)
}

export function userNames(users: readonly NamedUser[]) {
  if (users.length === 0) return null

  return users.map((user) => user.display_name || user.email).join(', ')
}
