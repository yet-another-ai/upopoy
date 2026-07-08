import { authApi } from './api/auth'
import { groupsApi } from './api/groups'
import { projectsApi } from './api/projects'
import { searchApi } from './api/search'
import { settingsApi } from './api/settings'
import { tasksApi } from './api/tasks'
import { usersApi } from './api/users'

export * from './api/client'
export * from './api/types'

export const api = {
  ...settingsApi,
  ...authApi,
  ...usersApi,
  ...groupsApi,
  ...searchApi,
  ...projectsApi,
  ...tasksApi,
}
