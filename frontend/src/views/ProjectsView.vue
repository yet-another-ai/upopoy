<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { onMounted } from 'vue'
import ProjectForm from '@/components/projects/ProjectForm.vue'
import ProjectList from '@/components/projects/ProjectList.vue'
import { useProjectsStore } from '@/stores/projects'
import { useToastsStore } from '@/stores/toasts'
import { useAuthStore } from '@/stores/auth'
import { useOrganizationsStore } from '@/stores/organizations'
import type { ProjectInput } from '@/services/api'

const projectsStore = useProjectsStore()
const organizationsStore = useOrganizationsStore()
const authStore = useAuthStore()
const toasts = useToastsStore()
const projects = storeToRefs(projectsStore)
const organizations = storeToRefs(organizationsStore)
const auth = storeToRefs(authStore)

onMounted(async () => {
  if (projects.projects.value.length === 0) await projectsStore.loadProjects()
  if (organizations.organizations.value.length === 0) await organizationsStore.loadOrganizations()
})

async function createProject(input: ProjectInput) {
  try {
    await projectsStore.createProject(input)
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unable to create project'
    toasts.error('Unable to create project', message)
  }
}
</script>

<template>
  <div class="grid gap-5 lg:grid-cols-[22rem_minmax(0,1fr)]">
    <ProjectForm
      :organizations="organizations.organizations.value"
      :current-user="auth.user.value"
      :loading-organizations="organizations.loadingOrganizations.value"
      @create-project="createProject"
    />
    <ProjectList
      :projects="projects.projects.value"
      :selected-project-id="projects.selectedProjectId.value"
      :loading="projects.loading.value"
      @select-project="projectsStore.selectProject"
    />
  </div>
</template>
