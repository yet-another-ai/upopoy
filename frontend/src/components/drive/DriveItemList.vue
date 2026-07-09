<script setup lang="ts">
import {
  DownloadIcon,
  FileIcon,
  FileTextIcon,
  FolderIcon,
  FolderPlusIcon,
  MoveRightIcon,
  PencilIcon,
  RefreshCcwIcon,
  Trash2Icon,
  UploadIcon,
} from '@lucide/vue'
import { computed, onMounted, onUnmounted, shallowRef, type CSSProperties } from 'vue'
import type { DriveItem } from '@/services/api'

const props = defineProps<{
  items: readonly DriveItem[]
  loading: boolean
  selectedItemId: number | null
}>()

const emit = defineEmits<{
  createFolder: []
  createMarkdown: []
  upload: []
  refresh: []
  open: [item: DriveItem]
  select: [item: DriveItem]
  edit: [item: DriveItem]
  rename: [item: DriveItem]
  move: [item: DriveItem]
  delete: [item: DriveItem]
  download: [item: DriveItem]
}>()

const contextMenu = shallowRef<{ x: number; y: number; item: DriveItem | null } | null>(null)

const contextMenuStyle = computed<CSSProperties>(() => {
  if (!contextMenu.value) return {}

  const menuWidth = 208
  const menuHeight = contextMenu.value.item ? 244 : 180
  return {
    left: `${Math.min(contextMenu.value.x, window.innerWidth - menuWidth - 12)}px`,
    top: `${Math.min(contextMenu.value.y, window.innerHeight - menuHeight - 12)}px`,
  }
})

function iconFor(item: DriveItem) {
  if (item.kind === 'folder') return FolderIcon
  if (item.markdown) return FileTextIcon
  return FileIcon
}

function openItem(item: DriveItem) {
  if (item.kind === 'folder') {
    emit('open', item)
    return
  }

  if (item.markdown) {
    emit('edit', item)
    return
  }

  emit('download', item)
}

function openItemMenu(event: MouseEvent, item: DriveItem) {
  emit('select', item)
  contextMenu.value = { x: event.clientX, y: event.clientY, item }
}

function openFolderMenu(event: MouseEvent) {
  contextMenu.value = { x: event.clientX, y: event.clientY, item: null }
}

function runMenuAction(action: () => void) {
  contextMenu.value = null
  action()
}

function runItemMenuAction(action: (item: DriveItem) => void) {
  const item = contextMenu.value?.item
  contextMenu.value = null
  if (item) action(item)
}

function formatBytes(bytes: number | null) {
  if (bytes == null) return '—'
  if (bytes < 1024) return `${bytes} B`

  const units = ['KB', 'MB', 'GB']
  let value = bytes / 1024
  let unitIndex = 0
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024
    unitIndex += 1
  }

  return `${value.toFixed(value >= 10 ? 0 : 1)} ${units[unitIndex]}`
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function closeMenu() {
  contextMenu.value = null
}

function closeMenuWithEscape(event: KeyboardEvent) {
  if (event.key === 'Escape') closeMenu()
}

onMounted(() => {
  document.addEventListener('click', closeMenu)
  document.addEventListener('keydown', closeMenuWithEscape)
})

onUnmounted(() => {
  document.removeEventListener('click', closeMenu)
  document.removeEventListener('keydown', closeMenuWithEscape)
})
</script>

<template>
  <div
    class="border-border relative min-h-0 overflow-hidden rounded-lg border"
    aria-label="Drive file list"
    @contextmenu.prevent="openFolderMenu"
  >
    <div class="bg-muted/50 text-muted-foreground grid grid-cols-[minmax(0,1fr)_12rem_7rem] gap-3 px-4 py-2 text-xs font-medium uppercase">
      <span>Name</span>
      <span>Modified</span>
      <span class="text-right">Size</span>
    </div>

    <div v-if="props.loading" class="text-muted-foreground px-4 py-8 text-center text-sm">
      Loading...
    </div>

    <div v-else-if="props.items.length === 0" class="text-muted-foreground px-4 py-8 text-center text-sm">
      Empty folder
    </div>

    <div v-else class="divide-border h-full min-h-[24rem] divide-y overflow-auto">
      <div
        v-for="item in props.items"
        :key="item.id"
        class="grid grid-cols-[minmax(0,1fr)_12rem_7rem] items-center gap-3 px-4 py-2"
        :class="{ 'bg-accent/70': props.selectedItemId === item.id }"
        @contextmenu.stop.prevent="openItemMenu($event, item)"
      >
        <button
          type="button"
          class="hover:text-primary flex min-w-0 items-center gap-2 text-left text-sm font-medium"
          @click="emit('select', item)"
          @dblclick="openItem(item)"
        >
          <component :is="iconFor(item)" class="size-4 shrink-0" />
          <span class="truncate">{{ item.name }}</span>
        </button>

        <span class="text-muted-foreground truncate text-sm">{{ formatDate(item.updated_at) }}</span>
        <span class="text-muted-foreground text-right text-sm">{{ item.kind === 'file' ? formatBytes(item.byte_size) : '—' }}</span>
      </div>
    </div>

    <div
      v-if="contextMenu"
      class="bg-popover text-popover-foreground border-border fixed z-50 grid w-52 gap-1 rounded-md border p-1 text-sm shadow-md"
      role="menu"
      :style="contextMenuStyle"
      @click.stop
    >
      <template v-if="contextMenu.item">
        <button
          v-if="contextMenu.item.kind === 'folder'"
          type="button"
          class="hover:bg-accent flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
          role="menuitem"
          @click="runItemMenuAction((item) => emit('open', item))"
        >
          <FolderIcon class="size-4" />
          Open
        </button>
        <button
          v-if="contextMenu.item.markdown"
          type="button"
          class="hover:bg-accent flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
          role="menuitem"
          @click="runItemMenuAction((item) => emit('edit', item))"
        >
          <FileTextIcon class="size-4" />
          Edit
        </button>
        <button
          v-if="contextMenu.item.kind === 'file'"
          type="button"
          class="hover:bg-accent flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
          role="menuitem"
          @click="runItemMenuAction((item) => emit('download', item))"
        >
          <DownloadIcon class="size-4" />
          Download
        </button>
        <div class="bg-border my-1 h-px" />
        <button
          type="button"
          class="hover:bg-accent flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
          role="menuitem"
          @click="runItemMenuAction((item) => emit('rename', item))"
        >
          <PencilIcon class="size-4" />
          Rename
        </button>
        <button
          type="button"
          class="hover:bg-accent flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
          role="menuitem"
          @click="runItemMenuAction((item) => emit('move', item))"
        >
          <MoveRightIcon class="size-4" />
          Move
        </button>
        <button
          type="button"
          class="text-destructive hover:bg-destructive/10 flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
          role="menuitem"
          @click="runItemMenuAction((item) => emit('delete', item))"
        >
          <Trash2Icon class="size-4" />
          Delete
        </button>
      </template>

      <template v-else>
        <button
          type="button"
          class="hover:bg-accent flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
          role="menuitem"
          @click="runMenuAction(() => emit('createFolder'))"
        >
          <FolderPlusIcon class="size-4" />
          New folder
        </button>
        <button
          type="button"
          class="hover:bg-accent flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
          role="menuitem"
          @click="runMenuAction(() => emit('createMarkdown'))"
        >
          <FileTextIcon class="size-4" />
          New Markdown document
        </button>
        <div class="bg-border my-1 h-px" />
        <button
          type="button"
          class="hover:bg-accent flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
          role="menuitem"
          @click="runMenuAction(() => emit('upload'))"
        >
          <UploadIcon class="size-4" />
          Upload file
        </button>
        <button
          type="button"
          class="hover:bg-accent flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
          role="menuitem"
          @click="runMenuAction(() => emit('refresh'))"
        >
          <RefreshCcwIcon class="size-4" />
          Refresh
        </button>
      </template>
    </div>
  </div>
</template>
