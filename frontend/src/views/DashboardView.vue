<script setup lang="ts">
import {
  FolderKanbanIcon,
  FolderOpenIcon,
  KanbanIcon,
  MessageCircleIcon,
  SettingsIcon,
  UsersRoundIcon,
} from '@lucide/vue'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const { user } = storeToRefs(authStore)
const { t } = useI18n()
const canManageAdminSettings = computed(() => Boolean(user.value?.system_admin))
</script>

<template>
  <div class="grid gap-5">
    <div class="grid gap-1">
      <h2 class="text-2xl font-semibold">{{ t('navigation.dashboard') }}</h2>
      <p class="text-muted-foreground text-sm">{{ t('dashboard.chooseApp') }}</p>
    </div>

    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <RouterLink
        :to="{ name: 'projects' }"
        class="border-border bg-card text-card-foreground hover:border-primary/40 hover:bg-accent focus-visible:ring-ring grid min-h-36 gap-4 rounded-lg border p-5 transition outline-none focus-visible:ring-2"
        :aria-label="t('dashboard.openProjectManagement')"
      >
        <span
          class="bg-primary text-primary-foreground grid size-12 place-items-center rounded-md"
          aria-hidden="true"
        >
          <FolderKanbanIcon class="size-6" />
        </span>
        <span class="grid gap-1">
          <span class="text-lg font-semibold">{{ t('navigation.projects') }}</span>
          <span class="text-muted-foreground text-sm">{{
            t('dashboard.projectsDescription')
          }}</span>
        </span>
      </RouterLink>

      <RouterLink
        :to="{ name: 'board' }"
        class="border-border bg-card text-card-foreground hover:border-primary/40 hover:bg-accent focus-visible:ring-ring grid min-h-36 gap-4 rounded-lg border p-5 transition outline-none focus-visible:ring-2"
        :aria-label="t('dashboard.openKanban')"
      >
        <span
          class="bg-primary text-primary-foreground grid size-12 place-items-center rounded-md"
          aria-hidden="true"
        >
          <KanbanIcon class="size-6" />
        </span>
        <span class="grid gap-1">
          <span class="text-lg font-semibold">{{ t('navigation.kanban') }}</span>
          <span class="text-muted-foreground text-sm">{{ t('dashboard.kanbanDescription') }}</span>
        </span>
      </RouterLink>

      <RouterLink
        :to="{ name: 'drive' }"
        class="border-border bg-card text-card-foreground hover:border-primary/40 hover:bg-accent focus-visible:ring-ring grid min-h-36 gap-4 rounded-lg border p-5 transition outline-none focus-visible:ring-2"
        :aria-label="t('dashboard.openDrive')"
      >
        <span
          class="bg-primary text-primary-foreground grid size-12 place-items-center rounded-md"
          aria-hidden="true"
        >
          <FolderOpenIcon class="size-6" />
        </span>
        <span class="grid gap-1">
          <span class="text-lg font-semibold">{{ t('navigation.drive') }}</span>
          <span class="text-muted-foreground text-sm">{{ t('dashboard.driveDescription') }}</span>
        </span>
      </RouterLink>

      <RouterLink
        :to="{ name: 'chats' }"
        class="border-border bg-card text-card-foreground hover:border-primary/40 hover:bg-accent focus-visible:ring-ring grid min-h-36 gap-4 rounded-lg border p-5 transition outline-none focus-visible:ring-2"
        :aria-label="t('dashboard.openChats')"
      >
        <span
          class="bg-primary text-primary-foreground grid size-12 place-items-center rounded-md"
          aria-hidden="true"
        >
          <MessageCircleIcon class="size-6" />
        </span>
        <span class="grid gap-1">
          <span class="text-lg font-semibold">{{ t('navigation.chats') }}</span>
          <span class="text-muted-foreground text-sm">{{ t('dashboard.chatsDescription') }}</span>
        </span>
      </RouterLink>

      <RouterLink
        :to="{ name: 'users' }"
        class="border-border bg-card text-card-foreground hover:border-primary/40 hover:bg-accent focus-visible:ring-ring grid min-h-36 gap-4 rounded-lg border p-5 transition outline-none focus-visible:ring-2"
        :aria-label="t('dashboard.openUsersAndOrganizations')"
      >
        <span
          class="bg-primary text-primary-foreground grid size-12 place-items-center rounded-md"
          aria-hidden="true"
        >
          <UsersRoundIcon class="size-6" />
        </span>
        <span class="grid gap-1">
          <span class="text-lg font-semibold">{{ t('navigation.usersAndOrganizations') }}</span>
          <span class="text-muted-foreground text-sm">{{
            t('dashboard.usersAndOrganizationsDescription')
          }}</span>
        </span>
      </RouterLink>

      <RouterLink
        v-if="canManageAdminSettings"
        :to="{ name: 'admin-settings' }"
        class="border-border bg-card text-card-foreground hover:border-primary/40 hover:bg-accent focus-visible:ring-ring grid min-h-36 gap-4 rounded-lg border p-5 transition outline-none focus-visible:ring-2"
        :aria-label="t('dashboard.openAdminSettings')"
      >
        <span
          class="bg-primary text-primary-foreground grid size-12 place-items-center rounded-md"
          aria-hidden="true"
        >
          <SettingsIcon class="size-6" />
        </span>
        <span class="grid gap-1">
          <span class="text-lg font-semibold">{{ t('navigation.adminSettings') }}</span>
          <span class="text-muted-foreground text-sm">{{
            t('dashboard.adminSettingsDescription')
          }}</span>
        </span>
      </RouterLink>
    </div>
  </div>
</template>
