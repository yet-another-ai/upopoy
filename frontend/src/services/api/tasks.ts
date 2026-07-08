import { request } from './client'
import type { Board, Iteration, IterationInput, Task, TaskInput } from './types'

export const tasksApi = {
  getBoard: (projectId: number) => request<Board>(`/api/v1/projects/${projectId}/board`),
  listIterations: (projectId: number) =>
    request<Iteration[]>(`/api/v1/projects/${projectId}/iterations`),
  createIteration: (projectId: number, iteration: IterationInput) =>
    request<Iteration>(`/api/v1/projects/${projectId}/iterations`, {
      method: 'POST',
      body: JSON.stringify({ iteration }),
    }),
  updateIteration: (iterationId: number, iteration: Partial<IterationInput>) =>
    request<Iteration>(`/api/v1/iterations/${iterationId}`, {
      method: 'PATCH',
      body: JSON.stringify({ iteration }),
    }),
  deleteIteration: (iterationId: number) =>
    request<void>(`/api/v1/iterations/${iterationId}`, {
      method: 'DELETE',
    }),
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
