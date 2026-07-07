<script setup lang="ts">
import { FolderKanbanIcon, KanbanIcon, LogOutIcon } from '@lucide/vue'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import type { User } from '@/services/api'

defineProps<{
  currentUser: User
}>()

const emit = defineEmits<{
  signOut: []
}>()
</script>

<template>
  <main class="bg-background text-foreground min-h-svh">
    <header class="border-border flex items-center justify-between gap-4 border-b px-5 py-4">
      <div class="min-w-0">
        <p class="text-muted-foreground text-xs font-medium tracking-wider uppercase">upopoy</p>
        <h1 class="text-xl leading-tight font-semibold">Apps</h1>
      </div>

      <div class="flex min-w-0 items-center gap-3">
        <p class="text-muted-foreground hidden truncate text-sm sm:block">
          {{ currentUser.email }}
        </p>
        <Button size="icon" variant="ghost" aria-label="Sign out" @click="emit('signOut')">
          <LogOutIcon />
        </Button>
      </div>
    </header>

    <section class="mx-auto grid w-full max-w-5xl gap-5 px-5 py-6">
      <div class="grid gap-1">
        <h2 class="text-2xl font-semibold">Dashboard</h2>
        <p class="text-muted-foreground text-sm">Choose an app to continue.</p>
      </div>

      <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <RouterLink
          :to="{ name: 'projects' }"
          class="border-border bg-card text-card-foreground hover:border-primary/40 hover:bg-accent focus-visible:ring-ring grid min-h-36 gap-4 rounded-lg border p-5 transition outline-none focus-visible:ring-2"
          aria-label="Open Project management"
        >
          <span
            class="bg-primary text-primary-foreground grid size-12 place-items-center rounded-md"
            aria-hidden="true"
          >
            <FolderKanbanIcon class="size-6" />
          </span>
          <span class="grid gap-1">
            <span class="text-lg font-semibold">Projects</span>
            <span class="text-muted-foreground text-sm">Create and select workspaces.</span>
          </span>
        </RouterLink>

        <RouterLink
          :to="{ name: 'board' }"
          class="border-border bg-card text-card-foreground hover:border-primary/40 hover:bg-accent focus-visible:ring-ring grid min-h-36 gap-4 rounded-lg border p-5 transition outline-none focus-visible:ring-2"
          aria-label="Open Kanban"
        >
          <span
            class="bg-primary text-primary-foreground grid size-12 place-items-center rounded-md"
            aria-hidden="true"
          >
            <KanbanIcon class="size-6" />
          </span>
          <span class="grid gap-1">
            <span class="text-lg font-semibold">Kanban</span>
            <span class="text-muted-foreground text-sm">Projects, tasks, and fixed workflow.</span>
          </span>
        </RouterLink>
      </div>
    </section>
  </main>
</template>
