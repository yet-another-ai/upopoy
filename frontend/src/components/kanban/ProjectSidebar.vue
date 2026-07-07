<script setup lang="ts">
import { FolderKanbanIcon, LayoutDashboardIcon, LogOutIcon } from '@lucide/vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import type { Project, User } from '@/services/api'

const props = defineProps<{
  projects: readonly Project[]
  selectedProjectId: number | null
  loading: boolean
  currentUser: User
}>()

const emit = defineEmits<{
  selectProject: [projectId: number]
  signOut: []
}>()
</script>

<template>
  <aside
    class="border-border bg-sidebar text-sidebar-foreground flex h-full w-full flex-col border-r p-4 lg:w-80"
  >
    <div class="flex items-center justify-between gap-3">
      <div>
        <p class="text-muted-foreground text-xs font-medium tracking-wider uppercase">upopoy</p>
        <h1 class="text-xl leading-tight font-semibold">Projects</h1>
      </div>
      <Button as-child size="icon" variant="outline" aria-label="Apps">
        <RouterLink :to="{ name: 'home' }">
          <LayoutDashboardIcon />
        </RouterLink>
      </Button>
    </div>

    <Separator class="my-4" />

    <div class="grid gap-2">
      <Button
        v-for="project in props.projects"
        :key="project.id"
        class="h-auto justify-start px-3 py-2 text-left"
        :variant="project.id === props.selectedProjectId ? 'secondary' : 'ghost'"
        @click="emit('selectProject', project.id)"
      >
        <span class="min-w-0">
          <span class="block truncate font-medium">{{ project.name }}</span>
          <span v-if="project.description" class="text-muted-foreground block truncate text-xs">
            {{ project.description }}
          </span>
        </span>
      </Button>
    </div>

    <p
      v-if="!props.loading && props.projects.length === 0"
      class="text-muted-foreground mt-6 text-sm"
    >
      Create a project in Project management to start shaping the board.
    </p>
    <Button
      v-if="!props.loading && props.projects.length === 0"
      as-child
      variant="outline"
      class="mt-3 justify-start"
    >
      <RouterLink :to="{ name: 'projects' }">
        <FolderKanbanIcon />
        Project management
      </RouterLink>
    </Button>

    <div class="mt-auto grid gap-3 pt-6">
      <Separator />
      <div class="flex items-center justify-between gap-3">
        <div class="min-w-0">
          <p class="text-muted-foreground text-xs">Signed in as</p>
          <p class="truncate text-sm font-medium">{{ props.currentUser.email }}</p>
        </div>
        <Button size="icon" variant="ghost" aria-label="Sign out" @click="emit('signOut')">
          <LogOutIcon />
        </Button>
      </div>
    </div>
  </aside>
</template>
