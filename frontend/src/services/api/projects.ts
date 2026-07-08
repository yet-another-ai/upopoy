import { request } from './client'
import type { Project, ProjectInput } from './types'

export const projectsApi = {
  listProjects: () => request<Project[]>('/api/v1/projects'),
  createProject: (project: ProjectInput) =>
    request<Project>('/api/v1/projects', {
      method: 'POST',
      body: JSON.stringify({ project }),
    }),
}
