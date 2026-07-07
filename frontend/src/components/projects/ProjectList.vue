<script setup lang="ts">
import { ArrowRightIcon } from '@lucide/vue'
import { RouterLink } from 'vue-router'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { Project } from '@/services/api'

const props = defineProps<{
  projects: readonly Project[]
  selectedProjectId: number | null
  loading: boolean
}>()

const emit = defineEmits<{
  selectProject: [projectId: number]
}>()
</script>

<template>
  <Card class="rounded-lg shadow-none">
    <CardHeader>
      <CardTitle class="text-base">Projects</CardTitle>
    </CardHeader>
    <CardContent>
      <p v-if="props.loading" class="text-muted-foreground text-sm">Loading projects...</p>

      <div v-else-if="props.projects.length > 0" class="grid gap-3">
        <article
          v-for="project in props.projects"
          :key="project.id"
          class="border-border grid gap-3 rounded-lg border p-4 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-center"
        >
          <div class="min-w-0">
            <div class="flex flex-wrap items-center gap-2">
              <h3 class="truncate font-medium">{{ project.name }}</h3>
              <Badge v-if="project.id === props.selectedProjectId" variant="secondary">
                Selected
              </Badge>
              <Badge v-if="project.group_name" variant="outline">
                {{ project.group_name }}
              </Badge>
            </div>
            <p v-if="project.description" class="text-muted-foreground mt-1 text-sm">
              {{ project.description }}
            </p>
          </div>

          <div class="flex flex-wrap gap-2">
            <Button
              size="sm"
              :variant="project.id === props.selectedProjectId ? 'secondary' : 'outline'"
              @click="emit('selectProject', project.id)"
            >
              Select
            </Button>
            <Button as-child size="sm" variant="ghost">
              <RouterLink :to="{ name: 'board' }" @click="emit('selectProject', project.id)">
                Open board
                <ArrowRightIcon />
              </RouterLink>
            </Button>
          </div>
        </article>
      </div>

      <p v-else class="text-muted-foreground text-sm">Create a project to start using Kanban.</p>
    </CardContent>
  </Card>
</template>
