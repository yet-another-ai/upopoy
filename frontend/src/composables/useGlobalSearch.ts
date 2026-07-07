import { watchDebounced } from '@vueuse/core'
import { readonly, shallowRef, watch } from 'vue'
import { api, type SearchResult } from '@/services/api'

interface UseGlobalSearchOptions {
  limit?: number
  debounceMs?: number
}

export function useGlobalSearch(options: UseGlobalSearchOptions = {}) {
  const limit = options.limit ?? 8
  const debounceMs = options.debounceMs ?? 250
  const query = shallowRef('')
  const results = shallowRef<SearchResult[]>([])
  const loading = shallowRef(false)
  const searched = shallowRef(false)
  const error = shallowRef<string | null>(null)
  let requestId = 0

  watch(
    query,
    (value) => {
      if (value.trim()) return

      requestId += 1
      loading.value = false
      searched.value = false
      error.value = null
      results.value = []
    },
  )

  watchDebounced(
    query,
    (value) => {
      void search(value)
    },
    { debounce: debounceMs },
  )

  async function search(value = query.value) {
    const trimmedQuery = value.trim()
    const currentRequestId = requestId + 1
    requestId = currentRequestId

    if (!trimmedQuery) {
      results.value = []
      loading.value = false
      searched.value = false
      error.value = null
      return
    }

    loading.value = true
    error.value = null

    try {
      const response = await api.search({ q: trimmedQuery, limit })
      if (currentRequestId !== requestId) return

      results.value = response.results
      searched.value = true
    } catch {
      if (currentRequestId !== requestId) return

      results.value = []
      searched.value = true
      error.value = 'Search failed'
    } finally {
      if (currentRequestId === requestId) loading.value = false
    }
  }

  function clear() {
    requestId += 1
    query.value = ''
    results.value = []
    loading.value = false
    searched.value = false
    error.value = null
  }

  return {
    query,
    results: readonly(results),
    loading: readonly(loading),
    searched: readonly(searched),
    error: readonly(error),
    clear,
    search,
  }
}
