<script setup lang="ts">
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

const props = withDefaults(
  defineProps<{
    title?: string
    description: string
    confirmLabel?: string
  }>(),
  {
    title: 'Delete item?',
    confirmLabel: 'Delete',
  },
)

const emit = defineEmits<{
  confirm: []
}>()

const open = defineModel<boolean>('open', { default: false })

function openDialog(event?: Event) {
  event?.preventDefault()
  open.value = true
}

function confirmDelete() {
  open.value = false
  emit('confirm')
}
</script>

<template>
  <slot name="trigger" :open="openDialog" />

  <Dialog v-model:open="open">
    <DialogContent>
      <DialogHeader>
        <DialogTitle>{{ props.title }}</DialogTitle>
        <DialogDescription>
          {{ props.description }}
        </DialogDescription>
      </DialogHeader>

      <DialogFooter>
        <DialogClose as-child>
          <Button type="button" variant="outline">Cancel</Button>
        </DialogClose>
        <Button type="button" variant="destructive" @click="confirmDelete">
          {{ props.confirmLabel }}
        </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
</template>
