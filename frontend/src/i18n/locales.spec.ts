import { describe, expect, it } from 'vitest'
import { resolveBrowserLocale } from './locales'

describe('resolveBrowserLocale', () => {
  it('uses Simplified Chinese for zh-CN and zh-Hans browser languages', () => {
    expect(resolveBrowserLocale(['zh-CN'])).toBe('zh-CN')
    expect(resolveBrowserLocale(['zh-Hans-US'])).toBe('zh-CN')
  })

  it('uses English for en browser languages', () => {
    expect(resolveBrowserLocale(['en-US'])).toBe('en')
  })

  it('falls back to the first supported browser language', () => {
    expect(resolveBrowserLocale(['fr-FR', 'zh'])).toBe('zh-CN')
  })

  it('falls back to English for unsupported browser languages', () => {
    expect(resolveBrowserLocale(['fr-FR'])).toBe('en')
  })
})
