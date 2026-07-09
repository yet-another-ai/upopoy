<script setup lang="ts">
import { reactive, watch } from 'vue'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogDescription,
  DialogHeader,
  DialogScrollContent,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import type { ChatChannel, ChatChannelInput } from '@/services/api'

const props = defineProps<{
  open: boolean
  channel: ChatChannel | null
  saving: boolean
}>()

const emit = defineEmits<{
  close: []
  save: [input: ChatChannelInput]
}>()

const form = reactive({
  name: '',
  description: '',
})

watch(
  () => [props.open, props.channel] as const,
  () => {
    form.name = props.channel?.name ?? ''
    form.description = props.channel?.description ?? ''
  },
  { immediate: true },
)

function updateOpen(open: boolean) {
  if (!open) emit('close')
}

function submitForm() {
  const name = form.name.trim()
  if (!name) return

  emit('save', {
    name,
    description: form.description.trim(),
  })
}
</script>

<template>
  <Dialog :open="props.open" @update:open="updateOpen">
    <DialogScrollContent class="max-w-md">
      <DialogHeader>
        <DialogTitle>{{ props.channel ? 'Edit channel' : 'New channel' }}</DialogTitle>
        <DialogDescription>Channels belong to a group and use Markdown messages.</DialogDescription>
      </DialogHeader>

      <form class="grid gap-4" @submit.prevent="submitForm">
        <div class="grid gap-1.5">
          <Label for="chat-channel-name">Name</Label>
          <Input id="chat-channel-name" v-model="form.name" />
        </div>
        <div class="grid gap-1.5">
          <Label for="chat-channel-description">Description</Label>
          <Textarea id="chat-channel-description" v-model="form.description" rows="3" />
        </div>
        <div class="flex justify-end gap-2">
          <Button type="button" variant="ghost" @click="emit('close')">Cancel</Button>
          <Button type="submit" :disabled="props.saving || !form.name.trim()">Save channel</Button>
        </div>
      </form>
    </DialogScrollContent>
  </Dialog>
</template>
