<script setup lang="ts">
import { ArrowLeftIcon, LogOutIcon } from '@lucide/vue'
import { RouterLink } from 'vue-router'
import ProjectForm from '@/components/projects/ProjectForm.vue'
import ProjectList from '@/components/projects/ProjectList.vue'
import { Button } from '@/components/ui/button'
import type { Project, ProjectInput, User } from '@/services/api'

const props = defineProps<{
  projects: readonly Project[]
  selectedProjectId: number | null
  loading: boolean
  currentUser: User
}>()

const emit = defineEmits<{
  createProject: [input: ProjectInput]
  selectProject: [projectId: number]
  signOut: []
}>()
</script>

<template>
  <main class="bg-background text-foreground min-h-svh">
    <header class="border-border flex items-center justify-between gap-4 border-b px-5 py-4">
      <div class="min-w-0">
        <Button as-child variant="ghost" size="sm" class="mb-2 -ml-2">
          <RouterLink :to="{ name: 'home' }">
            <ArrowLeftIcon />
            Apps
          </RouterLink>
        </Button>
        <p class="text-muted-foreground text-xs font-medium tracking-wider uppercase">upopoy</p>
        <h1 class="text-xl leading-tight font-semibold">Project management</h1>
      </div>

      <div class="flex min-w-0 items-center gap-3">
        <p class="text-muted-foreground hidden truncate text-sm sm:block">
          {{ props.currentUser.email }}
        </p>
        <Button size="icon" variant="ghost" aria-label="Sign out" @click="emit('signOut')">
          <LogOutIcon />
        </Button>
      </div>
    </header>

    <section
      class="mx-auto grid w-full max-w-5xl gap-5 px-5 py-6 lg:grid-cols-[22rem_minmax(0,1fr)]"
    >
      <ProjectForm @create-project="emit('createProject', $event)" />
      <ProjectList
        :projects="props.projects"
        :selected-project-id="props.selectedProjectId"
        :loading="props.loading"
        @select-project="emit('selectProject', $event)"
      />
    </section>
  </main>
</template>
