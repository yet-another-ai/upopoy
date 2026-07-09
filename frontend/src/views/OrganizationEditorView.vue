<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { ArrowLeftIcon } from '@lucide/vue'
import { RouterLink } from 'vue-router'
import OrganizationForm from '@/components/organizations/OrganizationForm.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { Organization, OrganizationInput, ManagedUser } from '@/services/api'

const props = defineProps<{
  organizationId: number
  organizations: readonly Organization[]
  users: readonly ManagedUser[]
  loading: boolean
  saving: boolean
}>()

const emit = defineEmits<{
  loadOrganizations: []
  saveOrganization: [organizationId: number | null, input: OrganizationInput]
  closeOrganizationEditor: []
}>()

const organization = computed(() => props.organizations.find((item) => item.id === props.organizationId) ?? null)

onMounted(() => {
  loadOrganization()
})

watch(
  () => props.organizationId,
  () => loadOrganization(),
)

function loadOrganization() {
  if (props.organizations.length === 0) emit('loadOrganizations')
}

function saveOrganization(organizationId: number | null, input: OrganizationInput) {
  emit('saveOrganization', organizationId, input)
}
</script>

<template>
  <div class="grid gap-5">
    <div class="flex flex-wrap items-center gap-3">
      <Button as-child variant="outline" size="sm">
        <RouterLink :to="{ name: 'organizations' }">
          <ArrowLeftIcon />
          Organizations
        </RouterLink>
      </Button>
      <div class="min-w-0">
        <h2 class="truncate text-xl font-semibold">
          {{ organization?.name || 'Edit organization' }}
        </h2>
        <p class="text-muted-foreground text-sm">Edit organization details and memberships.</p>
      </div>
    </div>

    <p v-if="props.loading && !organization" class="text-muted-foreground text-sm">Loading organization...</p>

    <div
      v-else-if="organization && !organization.can_admin"
      class="border-border bg-card text-card-foreground rounded-lg border p-5"
    >
      <h3 class="text-base font-medium">Organization management unavailable</h3>
      <p class="text-muted-foreground mt-1 text-sm">
        You can view this organization, but only organization admins can manage its settings.
      </p>
    </div>

    <Card v-else-if="organization" class="rounded-lg shadow-none">
      <CardHeader>
        <CardTitle class="text-base">Organization profile</CardTitle>
      </CardHeader>
      <CardContent>
        <OrganizationForm
          :organization="organization"
          :users="props.users"
          :saving="props.saving"
          @save-organization="saveOrganization"
          @cancel-edit="emit('closeOrganizationEditor')"
        />
      </CardContent>
    </Card>

    <div v-else class="border-border bg-card text-card-foreground rounded-lg border p-5">
      <h3 class="text-base font-medium">Organization not found</h3>
      <p class="text-muted-foreground mt-1 text-sm">This organization may have been deleted.</p>
    </div>
  </div>
</template>
