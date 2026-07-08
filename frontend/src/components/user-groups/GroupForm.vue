<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { SaveIcon, XIcon } from '@lucide/vue'
import ResourceSearch from '@/components/search/ResourceSearch.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import type { Group, GroupInput, ManagedUser, SearchResult } from '@/services/api'

const props = defineProps<{
  group: Group | null
  groups: readonly Group[]
  users: readonly ManagedUser[]
  saving: boolean
}>()

const emit = defineEmits<{
  saveGroup: [groupId: number | null, input: GroupInput]
  cancelEdit: []
}>()

const noParentValue = 'none'

const form = reactive({
  name: '',
  description: '',
  parentGroupId: noParentValue,
  userIds: [] as number[],
})
const selectedSearchResults = reactive(new Map<number, SearchResult>())

const editing = computed(() => props.group !== null)
const availableParentGroups = computed(() =>
  props.groups.filter((group) => group.id !== props.group?.id),
)
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
    }
  }),
)

watch(
  () => props.group,
  (group) => {
    form.name = group?.name ?? ''
    form.description = group?.description ?? ''
    form.parentGroupId = group?.parent_group_id ? String(group.parent_group_id) : noParentValue
    form.userIds = group?.user_ids ? [...group.user_ids] : []
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
}

function submitGroup() {
  const name = form.name.trim()
  if (!name) return

  emit('saveGroup', props.group?.id ?? null, {
    name,
    description: form.description.trim(),
    parent_group_id:
      form.parentGroupId === noParentValue ? null : Number.parseInt(form.parentGroupId, 10),
    user_ids: form.userIds,
  })
}

function resetForm() {
  emit('cancelEdit')
  form.name = ''
  form.description = ''
  form.parentGroupId = noParentValue
  form.userIds = []
  selectedSearchResults.clear()
}
</script>

<template>
  <form class="grid gap-4" @submit.prevent="submitGroup">
    <div class="grid gap-1.5">
      <Label for="group-name">Name</Label>
      <Input id="group-name" v-model="form.name" placeholder="Engineering" />
    </div>

    <div class="grid gap-1.5">
      <Label for="group-description">Description</Label>
      <Textarea id="group-description" v-model="form.description" rows="3" />
    </div>

    <div class="grid gap-1.5">
      <Label for="group-parent">Parent group</Label>
      <Select v-model="form.parentGroupId">
        <SelectTrigger id="group-parent" class="w-full" aria-label="Parent group">
          <SelectValue placeholder="No parent" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem :value="noParentValue">No parent</SelectItem>
          <SelectItem
            v-for="parentGroup in availableParentGroups"
            :key="parentGroup.id"
            :value="String(parentGroup.id)"
          >
            {{ parentGroup.name }}
          </SelectItem>
        </SelectContent>
      </Select>
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
          <Badge variant="secondary" class="shrink-0">Member</Badge>
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
        {{ editing ? 'Save group' : 'Create group' }}
      </Button>
      <Button type="button" variant="outline" @click="resetForm">
        <XIcon />
        Cancel
      </Button>
    </div>
  </form>
</template>
