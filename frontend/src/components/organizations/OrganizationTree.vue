<script setup lang="ts">
import { PencilIcon, Trash2Icon, UsersRoundIcon } from '@lucide/vue'
import ConfirmDeleteDialog from '@/components/common/ConfirmDeleteDialog.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { Organization } from '@/services/api'

const props = defineProps<{
  organizations: readonly Organization[]
  selectedOrganizationId: number | null
  loading: boolean
}>()

const emit = defineEmits<{
  selectOrganization: [organizationId: number]
  deleteOrganization: [organizationId: number]
}>()
</script>

<template>
  <Card class="rounded-lg shadow-none">
    <CardHeader>
      <CardTitle class="text-base">Organizations</CardTitle>
    </CardHeader>
    <CardContent>
      <p v-if="props.loading" class="text-muted-foreground text-sm">Loading organizations...</p>

      <div v-else-if="props.organizations.length > 0" class="grid gap-2">
        <article
          v-for="organization in props.organizations"
          :key="organization.id"
          class="border-border grid min-h-12 gap-3 rounded-lg border p-3 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-center"
          :class="organization.id === props.selectedOrganizationId && 'border-primary/30 bg-accent'"
        >
          <div class="min-w-0">
            <div class="flex flex-wrap items-center gap-2">
              <h3 class="truncate text-sm font-medium">{{ organization.name }}</h3>
              <Badge v-if="organization.id === props.selectedOrganizationId" variant="secondary">
                Editing
              </Badge>
            </div>
            <div class="text-muted-foreground mt-1 flex flex-wrap items-center gap-2 text-xs">
              <span class="inline-flex items-center gap-1">
                <UsersRoundIcon class="size-3.5" />
                {{ organization.users_count }} members
              </span>
              <Badge v-if="organization.admins_count > 0" variant="secondary">
                {{ organization.admins_count }} admins
              </Badge>
              <span v-if="organization.description" class="truncate">
                {{ organization.description }}
              </span>
            </div>
          </div>

          <div v-if="organization.can_admin" class="flex gap-1">
            <Button
              size="icon-sm"
              variant="ghost"
              aria-label="Manage organization"
              @click="emit('selectOrganization', organization.id)"
            >
              <PencilIcon />
            </Button>
            <ConfirmDeleteDialog
              title="Delete organization?"
              :description="`This will permanently delete '${organization.name}'.`"
              @confirm="emit('deleteOrganization', organization.id)"
            >
              <template #trigger="{ open }">
                <Button
                  size="icon-sm"
                  variant="ghost"
                  class="text-destructive"
                  aria-label="Delete organization"
                  @click="open"
                >
                  <Trash2Icon />
                </Button>
              </template>
            </ConfirmDeleteDialog>
          </div>
        </article>
      </div>

      <p v-else class="text-muted-foreground text-sm">Create an organization to organize users.</p>
    </CardContent>
  </Card>
</template>
