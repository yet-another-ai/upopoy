<script setup lang="ts">
import { computed, onMounted, shallowRef, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import KanbanBoard from '@/components/kanban/KanbanBoard.vue'
import ProjectSidebar from '@/components/kanban/ProjectSidebar.vue'
import { useAuth } from '@/composables/useAuth'
import { useBoard } from '@/composables/useBoard'
import { useProjects } from '@/composables/useProjects'
import AuthCallbackView from '@/views/AuthCallbackView.vue'
import AuthView from '@/views/AuthView.vue'
import TaskDetailPage from '@/views/TaskDetailPage.vue'
import type { AuthInput, Task, TaskInput, TaskStatusOption } from '@/services/api'

const auth = useAuth()
const projects = useProjects()
const board = useBoard()
const route = useRoute()
const router = useRouter()
const ready = shallowRef(false)

const taskDetailId = computed(() => {
  if (route.name !== 'task-detail') return null

  const taskId = Number(route.params.taskId)
  return Number.isInteger(taskId) && taskId > 0 ? taskId : null
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

  if (route.name === 'auth') await router.replace({ name: 'board' })

  await projects.loadProjects()
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
  await router.push({ name: 'board' })
  await projects.loadProjects()
}

async function signOut() {
  await auth.logout()
  projects.clearProjects()
  board.clearBoard()
  await router.push({ name: 'auth' })
}

async function createProject(input: { name: string; description?: string }) {
  const project = await projects.createProject(input)
  await board.loadBoard(project.id)
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

  <div
    v-else-if="auth.user.value"
    class="bg-background text-foreground flex min-h-svh flex-col lg:flex-row"
  >
    <ProjectSidebar
      :projects="projects.projects.value"
      :selected-project-id="projects.selectedProjectId.value"
      :loading="projects.loading.value"
      :current-user="auth.user.value"
      @select-project="projects.selectProject"
      @create-project="createProject"
      @sign-out="signOut"
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
  </div>

  <div
    v-if="projects.error.value || board.error.value"
    class="bg-destructive text-destructive-foreground fixed bottom-4 left-1/2 z-50 max-w-[calc(100vw-2rem)] -translate-x-1/2 rounded-lg px-4 py-2 text-sm shadow-lg"
  >
    {{ projects.error.value ?? board.error.value }}
  </div>
</template>
