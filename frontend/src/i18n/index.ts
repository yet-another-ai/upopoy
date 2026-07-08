import { createI18n } from 'vue-i18n'
import messages from '@intlify/unplugin-vue-i18n/messages'
import { defaultLocale, resolveBrowserLocale } from './locales'

export const i18n = createI18n({
  legacy: false,
  locale: resolveBrowserLocale(),
  fallbackLocale: defaultLocale,
  globalInjection: true,
  messages,
})
