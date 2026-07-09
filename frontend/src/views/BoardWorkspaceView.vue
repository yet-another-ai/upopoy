<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, onMounted, shallowRef, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import DriveSidebar from '@/components/drive/DriveSidebar.vue'
import DriveWorkspace from '@/components/drive/DriveWorkspace.vue'
import IterationsView from '@/components/kanban/IterationsView.vue'
import KanbanBoard from '@/components/kanban/KanbanBoard.vue'
import ProjectSidebar from '@/components/kanban/ProjectSidebar.vue'
import { positiveIntegerRouteParam } from '@/lib/route'
import { useBoardStore } from '@/stores/board'
import { useProjectsStore } from '@/stores/projects'
import { useToastsStore } from '@/stores/toasts'
import TaskDetailPage from '@/views/TaskDetailPage.vue'
import MarkdownDriveEditorView from '@/views/MarkdownDriveEditorView.vue'
import type { Task, TaskInput, TaskStatusOption } from '@/services/api'

type AppView = 'drive' | 'kanban' | 'iterations'
type KanbanView = 'kanban' | 'iterations'

const route = useRoute()
const router = useRouter()
const projectsStore = useProjectsStore()
const boardStore = useBoardStore()
const toasts = useToastsStore()
const projects = storeToRefs(projectsStore)
const board = storeToRefs(boardStore)
const boardView = shallowRef<AppView>(isDriveRoute(route.name) ? 'drive' : 'kanban')

const taskDetailId = computed(() =>
  route.name === 'task-detail' ? positiveIntegerRouteParam(route, 'taskId') : null,
)
const isDriveEditorRoute = computed(() => route.name === 'drive-item-edit')
const kanbanView = computed<KanbanView>(() => (boardView.value === 'iterations' ? 'iterations' : 'kanban'))

onMounted(async () => {
  const selectedProjectIdBeforeLoad = projects.selectedProjectId.value

  if (projects.projects.value.length === 0) await projectsStore.loadProjects()
  if (
    projects.selectedProjectId.value &&
    projects.selectedProjectId.value === selectedProjectIdBeforeLoad &&
    boardView.value !== 'drive'
  ) {
    await boardStore.loadBoard(projects.selectedProjectId.value)
  }
})

watch(
  () => projects.selectedProjectId.value,
  (projectId) => {
    if (projectId && boardView.value !== 'drive') void boardStore.loadBoard(projectId)
  },
)

watch(
  () => route.name,
  (routeName) => {
    boardView.value = isDriveRoute(routeName) ? 'drive' : 'kanban'
  },
)

async function refreshBoard() {
  const projectId = projects.selectedProjectId.value
  if (!projectId) return

  await boardStore.loadBoard(projectId)
  if (board.error.value) toasts.error('Unable to refresh board', board.error.value)
}

async function createTask(_status: TaskStatusOption['id'], input: TaskInput) {
  const projectId = projects.selectedProjectId.value
  if (!projectId) return

  try {
    await boardStore.createTask(projectId, input)
  } catch (err) {
    notifyError(err, 'Unable to create task')
  }
}

async function createIteration(input: Parameters<typeof boardStore.createIteration>[1]) {
  const projectId = projects.selectedProjectId.value
  if (!projectId) return

  try {
    await boardStore.createIteration(projectId, input)
  } catch (err) {
    notifyError(err, 'Unable to create iteration')
  }
}

async function refreshBoardAfterTaskUpdate(task: Task) {
  if (projects.selectedProjectId.value !== task.project_id) projectsStore.selectProject(task.project_id)

  await boardStore.loadBoard(task.project_id)
}

async function updateTask(taskId: number, input: Partial<TaskInput>) {
  try {
    await boardStore.updateTask(taskId, input)
  } catch (err) {
    notifyError(err, 'Unable to update task')
  }
}

async function deleteTask(taskId: number) {
  try {
    await boardStore.deleteTask(taskId)
  } catch (err) {
    notifyError(err, 'Unable to delete task')
  }
}

function notifyError(err: unknown, fallback: string) {
  toasts.error(fallback, err instanceof Error ? err.message : fallback)
}

async function selectKanbanView(view: KanbanView) {
  boardView.value = view

  if (isDriveRoute(route.name)) await router.push({ name: 'board' })

  const projectId = projects.selectedProjectId.value
  if (projectId) await boardStore.loadBoard(projectId)
}

function isDriveRoute(routeName: unknown) {
  return routeName === 'drive' || routeName === 'drive-item-edit'
}
</script>

<template>
  <DriveSidebar
    v-if="boardView === 'drive'"
    :projects="projects.projects.value"
    :selected-project-id="projects.selectedProjectId.value"
    :loading="projects.loading.value"
    @select-project="projectsStore.selectProject"
  />

  <ProjectSidebar
    v-else
    :projects="projects.projects.value"
    :selected-project-id="projects.selectedProjectId.value"
    :active-view="kanbanView"
    :loading="projects.loading.value"
    @select-project="projectsStore.selectProject"
    @select-view="selectKanbanView"
  />

  <TaskDetailPage
    v-if="taskDetailId"
    :task-id="taskDetailId"
    @task-updated="refreshBoardAfterTaskUpdate"
  />

  <DriveWorkspace
    v-else-if="boardView === 'drive' && !isDriveEditorRoute"
    :project="projects.selectedProject.value"
    :projects-loading="projects.loading.value"
  />

  <MarkdownDriveEditorView v-else-if="boardView === 'drive' && isDriveEditorRoute" />

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
    @update-task="updateTask"
    @delete-task="deleteTask"
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
    @delete-task="deleteTask"
  />
</template>
