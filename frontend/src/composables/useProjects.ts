import { storeToRefs } from 'pinia'
import { useProjectsStore } from '@/stores/projects'

export function useProjects() {
  const store = useProjectsStore()
  const { projects, selectedProject, selectedProjectId, loading, error } = storeToRefs(store)

  return {
    projects,
    selectedProject,
    selectedProjectId,
    loading,
    error,
    loadProjects: store.loadProjects,
    createProject: store.createProject,
    selectProject: store.selectProject,
    clearProjects: store.clearProjects,
  }
}
