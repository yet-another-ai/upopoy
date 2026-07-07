<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { ArrowLeftIcon } from '@lucide/vue'
import { RouterLink } from 'vue-router'
import GroupForm from '@/components/user-groups/GroupForm.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { Group, GroupInput, ManagedUser } from '@/services/api'

const props = defineProps<{
  groupId: number
  groups: readonly Group[]
  users: readonly ManagedUser[]
  loading: boolean
  saving: boolean
}>()

const emit = defineEmits<{
  loadGroups: []
  saveGroup: [groupId: number | null, input: GroupInput]
  closeGroupEditor: []
}>()

const group = computed(() => props.groups.find((item) => item.id === props.groupId) ?? null)

onMounted(() => {
  loadGroup()
})

watch(
  () => props.groupId,
  () => loadGroup(),
)

function loadGroup() {
  if (props.groups.length === 0) emit('loadGroups')
}

function saveGroup(groupId: number | null, input: GroupInput) {
  emit('saveGroup', groupId, input)
}
</script>

<template>
  <div class="grid gap-5">
    <div class="flex flex-wrap items-center gap-3">
      <Button as-child variant="outline" size="sm">
        <RouterLink :to="{ name: 'groups' }">
          <ArrowLeftIcon />
          Groups
        </RouterLink>
      </Button>
      <div class="min-w-0">
        <h2 class="truncate text-xl font-semibold">
          {{ group?.name || 'Edit group' }}
        </h2>
        <p class="text-muted-foreground text-sm">Edit group details and memberships.</p>
      </div>
    </div>

    <p v-if="props.loading && !group" class="text-muted-foreground text-sm">Loading group...</p>

    <Card v-else-if="group" class="rounded-lg shadow-none">
      <CardHeader>
        <CardTitle class="text-base">Group profile</CardTitle>
      </CardHeader>
      <CardContent>
        <GroupForm
          :group="group"
          :groups="props.groups"
          :users="props.users"
          :saving="props.saving"
          @save-group="saveGroup"
          @cancel-edit="emit('closeGroupEditor')"
        />
      </CardContent>
    </Card>

    <div v-else class="border-border bg-card text-card-foreground rounded-lg border p-5">
      <h3 class="text-base font-medium">Group not found</h3>
      <p class="text-muted-foreground mt-1 text-sm">This group may have been deleted.</p>
    </div>
  </div>
</template>
