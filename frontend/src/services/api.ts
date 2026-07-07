export interface Project {
  id: number
  name: string
  description: string | null
  created_at: string
  updated_at: string
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

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(path, {
    ...options,
    headers: {
      ...jsonHeaders,
      ...options.headers,
    },
  })

  if (response.status === 204) return undefined as T

  const data = await response.json()

  if (!response.ok) {
    const message = data?.errors ? Object.values(data.errors).flat().join(', ') : 'Request failed'
    throw new Error(message)
  }

  return data as T
}

export const api = {
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
