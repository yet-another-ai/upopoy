<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import KanbanBoard from '@/components/kanban/KanbanBoard.vue'
import ProjectSidebar from '@/components/kanban/ProjectSidebar.vue'
import { useBoard } from '@/composables/useBoard'
import { useProjects } from '@/composables/useProjects'
import TaskDetailPage from '@/views/TaskDetailPage.vue'
import type { Task, TaskInput, TaskStatusOption } from '@/services/api'

const projects = useProjects()
const board = useBoard()
const route = useRoute()

const taskDetailId = computed(() => {
  if (route.name !== 'task-detail') return null

  const taskId = Number(route.params.taskId)
  return Number.isInteger(taskId) && taskId > 0 ? taskId : null
})

onMounted(() => {
  void projects.loadProjects()
})

watch(
  () => projects.selectedProjectId.value,
  (projectId) => {
    if (projectId) void board.loadBoard(projectId)
  },
)

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
  <div class="bg-background text-foreground flex min-h-svh flex-col lg:flex-row">
    <ProjectSidebar
      :projects="projects.projects.value"
      :selected-project-id="projects.selectedProjectId.value"
      :loading="projects.loading.value"
      @select-project="projects.selectProject"
      @create-project="createProject"
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
