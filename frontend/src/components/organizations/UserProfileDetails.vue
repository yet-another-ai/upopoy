<script setup lang="ts">
import { computed } from 'vue'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { Organization, ManagedUser } from '@/services/api'

const props = defineProps<{
  user: ManagedUser
  organizations: readonly Organization[]
}>()

const organizationNames = computed(
  () => new Map(props.organizations.map((organization) => [organization.id, organization.name] as const)),
)
const memberships = computed(() =>
  props.user.organization_ids
    .map((organizationId) => organizationNames.value.get(organizationId))
    .filter((name): name is string => Boolean(name)),
)
</script>

<template>
  <div class="grid gap-5 lg:grid-cols-[minmax(0,1fr)_20rem]">
    <Card class="rounded-lg shadow-none">
      <CardHeader>
        <CardTitle class="text-base">Profile</CardTitle>
      </CardHeader>
      <CardContent class="grid gap-4">
        <div class="grid gap-1">
          <p class="text-muted-foreground text-xs font-medium uppercase">Email</p>
          <p class="break-words text-sm">{{ props.user.email }}</p>
        </div>

        <div class="grid gap-1">
          <p class="text-muted-foreground text-xs font-medium uppercase">Display name</p>
          <p class="text-sm">{{ props.user.display_name || 'Not set' }}</p>
        </div>

        <div class="grid gap-1">
          <p class="text-muted-foreground text-xs font-medium uppercase">Title</p>
          <p class="text-sm">{{ props.user.title || 'Not set' }}</p>
        </div>

        <div class="grid gap-1">
          <p class="text-muted-foreground text-xs font-medium uppercase">Access</p>
          <div>
            <Badge v-if="props.user.system_admin">System admin</Badge>
            <span v-else class="text-sm">Standard user</span>
          </div>
        </div>

        <div class="grid gap-1">
          <p class="text-muted-foreground text-xs font-medium uppercase">Bio</p>
          <p class="text-muted-foreground whitespace-pre-wrap text-sm">
            {{ props.user.bio || 'No bio yet.' }}
          </p>
        </div>
      </CardContent>
    </Card>

    <Card class="rounded-lg shadow-none">
      <CardHeader>
        <CardTitle class="text-base">Organizations</CardTitle>
      </CardHeader>
      <CardContent>
        <div class="flex flex-wrap gap-1.5">
          <Badge v-for="organizationName in memberships" :key="organizationName" variant="secondary">
            {{ organizationName }}
          </Badge>
          <span v-if="memberships.length === 0" class="text-muted-foreground text-sm">
            No organizations
          </span>
        </div>
      </CardContent>
    </Card>
  </div>
</template>
