<script setup lang="ts">
import GroupForm from '@/components/user-groups/GroupForm.vue'
import {
  Dialog,
  DialogDescription,
  DialogHeader,
  DialogScrollContent,
  DialogTitle,
} from '@/components/ui/dialog'
import type { Group, GroupInput, ManagedUser } from '@/services/api'

const props = defineProps<{
  open: boolean
  groups: readonly Group[]
  users: readonly ManagedUser[]
  saving: boolean
}>()

const emit = defineEmits<{
  close: []
  saveGroup: [groupId: number | null, input: GroupInput]
}>()

function updateOpen(open: boolean) {
  if (!open) emit('close')
}

function saveGroup(groupId: number | null, input: GroupInput) {
  emit('saveGroup', groupId, input)
}
</script>

<template>
  <Dialog :open="props.open" @update:open="updateOpen">
    <DialogScrollContent class="max-w-2xl">
      <DialogHeader>
        <DialogTitle>New group</DialogTitle>
        <DialogDescription>Create a group and assign its parent or members.</DialogDescription>
      </DialogHeader>

      <GroupForm
        :group="null"
        :groups="props.groups"
        :users="props.users"
        :saving="props.saving"
        @save-group="saveGroup"
        @cancel-edit="emit('close')"
      />
    </DialogScrollContent>
  </Dialog>
</template>
