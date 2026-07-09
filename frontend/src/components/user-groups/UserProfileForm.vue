<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { SaveIcon, XIcon } from '@lucide/vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import type { Group, ManagedUser, UserProfileInput } from '@/services/api'

const props = defineProps<{
  user: ManagedUser | null
  groups: readonly Group[]
  saving: boolean
  canManageSystemAdmins: boolean
}>()

const emit = defineEmits<{
  saveUserProfile: [payload: { userId: number; input: UserProfileInput }]
  cancelEdit: []
}>()

const form = reactive({
  email: '',
  displayName: '',
  title: '',
  bio: '',
  systemAdmin: false,
})

const groupNames = computed(
  () => new Map(props.groups.map((group) => [group.id, group.name] as const)),
)
const memberships = computed(() => {
  if (!props.user) return []

  return props.user.group_ids
    .map((groupId) => groupNames.value.get(groupId))
    .filter((name): name is string => Boolean(name))
})

watch(
  () => props.user,
  (user) => {
    form.email = user?.email ?? ''
    form.displayName = user?.display_name ?? ''
    form.title = user?.title ?? ''
    form.bio = user?.bio ?? ''
    form.systemAdmin = user?.system_admin ?? false
  },
  { immediate: true },
)

function submitProfile() {
  if (!props.user || !form.email.trim()) return

  const input: UserProfileInput = {
    email: form.email.trim(),
    display_name: form.displayName.trim(),
    title: form.title.trim(),
    bio: form.bio.trim(),
  }
  if (props.canManageSystemAdmins) input.system_admin = form.systemAdmin

  emit('saveUserProfile', {
    userId: props.user.id,
    input,
  })
}
</script>

<template>
  <Card class="rounded-lg shadow-none">
    <CardHeader>
      <CardTitle class="text-base">Profile</CardTitle>
    </CardHeader>
    <CardContent>
      <form v-if="props.user" class="grid gap-4" @submit.prevent="submitProfile">
        <div class="grid gap-1.5">
          <Label for="user-email">Email</Label>
          <Input id="user-email" v-model="form.email" type="email" />
        </div>

        <div class="grid gap-1.5">
          <Label for="user-display-name">Display name</Label>
          <Input id="user-display-name" v-model="form.displayName" placeholder="Grace Hopper" />
        </div>

        <div class="grid gap-1.5">
          <Label for="user-title">Title</Label>
          <Input id="user-title" v-model="form.title" placeholder="Product lead" />
        </div>

        <div class="grid gap-1.5">
          <Label for="user-bio">Bio</Label>
          <Textarea id="user-bio" v-model="form.bio" rows="5" />
        </div>

        <div class="grid gap-2">
          <p class="text-sm font-medium">Groups</p>
          <div class="flex flex-wrap gap-1.5">
            <Badge v-for="groupName in memberships" :key="groupName" variant="secondary">
              {{ groupName }}
            </Badge>
            <span v-if="memberships.length === 0" class="text-muted-foreground text-xs">
              No groups
            </span>
          </div>
        </div>

        <label
          v-if="props.canManageSystemAdmins"
          class="border-border grid gap-4 rounded-lg border p-4 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-center"
        >
          <span class="min-w-0">
            <span class="block text-sm font-medium">System admin</span>
            <span class="text-muted-foreground mt-1 block text-sm">
              Can update application-level admin settings.
            </span>
          </span>
          <span class="inline-flex items-center gap-2 justify-self-start sm:justify-self-end">
            <input
              v-model="form.systemAdmin"
              type="checkbox"
              class="peer sr-only"
              :disabled="props.saving"
            >
            <span
              class="peer-checked:bg-primary bg-muted after:bg-background relative h-6 w-10 rounded-full transition after:absolute after:top-1 after:left-1 after:size-4 after:rounded-full after:transition peer-checked:after:translate-x-4"
              aria-hidden="true"
            />
            <span class="text-sm">{{ form.systemAdmin ? 'Enabled' : 'Disabled' }}</span>
          </span>
        </label>

        <div class="flex flex-wrap gap-2">
          <Button type="submit" :disabled="props.saving">
            <SaveIcon />
            Save profile
          </Button>
          <Button type="button" variant="outline" @click="emit('cancelEdit')">
            <XIcon />
            Cancel
          </Button>
        </div>
      </form>

      <p v-else class="text-muted-foreground text-sm">Select a user to edit their profile.</p>
    </CardContent>
  </Card>
</template>
