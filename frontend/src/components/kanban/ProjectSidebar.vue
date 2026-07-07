<script setup lang="ts">
import { CalendarRangeIcon, FolderKanbanIcon, KanbanIcon } from '@lucide/vue'
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Separator } from '@/components/ui/separator'
import type { Component } from 'vue'
import type { Project } from '@/services/api'

type BoardView = 'kanban' | 'iterations'

const props = defineProps<{
  projects: readonly Project[]
  selectedProjectId: number | null
  activeView: BoardView
  loading: boolean
}>()

const emit = defineEmits<{
  selectProject: [projectId: number]
  selectView: [view: BoardView]
}>()

const selectedProjectValue = computed({
  get: () => (props.selectedProjectId == null ? '' : String(props.selectedProjectId)),
  set: (projectId) => {
    const parsedProjectId = Number(projectId)
    if (Number.isInteger(parsedProjectId) && parsedProjectId > 0) {
      emit('selectProject', parsedProjectId)
    }
  },
})

const selectedProjectName = computed(
  () =>
    props.projects.find((project) => project.id === props.selectedProjectId)?.name ?? 'No project',
)

const views: Array<{ id: BoardView; label: string; icon: Component }> = [
  { id: 'kanban', label: 'Kanban', icon: KanbanIcon },
  { id: 'iterations', label: 'Iterations', icon: CalendarRangeIcon },
]
</script>

<template>
  <aside
    class="border-border bg-sidebar text-sidebar-foreground flex h-full w-full flex-col border-r p-4 lg:w-72"
  >
    <div class="grid gap-3">
      <div class="flex items-center justify-between gap-3">
        <div class="min-w-0">
          <p class="text-muted-foreground text-xs font-medium tracking-wider uppercase">
            Project
          </p>
          <h2 class="truncate text-xl leading-tight font-semibold">
            {{ selectedProjectName }}
          </h2>
        </div>
        <Button as-child size="icon" variant="outline" aria-label="Project management">
          <RouterLink :to="{ name: 'projects' }">
            <FolderKanbanIcon />
          </RouterLink>
        </Button>
      </div>

      <Select v-if="props.projects.length > 0" v-model="selectedProjectValue">
        <SelectTrigger class="w-full" aria-label="Project">
          <SelectValue placeholder="Select project" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem
            v-for="project in props.projects"
            :key="project.id"
            :value="String(project.id)"
          >
            {{ project.name }}
          </SelectItem>
        </SelectContent>
      </Select>

      <p v-else-if="!props.loading" class="text-muted-foreground text-sm">
        Create a project in Project management to start shaping the board.
      </p>
    </div>

    <Separator class="my-4" />

    <nav class="grid gap-1" aria-label="Board views">
      <Button
        v-for="view in views"
        :key="view.id"
        class="justify-start"
        :variant="props.activeView === view.id ? 'secondary' : 'ghost'"
        @click="emit('selectView', view.id)"
      >
        <component :is="view.icon" />
        {{ view.label }}
      </Button>
    </nav>

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

    <div v-if="props.projects.length > 0" class="mt-auto grid gap-3 pt-6">
      <Separator />
      <Button as-child variant="outline" class="justify-start">
        <RouterLink :to="{ name: 'projects' }">
          <FolderKanbanIcon />
          Project management
        </RouterLink>
      </Button>
    </div>
  </aside>
</template>
