export const supportedLocales = ['en', 'zh-CN'] as const
export type SupportedLocale = (typeof supportedLocales)[number]

export const defaultLocale: SupportedLocale = 'en'

export function resolveBrowserLocale(languages = browserLanguages()): SupportedLocale {
  for (const language of languages) {
    const locale = normalizeLocale(language)
    if (locale) return locale
  }

  return defaultLocale
}

export function preferredLocaleHeader() {
  return resolveBrowserLocale()
}

function browserLanguages() {
  if (typeof navigator === 'undefined') return []

  return navigator.languages?.length ? navigator.languages : [navigator.language]
}

function normalizeLocale(language: string): SupportedLocale | null {
  const normalized = language.trim().replace('_', '-').toLowerCase()
  if (!normalized) return null

  if (normalized === 'zh' || normalized === 'zh-cn' || normalized === 'zh-hans') return 'zh-CN'
  if (normalized.startsWith('zh-hans-') || normalized.startsWith('zh-cn-')) return 'zh-CN'
  if (normalized === 'en' || normalized.startsWith('en-')) return 'en'

  return null
}
