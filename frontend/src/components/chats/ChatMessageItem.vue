<script setup lang="ts">
import { MessageSquareTextIcon } from '@lucide/vue'
import { computed, onMounted, onUnmounted, shallowRef, type CSSProperties } from 'vue'
import MarkdownPreview from '@/components/markdown/MarkdownPreview.vue'
import type { ChatMessage } from '@/services/api'

const props = defineProps<{
  message: ChatMessage
}>()

const emit = defineEmits<{
  openThread: [message: ChatMessage]
}>()

const contextMenu = shallowRef<{ x: number; y: number } | null>(null)

const contextMenuStyle = computed<CSSProperties>(() => {
  if (!contextMenu.value) return {}

  const menuWidth = 184
  const menuHeight = 44
  return {
    left: `${Math.min(contextMenu.value.x, window.innerWidth - menuWidth - 12)}px`,
    top: `${Math.min(contextMenu.value.y, window.innerHeight - menuHeight - 12)}px`,
  }
})

function authorName(message: ChatMessage) {
  return message.author.display_name || message.author.email
}

function formatTime(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value))
}

function openContextMenu(event: MouseEvent) {
  contextMenu.value = { x: event.clientX, y: event.clientY }
}

function closeContextMenu() {
  contextMenu.value = null
}

function closeContextMenuWithEscape(event: KeyboardEvent) {
  if (event.key === 'Escape') closeContextMenu()
}

function openThread() {
  contextMenu.value = null
  emit('openThread', props.message)
}

onMounted(() => {
  document.addEventListener('click', closeContextMenu)
  document.addEventListener('keydown', closeContextMenuWithEscape)
})

onUnmounted(() => {
  document.removeEventListener('click', closeContextMenu)
  document.removeEventListener('keydown', closeContextMenuWithEscape)
})
</script>

<template>
  <article
    class="group grid gap-2 rounded-md px-3 py-2 hover:bg-accent/60"
    @contextmenu.prevent="openContextMenu"
  >
    <header class="flex min-w-0 flex-wrap items-center gap-2">
      <span class="truncate text-sm font-semibold">{{ authorName(props.message) }}</span>
      <time class="text-muted-foreground text-xs" :datetime="props.message.created_at">
        {{ formatTime(props.message.created_at) }}
      </time>
    </header>

    <MarkdownPreview :source="props.message.body" empty-text="Empty message" />

    <div
      v-if="props.message.thread_reply_count > 0 || props.message.thread_last_message_at"
      class="text-muted-foreground flex items-center gap-2 text-xs"
    >
      <button
        v-if="props.message.thread_reply_count > 0"
        type="button"
        class="hover:text-foreground inline-flex items-center gap-1 rounded-sm outline-none focus-visible:ring-2 focus-visible:ring-ring"
        @click="openThread"
      >
        <MessageSquareTextIcon class="size-3.5" />
        {{ props.message.thread_reply_count }} replies
      </button>
      <span v-if="props.message.thread_last_message_at">
        Latest {{ formatTime(props.message.thread_last_message_at) }}
      </span>
    </div>

    <div
      v-if="contextMenu"
      class="bg-popover text-popover-foreground border-border fixed z-50 grid w-44 gap-1 rounded-md border p-1 text-sm shadow-md"
      role="menu"
      :style="contextMenuStyle"
      @click.stop
    >
      <button
        type="button"
        class="hover:bg-accent flex items-center gap-2 rounded-sm px-2 py-1.5 text-left"
        role="menuitem"
        @click="openThread"
      >
        <MessageSquareTextIcon class="size-4" />
        <template v-if="props.message.thread_reply_count > 0">Open thread</template>
        <template v-else>Start thread</template>
      </button>
    </div>
  </article>
</template>
