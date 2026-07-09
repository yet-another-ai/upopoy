import { authApi } from './api/auth'
import { chatsApi } from './api/chats'
import { organizationsApi } from './api/organizations'
import { driveApi } from './api/drive'
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
  ...chatsApi,
  ...organizationsApi,
  ...driveApi,
  ...searchApi,
  ...projectsApi,
  ...tasksApi,
}
