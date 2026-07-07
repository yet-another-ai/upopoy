<script setup lang="ts">
import { FolderKanbanIcon, KanbanIcon, UsersRoundIcon } from '@lucide/vue'
import { RouterLink } from 'vue-router'
</script>

<template>
  <div class="grid gap-5">
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

      <RouterLink
        :to="{ name: 'users' }"
        class="border-border bg-card text-card-foreground hover:border-primary/40 hover:bg-accent focus-visible:ring-ring grid min-h-36 gap-4 rounded-lg border p-5 transition outline-none focus-visible:ring-2"
        aria-label="Open User and Groups"
      >
        <span
          class="bg-primary text-primary-foreground grid size-12 place-items-center rounded-md"
          aria-hidden="true"
        >
          <UsersRoundIcon class="size-6" />
        </span>
        <span class="grid gap-1">
          <span class="text-lg font-semibold">Users & Groups</span>
          <span class="text-muted-foreground text-sm">Manage groups and memberships.</span>
        </span>
      </RouterLink>
    </div>
  </div>
</template>
