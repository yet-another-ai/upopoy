<script setup lang="ts">
import { shallowRef } from 'vue'
import { SendIcon } from '@lucide/vue'
import { Button } from '@/components/ui/button'
import MarkdownEditor from '@/components/markdown/MarkdownEditor.vue'

const props = withDefaults(
  defineProps<{
    saving?: boolean
    placeholder?: string
    editorLabel: string
  }>(),
  {
    saving: false,
    placeholder: 'Write a message in Markdown',
  },
)

const emit = defineEmits<{
  send: [body: string]
}>()

const draft = shallowRef('')

function sendMessage() {
  const body = draft.value.trim()
  if (!body || props.saving) return

  emit('send', body)
  draft.value = ''
}
</script>

<template>
  <form class="border-border bg-background grid gap-2 border-t p-3" @submit.prevent="sendMessage">
    <MarkdownEditor
      v-model="draft"
      :editor-label="props.editorLabel"
      :empty-text="props.placeholder"
      mode="edit"
      textarea-class="min-h-24"
      :rows="4"
    />
    <div class="flex justify-end">
      <Button type="submit" :disabled="props.saving || !draft.trim()">
        <SendIcon />
        Send
      </Button>
    </div>
  </form>
</template>
