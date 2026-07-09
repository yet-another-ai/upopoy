<script setup lang="ts">
import { computed, shallowRef, watch } from 'vue'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import type { DriveItem } from '@/services/api'

export type DriveDialogAction = 'create-folder' | 'create-markdown' | 'rename' | 'move' | 'delete'

export interface DriveActionPayload {
  name?: string
  parentId?: number | null
}

const props = defineProps<{
  action: DriveDialogAction | null
  item: DriveItem | null
  folders: readonly DriveItem[]
  saving: boolean
}>()

const emit = defineEmits<{
  submit: [payload: DriveActionPayload]
}>()

const open = defineModel<boolean>('open', { default: false })
const name = shallowRef('')
const parentId = shallowRef('')

const title = computed(() => {
  switch (props.action) {
    case 'create-folder':
      return 'New folder'
    case 'create-markdown':
      return 'New Markdown document'
    case 'rename':
      return 'Rename item'
    case 'move':
      return 'Move item'
    case 'delete':
      return 'Delete item?'
    default:
      return ''
  }
})

const description = computed(() => {
  switch (props.action) {
    case 'create-folder':
      return 'Create a folder in the current location.'
    case 'create-markdown':
      return 'Create a Markdown document in the current location.'
    case 'rename':
      return `Rename ${props.item?.name ?? 'this item'}.`
    case 'move':
      return `Choose a destination for ${props.item?.name ?? 'this item'}.`
    case 'delete':
      return `Delete ${props.item?.name ?? 'this item'} and its contents.`
    default:
      return ''
  }
})

const submitLabel = computed(() => {
  switch (props.action) {
    case 'create-folder':
      return 'Create folder'
    case 'create-markdown':
      return 'Create document'
    case 'rename':
      return 'Rename'
    case 'move':
      return 'Move'
    case 'delete':
      return 'Delete'
    default:
      return 'Save'
  }
})

const requiresName = computed(() =>
  props.action === 'create-folder' || props.action === 'create-markdown' || props.action === 'rename',
)

const moveTargets = computed(() => [
  { id: '', name: 'Root' },
  ...props.folders
    .filter((folder) => folder.id !== props.item?.id)
    .map((folder) => ({ id: String(folder.id), name: folder.name })),
])

const canSubmit = computed(() => {
  if (!props.action || props.saving) return false
  if (requiresName.value) return name.value.trim().length > 0
  if (props.action === 'move') return props.item?.parent_id !== normalizedParentId()
  return true
})

watch(
  () => [open.value, props.action, props.item?.id] as const,
  () => {
    if (!open.value) return

    name.value = props.item?.name ?? ''
    parentId.value = props.item?.parent_id == null ? '' : String(props.item.parent_id)
  },
  { immediate: true },
)

function submit() {
  if (!canSubmit.value) return

  emit('submit', {
    name: requiresName.value ? name.value.trim() : undefined,
    parentId: props.action === 'move' ? normalizedParentId() : undefined,
  })
}

function normalizedParentId() {
  return parentId.value ? Number(parentId.value) : null
}
</script>

<template>
  <Dialog v-model:open="open">
    <DialogContent>
      <DialogHeader>
        <DialogTitle>{{ title }}</DialogTitle>
        <DialogDescription>{{ description }}</DialogDescription>
      </DialogHeader>

      <form class="grid gap-4" @submit.prevent="submit">
        <div v-if="requiresName" class="grid gap-2">
          <Label for="drive-action-name">Name</Label>
          <Input
            id="drive-action-name"
            v-model="name"
            :disabled="props.saving"
            autocomplete="off"
          />
        </div>

        <div v-if="props.action === 'move'" class="grid gap-2">
          <Label for="drive-action-parent">Destination</Label>
          <select
            id="drive-action-parent"
            v-model="parentId"
            class="border-input bg-background h-8 rounded-lg border px-2.5 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
            :disabled="props.saving"
          >
            <option v-for="target in moveTargets" :key="target.id" :value="target.id">
              {{ target.name }}
            </option>
          </select>
        </div>

        <DialogFooter>
          <Button type="button" variant="outline" :disabled="props.saving" @click="open = false">
            Cancel
          </Button>
          <Button
            type="submit"
            :variant="props.action === 'delete' ? 'destructive' : 'default'"
            :disabled="!canSubmit"
          >
            {{ submitLabel }}
          </Button>
        </DialogFooter>
      </form>
    </DialogContent>
  </Dialog>
</template>
