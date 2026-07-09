<script setup lang="ts">
import OrganizationForm from '@/components/organizations/OrganizationForm.vue'
import {
  Dialog,
  DialogDescription,
  DialogHeader,
  DialogScrollContent,
  DialogTitle,
} from '@/components/ui/dialog'
import type { OrganizationInput, ManagedUser } from '@/services/api'

const props = defineProps<{
  open: boolean
  users: readonly ManagedUser[]
  saving: boolean
}>()

const emit = defineEmits<{
  close: []
  saveOrganization: [organizationId: number | null, input: OrganizationInput]
}>()

function updateOpen(open: boolean) {
  if (!open) emit('close')
}

function saveOrganization(organizationId: number | null, input: OrganizationInput) {
  emit('saveOrganization', organizationId, input)
}
</script>

<template>
  <Dialog :open="props.open" @update:open="updateOpen">
    <DialogScrollContent class="max-w-2xl">
      <DialogHeader>
        <DialogTitle>New organization</DialogTitle>
        <DialogDescription>Create an organization and assign members.</DialogDescription>
      </DialogHeader>

      <OrganizationForm
        :organization="null"
        :users="props.users"
        :saving="props.saving"
        @save-organization="saveOrganization"
        @cancel-edit="emit('close')"
      />
    </DialogScrollContent>
  </Dialog>
</template>
