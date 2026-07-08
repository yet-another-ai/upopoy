import { vi } from 'vitest'
import { config } from '@vue/test-utils'
import { i18n } from '@/i18n'

config.global.plugins = [i18n]

Object.defineProperty(window, 'ResizeObserver', {
  writable: true,
  value: vi.fn().mockImplementation(() => ({
    observe: vi.fn(),
    unobserve: vi.fn(),
    disconnect: vi.fn(),
  })),
})
