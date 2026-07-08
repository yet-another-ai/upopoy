<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { onMounted } from 'vue'
import ProjectForm from '@/components/projects/ProjectForm.vue'
import ProjectList from '@/components/projects/ProjectList.vue'
import { useProjectsStore } from '@/stores/projects'
import { useToastsStore } from '@/stores/toasts'
import { useUserGroupsStore } from '@/stores/userGroups'
import type { ProjectInput } from '@/services/api'

const projectsStore = useProjectsStore()
const userGroupsStore = useUserGroupsStore()
const toasts = useToastsStore()
const projects = storeToRefs(projectsStore)
const userGroups = storeToRefs(userGroupsStore)

onMounted(async () => {
  if (projects.projects.value.length === 0) await projectsStore.loadProjects()
  if (userGroups.groups.value.length === 0) await userGroupsStore.loadGroups()
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
      :groups="userGroups.groups.value"
      :loading-groups="userGroups.loadingGroups.value"
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
