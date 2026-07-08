<script setup lang="ts">
import { computed, onMounted, shallowRef, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import IterationsView from '@/components/kanban/IterationsView.vue'
import KanbanBoard from '@/components/kanban/KanbanBoard.vue'
import ProjectSidebar from '@/components/kanban/ProjectSidebar.vue'
import AuthenticatedLayout from '@/components/layout/AuthenticatedLayout.vue'
import GlobalSearch from '@/components/search/GlobalSearch.vue'
import { useAuth } from '@/composables/useAuth'
import { useBoard } from '@/composables/useBoard'
import { useProjects } from '@/composables/useProjects'
import { useUserGroups } from '@/composables/useUserGroups'
import AdminSettingsView from '@/views/AdminSettingsView.vue'
import AuthCallbackView from '@/views/AuthCallbackView.vue'
import AuthView from '@/views/AuthView.vue'
import DashboardView from '@/views/DashboardView.vue'
import ProjectsView from '@/views/ProjectsView.vue'
import TaskDetailPage from '@/views/TaskDetailPage.vue'
import UserGroupsView from '@/views/UserGroupsView.vue'
import type {
  AuthInput,
  ProjectInput,
  SearchResult,
  Task,
  TaskInput,
  TaskStatusOption,
} from '@/services/api'

type BoardView = 'kanban' | 'iterations'

const auth = useAuth()
const projects = useProjects()
const board = useBoard()
const userGroups = useUserGroups()
const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const ready = shallowRef(false)
const boardView = shallowRef<BoardView>('kanban')

const taskDetailId = computed(() => {
  if (route.name !== 'task-detail') return null

  const taskId = Number(route.params.taskId)
  return Number.isInteger(taskId) && taskId > 0 ? taskId : null
})

const userProfileId = computed(() => {
  if (route.name !== 'user-profile' && route.name !== 'user-edit') return null

  const userId = Number(route.params.userId)
  return Number.isInteger(userId) && userId > 0 ? userId : null
})

const groupDetailId = computed(() => {
  if (route.name !== 'group-detail') return null

  const groupId = Number(route.params.groupId)
  return Number.isInteger(groupId) && groupId > 0 ? groupId : null
})

const userGroupsRoute = computed(() => isUserGroupsRouteName(route.name))
const creatingGroup = computed(() => route.name === 'group-new')
const editingUser = computed(() => route.name === 'user-edit')

const userGroupsSection = computed<'users' | 'groups'>(() =>
  route.name === 'groups' || route.name === 'group-new' || route.name === 'group-detail'
    ? 'groups'
    : 'users',
)

const authenticatedPageTitle = computed(() => {
  if (route.name === 'admin-settings') return t('navigation.adminSettings')
  if (route.name === 'projects') return t('navigation.projectManagement')
  if (userGroupsRoute.value) return t('navigation.usersAndGroups')
  if (route.name === 'board' || route.name === 'task-detail') return t('navigation.kanban')

  return t('navigation.apps')
})

const authenticatedContentClass = computed(() => {
  if (route.name === 'board' || route.name === 'task-detail') {
    return 'flex min-h-0 w-full flex-1 flex-col p-0 lg:flex-row'
  }
  if (userGroupsRoute.value) return 'mx-auto w-full max-w-6xl px-5 py-6'

  return 'mx-auto w-full max-w-5xl px-5 py-6'
})

onMounted(() => {
  void initializeApp()
})

watch(
  () => projects.selectedProjectId.value,
  (projectId) => {
    if (auth.authenticated.value && projectId) void board.loadBoard(projectId)
  },
)

watch(
  () => route.name,
  (routeName) => {
    if (auth.authenticated.value && isUserGroupsRouteName(routeName)) {
      void userGroups.loadDirectory()
    }
  },
)

async function initializeApp() {
  await router.isReady()
  await restoreSession()
}

async function restoreSession() {
  if (route.name === 'auth-callback') {
    ready.value = true
    return
  }

  const authenticated = await auth.restoreSession()
  ready.value = true

  if (!authenticated) {
    await router.replace({ name: 'auth' })
    return
  }

  if (route.name === 'auth') await router.replace({ name: 'home' })

  await projects.loadProjects()
  await userGroups.loadGroups()
  if (userGroupsRoute.value) await userGroups.loadDirectory()
}

async function login(input: AuthInput) {
  await auth.login(input)
  await enterWorkspace()
}

async function signUp(input: AuthInput) {
  await auth.signUp(input)
  await enterWorkspace()
}

async function completeOAuth(token: string) {
  await auth.acceptToken(token)
  ready.value = true
  await enterWorkspace()
}

async function failOAuth(message: string) {
  auth.failAuthentication(message)
  ready.value = true
  await router.replace({ name: 'auth' })
}

async function enterWorkspace() {
  await router.push({ name: 'home' })
  await projects.loadProjects()
  await userGroups.loadGroups()
}

async function signOut() {
  await auth.logout()
  projects.clearProjects()
  board.clearBoard()
  userGroups.clearDirectory()
  await router.push({ name: 'auth' })
}

async function createProject(input: ProjectInput) {
  await projects.createProject(input)
}

async function refreshBoard() {
  const projectId = projects.selectedProjectId.value
  if (projectId) await board.loadBoard(projectId)
}

async function createTask(_status: TaskStatusOption['id'], input: TaskInput) {
  const projectId = projects.selectedProjectId.value
  if (projectId) await board.createTask(projectId, input)
}

async function createIteration(input: Parameters<typeof board.createIteration>[1]) {
  const projectId = projects.selectedProjectId.value
  if (projectId) await board.createIteration(projectId, input)
}

async function refreshBoardAfterTaskUpdate(task: Task) {
  if (projects.selectedProjectId.value !== task.project_id) projects.selectProject(task.project_id)

  await board.loadBoard(task.project_id)
}

async function saveGroup(
  groupId: number | null,
  input: Parameters<typeof userGroups.createGroup>[0],
) {
  if (groupId) await userGroups.updateGroup(groupId, input)
  else await userGroups.createGroup(input)

  await router.push({ name: 'groups' })
}

async function saveUserProfile(
  userId: number,
  input: Parameters<typeof userGroups.updateUserProfile>[1],
) {
  await userGroups.updateUserProfile(userId, input)
  await router.push({ name: 'user-profile', params: { userId } })
}

function editUser(userId: number) {
  void router.push({ name: 'user-profile', params: { userId } })
}

function cancelUserEdit() {
  const userId = userProfileId.value
  if (userId) void router.push({ name: 'user-profile', params: { userId } })
  else void router.push({ name: 'users' })
}

function selectGroup(groupId: number | null) {
  if (groupId) void router.push({ name: 'group-detail', params: { groupId } })
  else void router.push({ name: 'groups' })
}

function createGroup() {
  void router.push({ name: 'group-new' })
}

function closeGroupEditor() {
  void router.push({ name: 'groups' })
}

async function openSearchResult(result: SearchResult) {
  if (result.type === 'project') {
    projects.selectProject(result.id)
    await board.loadBoard(result.id)
    await router.push({ name: 'board' })
    return
  }

  if (result.type === 'task') {
    const projectId = Number(result.metadata.project_id)
    if (Number.isInteger(projectId) && projectId > 0) projects.selectProject(projectId)

    await router.push({ name: 'task-detail', params: { taskId: result.id } })
    return
  }

  if (result.type === 'user') {
    await router.push({ name: 'user-profile', params: { userId: result.id } })
    return
  }

  await router.push({ name: 'group-detail', params: { groupId: result.id } })
}

function isUserGroupsRouteName(routeName: unknown) {
  return (
    routeName === 'users' ||
    routeName === 'user-profile' ||
    routeName === 'user-edit' ||
    routeName === 'groups' ||
    routeName === 'group-new' ||
    routeName === 'group-detail'
  )
}
</script>

<template>
  <main v-if="!ready" class="bg-background text-muted-foreground grid min-h-svh place-items-center">
    {{ t('common.loading') }}
  </main>

  <AuthCallbackView
    v-else-if="route.name === 'auth-callback'"
    @complete="completeOAuth"
    @failed="failOAuth"
  />

  <AuthView
    v-else-if="!auth.authenticated.value || route.name === 'auth'"
    :loading="auth.loading.value"
    :error="auth.error.value"
    @login="login"
    @signup="signUp"
  />

  <AuthenticatedLayout
    v-else-if="auth.user.value"
    :current-user="auth.user.value"
    :title="authenticatedPageTitle"
    :content-class="authenticatedContentClass"
    @sign-out="signOut"
  >
    <template #header-actions>
      <GlobalSearch @select-result="openSearchResult" />
    </template>

    <DashboardView v-if="route.name === 'home'" />

    <ProjectsView
      v-else-if="route.name === 'projects'"
      :projects="projects.projects.value"
      :groups="userGroups.groups.value"
      :selected-project-id="projects.selectedProjectId.value"
      :loading="projects.loading.value"
      :loading-groups="userGroups.loadingGroups.value"
      @create-project="createProject"
      @select-project="projects.selectProject"
    />

    <AdminSettingsView v-else-if="route.name === 'admin-settings'" />

    <UserGroupsView
      v-else-if="userGroupsRoute"
      :users="userGroups.users.value"
      :users-meta="userGroups.usersMeta.value"
      :groups="userGroups.groups.value"
      :loading="userGroups.loading.value"
      :loading-users="userGroups.loadingUsers.value"
      :loading-groups="userGroups.loadingGroups.value"
      :saving="userGroups.saving.value"
      :section="userGroupsSection"
      :user-id="userProfileId"
      :editing-user="editingUser"
      :group-id="groupDetailId"
      :creating-group="creatingGroup"
      @save-group="saveGroup"
      @delete-group="userGroups.deleteGroup"
      @load-users="userGroups.loadUsers"
      @load-user="userGroups.loadUser"
      @load-groups="userGroups.loadGroups"
      @save-user-profile="saveUserProfile"
      @cancel-user-edit="cancelUserEdit"
      @edit-user="editUser"
      @select-group="selectGroup"
      @create-group="createGroup"
      @close-group-editor="closeGroupEditor"
    />

    <template v-else>
      <ProjectSidebar
        :projects="projects.projects.value"
        :selected-project-id="projects.selectedProjectId.value"
        :active-view="boardView"
        :loading="projects.loading.value"
        @select-project="projects.selectProject"
        @select-view="boardView = $event"
      />

      <TaskDetailPage
        v-if="taskDetailId"
        :task-id="taskDetailId"
        @task-updated="refreshBoardAfterTaskUpdate"
      />

      <KanbanBoard
        v-else-if="boardView === 'kanban'"
        :project="board.project.value"
        :statuses="board.statuses.value"
        :iterations="board.iterations.value"
        :inbox-iteration="board.inboxIteration.value"
        :task-count="board.taskCount.value"
        :loading="board.loading.value"
        @refresh="refreshBoard"
        @create-task="createTask"
        @update-task="board.updateTask"
        @delete-task="board.deleteTask"
      />

      <IterationsView
        v-else
        :project="board.project.value"
        :iterations="board.iterations.value"
        :statuses="board.statuses.value"
        :loading="board.loading.value"
        @refresh="refreshBoard"
        @create-iteration="createIteration"
        @create-task="createTask"
        @delete-task="board.deleteTask"
      />
    </template>
  </AuthenticatedLayout>

  <div
    v-if="projects.error.value || board.error.value || userGroups.error.value"
    class="bg-destructive text-destructive-foreground fixed bottom-4 left-1/2 z-50 max-w-[calc(100vw-2rem)] -translate-x-1/2 rounded-lg px-4 py-2 text-sm shadow-lg"
  >
    {{ projects.error.value ?? board.error.value ?? userGroups.error.value }}
  </div>
</template>
