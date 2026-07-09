<script setup lang="ts">
import { PlusIcon } from '@lucide/vue'
import OrganizationTree from '@/components/organizations/OrganizationTree.vue'
import { Button } from '@/components/ui/button'
import type { Organization } from '@/services/api'

const props = defineProps<{
  organizations: readonly Organization[]
  loading: boolean
}>()

const emit = defineEmits<{
  createOrganization: []
  selectOrganization: [organizationId: number]
  deleteOrganization: [organizationId: number]
}>()
</script>

<template>
  <div class="grid gap-5">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div class="grid gap-1">
        <h2 class="text-xl font-semibold">Organizations</h2>
        <p class="text-muted-foreground text-sm">Browse organizations and memberships.</p>
      </div>

      <Button type="button" @click="emit('createOrganization')">
        <PlusIcon />
        New organization
      </Button>
    </div>
    <OrganizationTree
      :organizations="props.organizations"
      :selected-organization-id="null"
      :loading="props.loading"
      @select-organization="emit('selectOrganization', $event)"
      @delete-organization="emit('deleteOrganization', $event)"
    />
  </div>
</template>
