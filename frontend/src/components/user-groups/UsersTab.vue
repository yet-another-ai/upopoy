<script setup lang="ts">
import { computed } from 'vue'
import { EyeIcon } from '@lucide/vue'
import UserPagination from '@/components/user-groups/UserPagination.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { Group, ManagedUser, UserListParams, UserPaginationMeta } from '@/services/api'

const props = defineProps<{
  users: readonly ManagedUser[]
  groups: readonly Group[]
  meta: UserPaginationMeta
  loading: boolean
}>()

const emit = defineEmits<{
  loadUsers: [params: UserListParams]
  editUser: [userId: number]
}>()

const groupNames = computed(
  () => new Map(props.groups.map((group) => [group.id, group.name] as const)),
)

function userGroupNames(user: ManagedUser) {
  return user.group_ids
    .map((groupId) => groupNames.value.get(groupId))
    .filter((name): name is string => Boolean(name))
}
</script>

<template>
  <Card class="rounded-lg shadow-none">
    <CardHeader>
      <CardTitle class="text-base">Users</CardTitle>
    </CardHeader>
    <CardContent class="grid gap-4">
      <p v-if="props.loading" class="text-muted-foreground text-sm">Loading users...</p>

      <div v-else-if="props.users.length > 0" class="grid gap-3">
        <article
          v-for="user in props.users"
          :key="user.id"
          class="border-border grid gap-3 rounded-lg border p-4 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-center"
        >
          <div class="min-w-0">
            <div class="flex flex-wrap items-center gap-2">
              <h3 class="truncate font-medium">
                {{ user.display_name || user.email }}
              </h3>
            </div>
            <p class="text-muted-foreground mt-1 truncate text-sm">{{ user.email }}</p>
            <p v-if="user.title" class="text-muted-foreground mt-1 text-sm">{{ user.title }}</p>
            <div class="mt-3 flex flex-wrap gap-1.5">
              <Badge v-for="groupName in userGroupNames(user)" :key="groupName" variant="secondary">
                {{ groupName }}
              </Badge>
              <span v-if="user.group_ids.length === 0" class="text-muted-foreground text-xs">
                No groups
              </span>
            </div>
          </div>

          <Button size="sm" variant="outline" @click="emit('editUser', user.id)">
            <EyeIcon />
            View profile
          </Button>
        </article>
      </div>

      <p v-else class="text-muted-foreground text-sm">No users found.</p>

      <UserPagination
        :meta="props.meta"
        :loading="props.loading"
        @change-page="emit('loadUsers', { page: $event })"
      />
    </CardContent>
  </Card>
</template>
