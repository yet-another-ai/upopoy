<script setup lang="ts">
import ProjectForm from '@/components/projects/ProjectForm.vue'
import ProjectList from '@/components/projects/ProjectList.vue'
import type { Group, Project, ProjectInput } from '@/services/api'

const props = defineProps<{
  projects: readonly Project[]
  groups: readonly Group[]
  selectedProjectId: number | null
  loading: boolean
  loadingGroups: boolean
}>()

const emit = defineEmits<{
  createProject: [input: ProjectInput]
  selectProject: [projectId: number]
}>()
</script>

<template>
  <div class="grid gap-5 lg:grid-cols-[22rem_minmax(0,1fr)]">
    <ProjectForm
      :groups="props.groups"
      :loading-groups="props.loadingGroups"
      @create-project="emit('createProject', $event)"
    />
    <ProjectList
      :projects="props.projects"
      :selected-project-id="props.selectedProjectId"
      :loading="props.loading"
      @select-project="emit('selectProject', $event)"
    />
  </div>
</template>
