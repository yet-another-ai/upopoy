export interface Project {
  id: number
  group_id: number
  group_name: string | null
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
  skills: UserSkill[]
  system_admin: boolean
  created_at: string
  updated_at: string
}

export type UserSkillLevel = 'learning' | 'working' | 'advanced' | 'expert'

export interface UserSkill {
  name: string
  level: UserSkillLevel
  note: string
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
  admin_user_ids: number[]
  admins_count: number
  can_admin: boolean
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

export interface AuthSettings {
  registration_enabled: boolean
  email_login_enabled: boolean
}

export interface AdminSettings extends AuthSettings {
  updated_at: string
}

export type AdminSettingsInput = Partial<AuthSettings>

export interface AuthResponse {
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
  iteration_id: number
  iteration_name: string
  iteration_starts_at: string | null
  iteration_deadline: string | null
  iteration_inbox: boolean
  status: TaskStatus
  priority: TaskPriority
  title: string
  description: string | null
  deadline: string | null
  estimated_minutes: number | null
  developer_ids: number[]
  developers: User[]
  reviewer_ids: number[]
  reviewers: User[]
  position: number
  created_at: string
  updated_at: string
}

export interface Iteration {
  id: number
  project_id: number
  name: string
  starts_at: string | null
  deadline: string | null
  inbox: boolean
  task_count: number
  created_at: string
  updated_at: string
}

export interface BoardStatus extends TaskStatusOption {
  tasks: readonly Task[]
}

export interface Board {
  project: Project
  iterations: Iteration[]
  inbox_iteration: Iteration
  statuses: BoardStatus[]
}

export type DriveItemKind = 'folder' | 'file'

export interface DriveItem {
  id: number
  project_id: number
  parent_id: number | null
  kind: DriveItemKind
  name: string
  text_content_cache: string
  markdown: boolean
  content_type: string | null
  byte_size: number | null
  download_path: string | null
  deleted_at: string | null
  versions_count: number
  latest_version_number: number | null
  created_at: string
  updated_at: string
}

export interface DriveItemVersion {
  id: number
  drive_item_id: number
  version_number: number
  name: string
  content_type: string | null
  byte_size: number | null
  text_content_cache: string
  markdown: boolean
  download_path: string
  created_at: string
  updated_at: string
}

export interface DriveItemInput {
  kind: DriveItemKind
  name?: string
  parent_id?: number | null
  content?: string
  base_version_number?: number | null
}

export interface DriveItemContent {
  content: string
}

export type SearchResultType = 'drive_item' | 'project' | 'task' | 'user' | 'group'

export interface SearchResult {
  slug: string
  type: SearchResultType
  id: number
  title: string
  snippet: string
  api_path: string
  metadata: Record<string, unknown>
  updated_at: string
}

export interface SearchResponse {
  results: SearchResult[]
}

export interface SearchParams {
  q: string
  type?: SearchResultType
  limit?: number
}

export interface ProjectInput {
  name: string
  description?: string
  group_id: number
}

export interface GroupInput {
  name: string
  description?: string
  parent_group_id?: number | null
  user_ids?: number[]
  admin_user_ids?: number[]
}

export interface UserProfileInput {
  email: string
  display_name?: string
  title?: string
  bio?: string
  skills?: UserSkill[]
  system_admin?: boolean
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
  developer_ids?: number[]
  reviewer_ids?: number[]
  iteration_id?: number | null
  position?: number
}

export interface IterationInput {
  name: string
  starts_at: string
  deadline: string
}
