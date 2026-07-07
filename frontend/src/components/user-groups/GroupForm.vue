<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { SaveIcon, XIcon } from '@lucide/vue'
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
import type { Group, GroupInput, ManagedUser } from '@/services/api'

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

const editing = computed(() => props.group !== null)
const availableParentGroups = computed(() =>
  props.groups.filter((group) => group.id !== props.group?.id),
)

watch(
  () => props.group,
  (group) => {
    form.name = group?.name ?? ''
    form.description = group?.description ?? ''
    form.parentGroupId = group?.parent_group_id ? String(group.parent_group_id) : noParentValue
    form.userIds = group?.user_ids ? [...group.user_ids] : []
  },
  { immediate: true },
)

function toggleUser(userId: number) {
  form.userIds = form.userIds.includes(userId)
    ? form.userIds.filter((id) => id !== userId)
    : [...form.userIds, userId]
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
      <div class="border-border grid max-h-56 gap-1 overflow-auto rounded-lg border p-2">
        <label
          v-for="user in props.users"
          :key="user.id"
          class="hover:bg-accent flex items-center gap-2 rounded-md px-2 py-1.5 text-sm"
        >
          <!-- prettier-ignore -->
          <input
            type="checkbox"
            class="accent-primary size-4"
            :checked="form.userIds.includes(user.id)"
            @change="toggleUser(user.id)"
          >
          <span class="min-w-0 truncate">{{ user.email }}</span>
        </label>
        <p v-if="props.users.length === 0" class="text-muted-foreground px-2 py-1 text-sm">
          No users found.
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
