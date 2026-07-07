const dateTimeFormatter = new Intl.DateTimeFormat('en-US', {
  year: 'numeric',
  month: 'short',
  day: 'numeric',
  hour: 'numeric',
  minute: '2-digit',
})

export function formatDeadline(value: string | null | undefined) {
  if (!value) return null

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value

  return dateTimeFormatter.format(date)
}

export function deadlineDatePart(value: string | null | undefined) {
  if (!value) return ''
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return value

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''

  return [
    String(date.getFullYear()).padStart(4, '0'),
    String(date.getMonth() + 1).padStart(2, '0'),
    String(date.getDate()).padStart(2, '0'),
  ].join('-')
}

export function deadlineTimePart(value: string | null | undefined) {
  if (!value || /^\d{4}-\d{2}-\d{2}$/.test(value)) return '09:00'

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '09:00'

  return [
    String(date.getHours()).padStart(2, '0'),
    String(date.getMinutes()).padStart(2, '0'),
  ].join(':')
}

export function buildDeadlineIso(datePart: string, timePart: string) {
  const [year, month, day] = datePart.split('-').map(Number)
  const [hours, minutes] = timePart.split(':').map(Number)
  const date = new Date(year, month - 1, day, hours || 0, minutes || 0)

  return date.toISOString()
}
