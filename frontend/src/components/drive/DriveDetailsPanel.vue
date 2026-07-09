<script setup lang="ts">
import {
  DownloadIcon,
  FileIcon,
  FileTextIcon,
  FolderIcon,
  HistoryIcon,
  XIcon,
} from '@lucide/vue'
import { computed } from 'vue'
import { Button } from '@/components/ui/button'
import type { DriveItem, DriveItemVersion } from '@/services/api'

const props = defineProps<{
  item: DriveItem | null
  versions: readonly DriveItemVersion[]
}>()

const emit = defineEmits<{
  close: []
  edit: [item: DriveItem]
  download: [item: DriveItem]
}>()

const icon = computed(() => {
  if (props.item?.kind === 'folder') return FolderIcon
  if (props.item?.markdown) return FileTextIcon
  return FileIcon
})

const itemType = computed(() => {
  if (!props.item) return ''
  if (props.item.kind === 'folder') return 'Folder'
  if (props.item.markdown) return 'Markdown document'
  return 'File'
})

function formatBytes(bytes: number | null) {
  if (bytes == null) return '—'
  if (bytes < 1024) return `${bytes} B`

  const units = ['KB', 'MB', 'GB', 'TB']
  let value = bytes / 1024
  let unitIndex = 0
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024
    unitIndex += 1
  }

  return `${value.toFixed(value >= 10 ? 0 : 1)} ${units[unitIndex]}`
}

function formatDate(value: string | null) {
  if (!value) return '—'

  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}
</script>

<template>
  <aside class="border-border bg-card grid min-h-0 content-start gap-4 rounded-lg border p-4">
    <div v-if="!props.item" class="text-muted-foreground grid min-h-[18rem] place-items-center text-center text-sm">
      Select a file or folder to view details.
    </div>

    <template v-else>
      <div class="flex min-w-0 items-start gap-3">
        <div class="bg-muted grid size-10 shrink-0 place-items-center rounded-md">
          <component :is="icon" class="size-5" />
        </div>
        <div class="min-w-0">
          <h3 class="truncate text-base font-semibold">{{ props.item.name }}</h3>
          <p class="text-muted-foreground text-sm">{{ itemType }}</p>
        </div>
        <Button class="ml-auto" size="icon-sm" variant="ghost" aria-label="Close details" @click="emit('close')">
          <XIcon />
        </Button>
      </div>

      <div v-if="props.item.kind === 'file'" class="flex flex-wrap gap-2">
        <Button v-if="props.item.markdown" size="sm" @click="emit('edit', props.item)">
          <FileTextIcon class="size-4" />
          Edit
        </Button>
        <Button v-if="props.item.kind === 'file'" size="sm" variant="outline" @click="emit('download', props.item)">
          <DownloadIcon class="size-4" />
          Download
        </Button>
      </div>

      <dl class="grid gap-3 text-sm">
        <div class="grid gap-1">
          <dt class="text-muted-foreground text-xs font-medium uppercase">Created</dt>
          <dd>{{ formatDate(props.item.created_at) }}</dd>
        </div>
        <div class="grid gap-1">
          <dt class="text-muted-foreground text-xs font-medium uppercase">Updated</dt>
          <dd>{{ formatDate(props.item.updated_at) }}</dd>
        </div>
        <div class="grid gap-1">
          <dt class="text-muted-foreground text-xs font-medium uppercase">Versions</dt>
          <dd>
            {{ props.item.versions_count }}
            <span v-if="props.item.latest_version_number"> · latest v{{ props.item.latest_version_number }}</span>
          </dd>
        </div>
        <div v-if="props.item.kind === 'file'" class="grid gap-1">
          <dt class="text-muted-foreground text-xs font-medium uppercase">Size</dt>
          <dd>{{ formatBytes(props.item.byte_size) }}</dd>
        </div>
        <div v-if="props.item.kind === 'file'" class="grid gap-1">
          <dt class="text-muted-foreground text-xs font-medium uppercase">Content type</dt>
          <dd>{{ props.item.content_type ?? '—' }}</dd>
        </div>
      </dl>

      <div v-if="props.item.kind === 'file'" class="border-border grid gap-2 rounded-lg border p-3">
        <div class="text-muted-foreground flex items-center gap-1.5 text-xs font-medium uppercase">
          <HistoryIcon class="size-3.5" />
          Version history
        </div>
        <p v-if="props.versions.length === 0" class="text-muted-foreground text-sm">
          No versions yet.
        </p>
        <div
          v-for="version in props.versions"
          :key="version.id"
          class="grid gap-0.5 rounded-md px-2 py-1.5 text-sm"
        >
          <span class="font-medium">v{{ version.version_number }}</span>
          <span class="text-muted-foreground truncate text-xs">{{ formatDate(version.created_at) }}</span>
        </div>
      </div>
    </template>
  </aside>
</template>
