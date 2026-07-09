<script setup lang="ts">
import ChatMessageItem from './ChatMessageItem.vue'
import type { ChatMessage } from '@/services/api'

const props = defineProps<{
  messages: readonly ChatMessage[]
}>()

const emit = defineEmits<{
  openThread: [message: ChatMessage]
}>()
</script>

<template>
  <div class="grid content-start gap-1 p-3">
    <p v-if="props.messages.length === 0" class="text-muted-foreground p-4 text-center text-sm">
      No messages yet.
    </p>
    <ChatMessageItem
      v-for="message in props.messages"
      :key="message.id"
      :message="message"
      @open-thread="emit('openThread', $event)"
    />
  </div>
</template>
