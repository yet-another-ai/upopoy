<script setup lang="ts">
import ProjectForm from '@/components/projects/ProjectForm.vue'
import ProjectList from '@/components/projects/ProjectList.vue'
import type { Project, ProjectInput } from '@/services/api'

const props = defineProps<{
  projects: readonly Project[]
  selectedProjectId: number | null
  loading: boolean
}>()

const emit = defineEmits<{
  createProject: [input: ProjectInput]
  selectProject: [projectId: number]
}>()
</script>

<template>
  <div class="grid gap-5 lg:grid-cols-[22rem_minmax(0,1fr)]">
    <ProjectForm @create-project="emit('createProject', $event)" />
    <ProjectList
      :projects="props.projects"
      :selected-project-id="props.selectedProjectId"
      :loading="props.loading"
      @select-project="emit('selectProject', $event)"
    />
  </div>
</template>
