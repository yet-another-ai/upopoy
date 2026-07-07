<script setup lang="ts">
import { PlusIcon } from '@lucide/vue'
import GroupTree from '@/components/user-groups/GroupTree.vue'
import { Button } from '@/components/ui/button'
import type { Group } from '@/services/api'

const props = defineProps<{
  groups: readonly Group[]
  loading: boolean
}>()

const emit = defineEmits<{
  createGroup: []
  selectGroup: [groupId: number]
  deleteGroup: [groupId: number]
}>()
</script>

<template>
  <div class="grid gap-5">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div class="grid gap-1">
        <h2 class="text-xl font-semibold">Groups</h2>
        <p class="text-muted-foreground text-sm">Browse group hierarchy and memberships.</p>
      </div>

      <Button type="button" @click="emit('createGroup')">
        <PlusIcon />
        New group
      </Button>
    </div>
    <GroupTree
      :groups="props.groups"
      :selected-group-id="null"
      :loading="props.loading"
      @select-group="emit('selectGroup', $event)"
      @delete-group="emit('deleteGroup', $event)"
    />
  </div>
</template>
