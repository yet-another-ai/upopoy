<script setup lang="ts">
import { ChevronRightIcon, HomeIcon } from '@lucide/vue'
import { Button } from '@/components/ui/button'
import type { DriveItem } from '@/services/api'

const props = defineProps<{
  breadcrumbs: readonly DriveItem[]
}>()

const emit = defineEmits<{
  navigate: [index: number]
}>()
</script>

<template>
  <nav class="flex min-w-0 items-center gap-1" aria-label="Drive folders">
    <Button size="sm" variant="ghost" class="shrink-0" @click="emit('navigate', -1)">
      <HomeIcon />
      Drive
    </Button>

    <template v-for="(folder, index) in props.breadcrumbs" :key="folder.id">
      <ChevronRightIcon class="text-muted-foreground size-4 shrink-0" />
      <Button size="sm" variant="ghost" class="min-w-0" @click="emit('navigate', index)">
        <span class="truncate">{{ folder.name }}</span>
      </Button>
    </template>
  </nav>
</template>
