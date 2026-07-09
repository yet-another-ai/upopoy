<script setup lang="ts">
import { XIcon } from '@lucide/vue'
import { Button } from '@/components/ui/button'
import MarkdownPreview from '@/components/markdown/MarkdownPreview.vue'
import ChatComposer from './ChatComposer.vue'
import ChatMessageList from './ChatMessageList.vue'
import type { ChatConversation, ChatMessage } from '@/services/api'

const props = defineProps<{
  conversation: ChatConversation | null
  messages: readonly ChatMessage[]
  saving: boolean
}>()

const emit = defineEmits<{
  close: []
  send: [body: string]
}>()
</script>

<template>
  <aside
    v-if="props.conversation"
    class="border-border bg-background flex min-h-0 w-full flex-col border-l lg:w-[24rem]"
  >
    <header class="border-border flex min-h-14 items-center gap-3 border-b px-4">
      <div class="min-w-0">
        <h2 class="truncate text-sm font-semibold">Thread</h2>
        <p class="text-muted-foreground truncate text-xs">{{ props.conversation.title }}</p>
      </div>
      <Button
        type="button"
        size="icon-sm"
        variant="ghost"
        class="ml-auto"
        aria-label="Close thread"
        @click="emit('close')"
      >
        <XIcon />
      </Button>
    </header>

    <div class="min-h-0 flex-1 overflow-auto">
      <article v-if="props.conversation.parent_message" class="border-border border-b p-4">
        <p class="text-muted-foreground mb-2 text-xs font-medium uppercase">Parent message</p>
        <MarkdownPreview :source="props.conversation.parent_message.body" />
      </article>
      <ChatMessageList :messages="props.messages" @open-thread="() => undefined" />
    </div>

    <ChatComposer
      :saving="props.saving"
      editor-label="Thread reply"
      placeholder="Reply in Markdown"
      @send="emit('send', $event)"
    />
  </aside>
</template>
