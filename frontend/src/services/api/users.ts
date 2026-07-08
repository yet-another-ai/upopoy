import { request } from './client'
import type { ManagedUser, PaginatedUsers, UserListParams, UserProfileInput } from './types'

function userListPath(params: UserListParams = {}) {
  const searchParams = new URLSearchParams()
  if (params.page) searchParams.set('page', String(params.page))
  if (params.perPage) searchParams.set('per_page', String(params.perPage))

  const query = searchParams.toString()
  return query ? `/api/v1/users?${query}` : '/api/v1/users'
}

export const usersApi = {
  listUsers: (params?: UserListParams) => request<PaginatedUsers>(userListPath(params)),
  getUser: (userId: number) => request<ManagedUser>(`/api/v1/users/${userId}`),
  updateUser: (userId: number, user: UserProfileInput) =>
    request<ManagedUser>(`/api/v1/users/${userId}`, {
      method: 'PATCH',
      body: JSON.stringify({ user }),
    }),
}
