import { request } from './client'
import type { Group, GroupInput } from './types'

export const groupsApi = {
  listGroups: () => request<Group[]>('/api/v1/groups'),
  createGroup: (group: GroupInput) =>
    request<Group>('/api/v1/groups', {
      method: 'POST',
      body: JSON.stringify({ group }),
    }),
  updateGroup: (groupId: number, group: GroupInput) =>
    request<Group>(`/api/v1/groups/${groupId}`, {
      method: 'PATCH',
      body: JSON.stringify({ group }),
    }),
  deleteGroup: (groupId: number) =>
    request<void>(`/api/v1/groups/${groupId}`, {
      method: 'DELETE',
    }),
}
