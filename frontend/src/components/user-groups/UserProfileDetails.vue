<script setup lang="ts">
import { computed } from 'vue'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { Group, ManagedUser, UserSkillLevel } from '@/services/api'

const props = defineProps<{
  user: ManagedUser
  groups: readonly Group[]
}>()

const groupNames = computed(
  () => new Map(props.groups.map((group) => [group.id, group.name] as const)),
)
const memberships = computed(() =>
  props.user.group_ids
    .map((groupId) => groupNames.value.get(groupId))
    .filter((name): name is string => Boolean(name)),
)

const skillLevelLabels: Record<UserSkillLevel, string> = {
  learning: 'Learning',
  working: 'Working',
  advanced: 'Advanced',
  expert: 'Expert',
}
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

        <div class="grid gap-2">
          <p class="text-muted-foreground text-xs font-medium uppercase">Skills</p>
          <div v-if="props.user.skills.length > 0" class="grid gap-2">
            <div
              v-for="skill in props.user.skills"
              :key="`${skill.name}-${skill.level}`"
              class="border-border grid gap-1 rounded-lg border p-3"
            >
              <div class="flex flex-wrap items-center gap-2">
                <p class="min-w-0 break-words text-sm font-medium">{{ skill.name }}</p>
                <Badge variant="secondary">{{ skillLevelLabels[skill.level] }}</Badge>
              </div>
              <p v-if="skill.note" class="text-muted-foreground whitespace-pre-wrap text-sm">
                {{ skill.note }}
              </p>
            </div>
          </div>
          <p v-else class="text-muted-foreground text-sm">No skills listed yet.</p>
        </div>
      </CardContent>
    </Card>

    <Card class="rounded-lg shadow-none">
      <CardHeader>
        <CardTitle class="text-base">Groups</CardTitle>
      </CardHeader>
      <CardContent>
        <div class="flex flex-wrap gap-1.5">
          <Badge v-for="groupName in memberships" :key="groupName" variant="secondary">
            {{ groupName }}
          </Badge>
          <span v-if="memberships.length === 0" class="text-muted-foreground text-sm">
            No groups
          </span>
        </div>
      </CardContent>
    </Card>
  </div>
</template>
