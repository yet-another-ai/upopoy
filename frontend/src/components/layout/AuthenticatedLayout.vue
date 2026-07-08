<script setup lang="ts">
import { LogOutIcon, PencilIcon, UserCircleIcon } from '@lucide/vue'
import { useI18n } from 'vue-i18n'
import { RouterLink } from 'vue-router'
import { Button } from '@/components/ui/button'
import type { User } from '@/services/api'

const props = withDefaults(
  defineProps<{
    currentUser: User
    title: string
    contentClass?: string
  }>(),
  {
    contentClass: 'mx-auto w-full max-w-5xl px-5 py-6',
  },
)

const emit = defineEmits<{
  signOut: []
}>()

const { t } = useI18n()
</script>

<template>
  <main class="bg-background text-foreground flex min-h-svh flex-col">
    <header class="border-border border-b">
      <div class="mx-auto flex h-14 w-full max-w-7xl items-center gap-4 px-5">
        <RouterLink
          :to="{ name: 'home' }"
          class="focus-visible:ring-ring rounded-md text-base font-semibold outline-none focus-visible:ring-2"
          :aria-label="t('layout.openApps')"
        >
          Upopoy
        </RouterLink>

        <div class="border-border h-5 border-l" aria-hidden="true" />

        <p class="min-w-0 truncate text-sm font-medium">
          {{ props.title }}
        </p>

        <div class="ml-auto flex min-w-0 items-center gap-2">
          <slot name="header-actions" />

          <div class="group relative shrink-0">
            <Button
              size="icon"
              variant="ghost"
              :aria-label="t('layout.userMenu')"
              aria-haspopup="menu"
            >
              <UserCircleIcon />
            </Button>

            <div
              role="menu"
              class="invisible absolute top-full right-0 z-50 w-56 pt-2 opacity-0 transition duration-100 group-focus-within:visible group-focus-within:opacity-100 group-hover:visible group-hover:opacity-100"
            >
              <div
                class="bg-popover text-popover-foreground ring-foreground/10 grid gap-1 rounded-lg p-1 shadow-md ring-1"
              >
                <p class="text-muted-foreground truncate px-1.5 py-1 text-xs font-medium">
                  {{ props.currentUser.email }}
                </p>
                <div class="bg-border -mx-1 h-px" />
                <RouterLink
                  role="menuitem"
                  :to="{ name: 'user-edit', params: { userId: props.currentUser.id } }"
                  class="hover:bg-accent focus:bg-accent flex items-center gap-1.5 rounded-md px-1.5 py-1 text-left text-sm outline-none"
                >
                  <PencilIcon class="size-4" />
                  {{ t('layout.editProfile') }}
                </RouterLink>
                <button
                  type="button"
                  role="menuitem"
                  class="text-destructive hover:bg-destructive/10 focus:bg-destructive/10 flex items-center gap-1.5 rounded-md px-1.5 py-1 text-left text-sm outline-none"
                  @click="emit('signOut')"
                >
                  <LogOutIcon class="size-4" />
                  {{ t('common.signOut') }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>

    <section class="min-h-0 flex-1" :class="props.contentClass">
      <slot />
    </section>

    <footer class="border-border border-t">
      <div
        class="text-muted-foreground mx-auto flex w-full max-w-7xl flex-col gap-1 px-5 py-4 text-xs sm:flex-row sm:items-center sm:justify-between"
      >
        <span>{{ t('layout.workspace') }}</span>
        <span class="truncate">{{
          t('layout.signedInAs', { email: props.currentUser.email })
        }}</span>
      </div>
    </footer>
  </main>
</template>
