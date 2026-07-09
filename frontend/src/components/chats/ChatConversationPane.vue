<script setup lang="ts">
import { RefreshCwIcon } from '@lucide/vue'
import { Button } from '@/components/ui/button'
import ChatComposer from './ChatComposer.vue'
import ChatMessageList from './ChatMessageList.vue'
import type { ChatConversation, ChatMessage } from '@/services/api'

const props = defineProps<{
  conversation: ChatConversation | null
  messages: readonly ChatMessage[]
  loading: boolean
  saving: boolean
}>()

const emit = defineEmits<{
  refresh: []
  send: [body: string]
  openThread: [message: ChatMessage]
}>()
</script>

<template>
  <section class="flex min-h-0 flex-1 flex-col">
    <header class="border-border flex min-h-14 items-center gap-3 border-b px-4">
      <div class="min-w-0">
        <h1 class="truncate text-base font-semibold">
          {{ props.conversation?.title ?? 'Chats' }}
        </h1>
        <p v-if="props.conversation" class="text-muted-foreground truncate text-xs">
          <template v-if="props.conversation.kind === 'direct'">Direct message</template>
          <template v-else-if="props.conversation.kind === 'channel'">
            {{ props.conversation.group_name }}
          </template>
          <template v-else>Thread</template>
        </p>
      </div>
      <Button
        type="button"
        size="icon-sm"
        variant="ghost"
        class="ml-auto"
        aria-label="Refresh messages"
        :disabled="!props.conversation || props.loading"
        @click="emit('refresh')"
      >
        <RefreshCwIcon />
      </Button>
    </header>

    <div class="min-h-0 flex-1 overflow-auto">
      <p v-if="props.loading" class="text-muted-foreground p-5 text-sm">Loading chat...</p>
      <p v-else-if="!props.conversation" class="text-muted-foreground p-5 text-sm">
        Choose a direct message or channel.
      </p>
      <ChatMessageList
        v-else
        :messages="props.messages"
        @open-thread="emit('openThread', $event)"
      />
    </div>

    <ChatComposer
      v-if="props.conversation"
      :saving="props.saving"
      editor-label="Chat message"
      @send="emit('send', $event)"
    />
  </section>
</template>
