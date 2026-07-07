import { flushPromises } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { api, type SearchResult } from '@/services/api'
import { useGlobalSearch } from '../useGlobalSearch'

vi.mock('@/services/api', () => ({
  api: {
    search: vi.fn(),
  },
}))

const result: SearchResult = {
  slug: 'task:1',
  type: 'task',
  id: 1,
  title: 'Draft MCP API',
  snippet: 'Keep resources clear.',
  api_path: '/api/v1/tasks/1',
  metadata: { project_id: 2 },
  updated_at: '2026-07-07T00:00:00Z',
}

describe('useGlobalSearch', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('debounces search requests', async () => {
    vi.mocked(api.search).mockResolvedValue({ results: [result] })
    const search = useGlobalSearch({ debounceMs: 300, limit: 5 })

    search.query.value = 'draft'
    await vi.advanceTimersByTimeAsync(299)

    expect(api.search).not.toHaveBeenCalled()

    await vi.advanceTimersByTimeAsync(1)
    await flushPromises()

    expect(api.search).toHaveBeenCalledWith({ q: 'draft', limit: 5 })
    expect(search.results.value).toEqual([result])
    expect(search.searched.value).toBe(true)
  })

  it('does not request blank queries', async () => {
    const search = useGlobalSearch({ debounceMs: 300 })

    search.query.value = '   '
    await vi.advanceTimersByTimeAsync(300)
    await flushPromises()

    expect(api.search).not.toHaveBeenCalled()
    expect(search.results.value).toEqual([])
  })
})
