<script setup lang="ts">
import { computed, onMounted, shallowRef, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import KanbanBoard from '@/components/kanban/KanbanBoard.vue'
import ProjectSidebar from '@/components/kanban/ProjectSidebar.vue'
import AuthenticatedLayout from '@/components/layout/AuthenticatedLayout.vue'
import { useAuth } from '@/composables/useAuth'
import { useBoard } from '@/composables/useBoard'
import { useProjects } from '@/composables/useProjects'
import { useUserGroups } from '@/composables/useUserGroups'
import AuthCallbackView from '@/views/AuthCallbackView.vue'
import AuthView from '@/views/AuthView.vue'
import DashboardView from '@/views/DashboardView.vue'
import ProjectsView from '@/views/ProjectsView.vue'
import TaskDetailPage from '@/views/TaskDetailPage.vue'
import UserGroupsView from '@/views/UserGroupsView.vue'
import type { AuthInput, ProjectInput, Task, TaskInput, TaskStatusOption } from '@/services/api'

const auth = useAuth()
const projects = useProjects()
const board = useBoard()
const userGroups = useUserGroups()
const route = useRoute()
const router = useRouter()
const ready = shallowRef(false)

const taskDetailId = computed(() => {
  if (route.name !== 'task-detail') return null

  const taskId = Number(route.params.taskId)
  return Number.isInteger(taskId) && taskId > 0 ? taskId : null
})

const userProfileId = computed(() => {
  if (route.name !== 'user-profile') return null

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

const userGroupsSection = computed<'users' | 'groups'>(() =>
  route.name === 'groups' || route.name === 'group-new' || route.name === 'group-detail'
    ? 'groups'
    : 'users',
)

const authenticatedPageTitle = computed(() => {
  if (route.name === 'projects') return 'Project management'
  if (userGroupsRoute.value) return 'Users & Groups'
  if (route.name === 'board' || route.name === 'task-detail') return 'Kanban'

  return 'Apps'
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

function editUser(userId: number) {
  void router.push({ name: 'user-profile', params: { userId } })
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

function isUserGroupsRouteName(routeName: unknown) {
  return (
    routeName === 'users' ||
    routeName === 'user-profile' ||
    routeName === 'groups' ||
    routeName === 'group-new' ||
    routeName === 'group-detail'
  )
}
</script>

<template>
  <main v-if="!ready" class="bg-background text-muted-foreground grid min-h-svh place-items-center">
    Loading...
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
    <DashboardView v-if="route.name === 'home'" />

    <ProjectsView
      v-else-if="route.name === 'projects'"
      :projects="projects.projects.value"
      :selected-project-id="projects.selectedProjectId.value"
      :loading="projects.loading.value"
      @create-project="createProject"
      @select-project="projects.selectProject"
    />

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
      :group-id="groupDetailId"
      :creating-group="creatingGroup"
      @save-group="saveGroup"
      @delete-group="userGroups.deleteGroup"
      @load-users="userGroups.loadUsers"
      @load-user="userGroups.loadUser"
      @load-groups="userGroups.loadGroups"
      @save-user-profile="userGroups.updateUserProfile"
      @edit-user="editUser"
      @select-group="selectGroup"
      @create-group="createGroup"
      @close-group-editor="closeGroupEditor"
    />

    <template v-else>
      <ProjectSidebar
        :projects="projects.projects.value"
        :selected-project-id="projects.selectedProjectId.value"
        :loading="projects.loading.value"
        @select-project="projects.selectProject"
      />

      <TaskDetailPage
        v-if="taskDetailId"
        :task-id="taskDetailId"
        @task-updated="refreshBoardAfterTaskUpdate"
      />

      <KanbanBoard
        v-else
        :project="board.project.value"
        :statuses="board.statuses.value"
        :task-count="board.taskCount.value"
        :loading="board.loading.value"
        @refresh="refreshBoard"
        @create-task="createTask"
        @update-task="board.updateTask"
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
