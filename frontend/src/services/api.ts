export interface Project {
  id: number
  name: string
  description: string | null
  created_at: string
  updated_at: string
}

export interface User {
  id: number
  email: string
  display_name: string | null
  title: string | null
  bio: string | null
  created_at: string
  updated_at: string
}

export interface ManagedUser extends User {
  group_ids: number[]
  groups_count: number
}

export interface Group {
  id: number
  name: string
  description: string | null
  parent_group_id: number | null
  parent_group_name: string | null
  user_ids: number[]
  users_count: number
  created_at: string
  updated_at: string
}

export interface AuthInput {
  email: string
  password: string
  password_confirmation?: string
}

export interface AuthSession {
  user: User
  token: string
}

export interface AuthProvider {
  name: string
  label: string
  authorize_path: string
}

interface AuthResponse {
  user: User
}

export type TaskStatus = 'todo' | 'in_progress' | 'under_review' | 'done'

export type TaskPriority = 'low' | 'medium' | 'high'

export interface TaskStatusOption {
  id: TaskStatus
  name: string
  slug: string
  position: number
}

export interface TaskPriorityOption {
  id: TaskPriority
  name: string
}

export const TASK_PRIORITIES: readonly TaskPriorityOption[] = [
  { id: 'high', name: 'High' },
  { id: 'medium', name: 'Medium' },
  { id: 'low', name: 'Low' },
] as const

export interface Task {
  id: number
  project_id: number
  status: TaskStatus
  priority: TaskPriority
  title: string
  description: string | null
  deadline: string | null
  estimated_minutes: number | null
  position: number
  created_at: string
  updated_at: string
}

export interface BoardStatus extends TaskStatusOption {
  tasks: readonly Task[]
}

export interface Board {
  project: Project
  statuses: BoardStatus[]
}

export interface ProjectInput {
  name: string
  description?: string
}

export interface GroupInput {
  name: string
  description?: string
  parent_group_id?: number | null
  user_ids?: number[]
}

export interface UserProfileInput {
  email: string
  display_name?: string
  title?: string
  bio?: string
}

export interface UserPaginationMeta {
  current_page: number
  total_pages: number
  total_count: number
  per_page: number
}

export interface PaginatedUsers {
  users: ManagedUser[]
  meta: UserPaginationMeta
}

export interface UserListParams {
  page?: number
  perPage?: number
}

export interface TaskInput {
  status?: TaskStatus
  priority?: TaskPriority
  title: string
  description?: string
  deadline?: string | null
  estimated_minutes?: number | null
  position?: number
}

const jsonHeaders = {
  Accept: 'application/json',
  'Content-Type': 'application/json',
}

const AUTH_TOKEN_STORAGE_KEY = 'upopoy.authToken'

let authToken =
  typeof localStorage === 'undefined' ? null : localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)

export class ApiError extends Error {
  readonly status: number

  constructor(message: string, status: number) {
    super(message)
    this.name = 'ApiError'
    this.status = status
  }
}

export function setAuthToken(token: string | null) {
  authToken = token

  if (typeof localStorage === 'undefined') return

  if (token) localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, token)
  else localStorage.removeItem(AUTH_TOKEN_STORAGE_KEY)
}

export function getAuthToken() {
  return authToken
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(path, {
    ...options,
    headers: {
      ...jsonHeaders,
      ...(authToken ? { Authorization: authToken } : {}),
      ...options.headers,
    },
  })

  if (response.status === 204) return undefined as T

  const data = await parseResponseBody(response)

  if (!response.ok) {
    throw new ApiError(errorMessage(data), response.status)
  }

  return data as T
}

async function requestAuth(path: string, input: AuthInput): Promise<AuthSession> {
  const response = await fetch(path, {
    method: 'POST',
    headers: jsonHeaders,
    body: JSON.stringify({ user: input }),
  })
  const data = await parseResponseBody(response)

  if (!response.ok) {
    throw new ApiError(errorMessage(data), response.status)
  }

  const token = response.headers.get('Authorization')
  if (!token) throw new ApiError('Authentication token missing', response.status)

  return {
    user: (data as AuthResponse).user,
    token,
  }
}

async function parseResponseBody(response: Response) {
  const contentType = response.headers.get('Content-Type') ?? ''
  if (contentType.includes('application/json')) return response.json()

  return response.text()
}

function errorMessage(data: unknown) {
  if (typeof data === 'string' && data) return data
  if (data && typeof data === 'object') {
    if ('errors' in data)
      return Object.values(data.errors as Record<string, string[]>)
        .flat()
        .join(', ')
    if ('error' in data && typeof data.error === 'string') return data.error
    if ('message' in data && typeof data.message === 'string') return data.message
  }

  return 'Request failed'
}

function userListPath(params: UserListParams = {}) {
  const searchParams = new URLSearchParams()
  if (params.page) searchParams.set('page', String(params.page))
  if (params.perPage) searchParams.set('per_page', String(params.perPage))

  const query = searchParams.toString()
  return query ? `/api/v1/users?${query}` : '/api/v1/users'
}

export const api = {
  listAuthProviders: () => request<AuthProvider[]>('/api/v1/auth/providers'),
  signUp: (input: AuthInput) => requestAuth('/api/v1/auth/signup', input),
  login: (input: AuthInput) => requestAuth('/api/v1/auth/login', input),
  logout: () =>
    request<{ message: string }>('/api/v1/auth/logout', {
      method: 'DELETE',
    }),
  me: () => request<AuthResponse>('/api/v1/auth/me'),
  listUsers: (params?: UserListParams) => request<PaginatedUsers>(userListPath(params)),
  getUser: (userId: number) => request<ManagedUser>(`/api/v1/users/${userId}`),
  updateUser: (userId: number, user: UserProfileInput) =>
    request<ManagedUser>(`/api/v1/users/${userId}`, {
      method: 'PATCH',
      body: JSON.stringify({ user }),
    }),
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
  listProjects: () => request<Project[]>('/api/v1/projects'),
  createProject: (project: ProjectInput) =>
    request<Project>('/api/v1/projects', {
      method: 'POST',
      body: JSON.stringify({ project }),
    }),
  getBoard: (projectId: number) => request<Board>(`/api/v1/projects/${projectId}/board`),
  getTask: (taskId: number) => request<Task>(`/api/v1/tasks/${taskId}`),
  createTask: (projectId: number, task: TaskInput) =>
    request<Task>(`/api/v1/projects/${projectId}/tasks`, {
      method: 'POST',
      body: JSON.stringify({ task }),
    }),
  updateTask: (taskId: number, task: Partial<TaskInput>) =>
    request<Task>(`/api/v1/tasks/${taskId}`, {
      method: 'PATCH',
      body: JSON.stringify({ task }),
    }),
  deleteTask: (taskId: number) =>
    request<void>(`/api/v1/tasks/${taskId}`, {
      method: 'DELETE',
    }),
}
