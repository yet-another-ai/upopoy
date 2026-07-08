import { request } from './client'
import type { SearchParams, SearchResponse } from './types'

function searchPath(params: SearchParams) {
  const searchParams = new URLSearchParams({ q: params.q })
  if (params.type) searchParams.set('type', params.type)
  if (params.limit) searchParams.set('limit', String(params.limit))

  return `/api/v1/search?${searchParams.toString()}`
}

export const searchApi = {
  search: (params: SearchParams) => request<SearchResponse>(searchPath(params)),
}
