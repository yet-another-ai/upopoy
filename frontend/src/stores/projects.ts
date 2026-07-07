import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, shallowRef } from 'vue'
import { api, type Project, type ProjectInput } from '@/services/api'

export const useProjectsStore = defineStore('projects', () => {
  const projects = shallowRef<Project[]>([])
  const selectedProjectId = shallowRef<number | null>(null)
  const loading = shallowRef(false)
  const error = shallowRef<string | null>(null)

  const selectedProject = computed(
    () => projects.value.find((project) => project.id === selectedProjectId.value) ?? null,
  )

  async function loadProjects() {
    loading.value = true
    error.value = null

    try {
      projects.value = await api.listProjects()
      selectedProjectId.value = selectedProjectId.value ?? projects.value[0]?.id ?? null
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load projects'
    } finally {
      loading.value = false
    }
  }

  async function createProject(input: ProjectInput) {
    const project = await api.createProject(input)
    projects.value = [project, ...projects.value]
    selectedProjectId.value = project.id
    return project
  }

  function selectProject(projectId: number) {
    selectedProjectId.value = projectId
  }

  function clearProjects() {
    projects.value = []
    selectedProjectId.value = null
    error.value = null
  }

  return {
    projects,
    selectedProject,
    selectedProjectId,
    loading,
    error,
    loadProjects,
    createProject,
    selectProject,
    clearProjects,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useProjectsStore, import.meta.hot))
}
