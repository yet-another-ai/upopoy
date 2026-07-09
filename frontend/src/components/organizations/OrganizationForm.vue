<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { SaveIcon, XIcon } from '@lucide/vue'
import ResourceSearch from '@/components/search/ResourceSearch.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import type { Organization, OrganizationInput, ManagedUser, SearchResult } from '@/services/api'

const props = defineProps<{
  organization: Organization | null
  users: readonly ManagedUser[]
  saving: boolean
}>()

const emit = defineEmits<{
  saveOrganization: [organizationId: number | null, input: OrganizationInput]
  cancelEdit: []
}>()

const form = reactive({
  name: '',
  description: '',
  userIds: [] as number[],
  adminUserIds: [] as number[],
})
const selectedSearchResults = reactive(new Map<number, SearchResult>())

const editing = computed(() => props.organization !== null)
const userLookup = computed(() => new Map(props.users.map((user) => [user.id, user] as const)))
const selectedMembers = computed(() =>
  form.userIds.map((userId) => {
    const user = userLookup.value.get(userId)
    const result = selectedSearchResults.get(userId)
    const label = user?.display_name || result?.title || user?.email || `User #${userId}`
    const detail = user?.display_name ? user.email : result?.snippet

    return {
      id: userId,
      label,
      detail: detail && detail !== label ? detail : null,
      admin: form.adminUserIds.includes(userId),
    }
  }),
)

watch(
  () => props.organization,
  (organization) => {
    form.name = organization?.name ?? ''
    form.description = organization?.description ?? ''
    form.userIds = organization?.user_ids ? [...organization.user_ids] : []
    form.adminUserIds = organization?.admin_user_ids ? [...organization.admin_user_ids] : []
    selectedSearchResults.clear()
  },
  { immediate: true },
)

function addUser(result: SearchResult) {
  if (result.type !== 'user') return

  selectedSearchResults.set(result.id, result)
  if (form.userIds.includes(result.id)) return

  form.userIds = [...form.userIds, result.id]
}

function removeUser(userId: number) {
  form.userIds = form.userIds.filter((id) => id !== userId)
  form.adminUserIds = form.adminUserIds.filter((id) => id !== userId)
}

function updateAdmin(userId: number, admin: boolean) {
  if (admin) {
    if (!form.userIds.includes(userId)) form.userIds = [...form.userIds, userId]
    if (!form.adminUserIds.includes(userId)) form.adminUserIds = [...form.adminUserIds, userId]
    return
  }

  form.adminUserIds = form.adminUserIds.filter((id) => id !== userId)
}

function submitOrganization() {
  const name = form.name.trim()
  if (!name) return

  emit('saveOrganization', props.organization?.id ?? null, {
    name,
    description: form.description.trim(),
    user_ids: form.userIds,
    admin_user_ids: form.adminUserIds,
  })
}

function resetForm() {
  emit('cancelEdit')
  form.name = ''
  form.description = ''
  form.userIds = []
  form.adminUserIds = []
  selectedSearchResults.clear()
}
</script>

<template>
  <form class="grid gap-4" @submit.prevent="submitOrganization">
    <div class="grid gap-1.5">
      <Label for="organization-name">Name</Label>
      <Input id="organization-name" v-model="form.name" placeholder="Engineering" />
    </div>

    <div class="grid gap-1.5">
      <Label for="organization-description">Description</Label>
      <Textarea id="organization-description" v-model="form.description" rows="3" />
    </div>

    <fieldset class="grid gap-2">
      <legend class="text-sm font-medium">Members</legend>
      <ResourceSearch
        type="user"
        panel-width="input"
        :show-type-label="false"
        placeholder="Search users"
        aria-label="Search users to add as members"
        @select-result="addUser"
      />
      <div class="border-border grid max-h-56 gap-1 overflow-auto rounded-lg border p-2">
        <div
          v-for="member in selectedMembers"
          :key="member.id"
          class="hover:bg-accent flex min-w-0 items-center gap-2 rounded-md px-2 py-1.5 text-sm"
        >
          <div class="min-w-0 flex-1">
            <span class="block truncate font-medium">{{ member.label }}</span>
            <span v-if="member.detail" class="text-muted-foreground block truncate text-xs">
              {{ member.detail }}
            </span>
          </div>
          <Badge :variant="member.admin ? 'default' : 'secondary'" class="shrink-0">
            {{ member.admin ? 'Admin' : 'Member' }}
          </Badge>
          <label class="inline-flex shrink-0 items-center gap-2">
            <input
              type="checkbox"
              class="peer sr-only"
              :checked="member.admin"
              :disabled="props.saving"
              @change="updateAdmin(member.id, ($event.target as HTMLInputElement).checked)"
            >
            <span
              class="peer-checked:bg-primary bg-muted after:bg-background relative h-5 w-9 rounded-full transition after:absolute after:top-1 after:left-1 after:size-3 after:rounded-full after:transition peer-checked:after:translate-x-4"
              aria-hidden="true"
            />
            <span class="text-xs">Admin</span>
          </label>
          <Button
            type="button"
            size="icon-sm"
            variant="ghost"
            aria-label="Remove member"
            @click="removeUser(member.id)"
          >
            <XIcon class="size-3.5" />
          </Button>
        </div>
        <p v-if="selectedMembers.length === 0" class="text-muted-foreground px-2 py-1 text-sm">
          No members selected.
        </p>
      </div>
    </fieldset>

    <div class="flex flex-wrap gap-2">
      <Button type="submit" :disabled="props.saving">
        <SaveIcon />
        {{ editing ? 'Save organization' : 'Create organization' }}
      </Button>
      <Button type="button" variant="outline" @click="resetForm">
        <XIcon />
        Cancel
      </Button>
    </div>
  </form>
</template>
