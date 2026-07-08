<script setup lang="ts">
import { XIcon } from '@lucide/vue'
import { computed, reactive } from 'vue'
import ResourceSearch from '@/components/search/ResourceSearch.vue'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import type { SearchResult, User } from '@/services/api'

const props = withDefaults(
  defineProps<{
    label: string
    placeholder: string
    searchAriaLabel: string
    selectedUsers?: readonly User[]
    emptyText?: string
  }>(),
  {
    selectedUsers: () => [],
    emptyText: 'No users selected.',
  },
)

const model = defineModel<number[]>({ required: true })
const selectedSearchResults = reactive(new Map<number, SearchResult>())

const userLookup = computed(() => new Map(props.selectedUsers.map((user) => [user.id, user])))
const selectedItems = computed(() =>
  model.value.map((userId) => {
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

function addUser(result: SearchResult) {
  if (result.type !== 'user') return

  selectedSearchResults.set(result.id, result)
  if (model.value.includes(result.id)) return

  model.value = [...model.value, result.id]
}

function removeUser(userId: number) {
  model.value = model.value.filter((id) => id !== userId)
}
</script>

<template>
  <div class="grid gap-2">
    <Label>{{ props.label }}</Label>
    <ResourceSearch
      type="user"
      panel-width="input"
      :show-type-label="false"
      :placeholder="props.placeholder"
      :aria-label="props.searchAriaLabel"
      @select-result="addUser"
    />
    <div class="border-border grid max-h-44 gap-1 overflow-auto rounded-lg border p-2">
      <div
        v-for="item in selectedItems"
        :key="item.id"
        class="hover:bg-accent grid min-w-0 grid-cols-[minmax(0,1fr)_auto] items-center gap-2 rounded-md px-3 py-2 text-sm"
      >
        <div class="min-w-0">
          <span class="block truncate font-medium" :title="item.label">{{ item.label }}</span>
          <span
            v-if="item.detail"
            class="text-muted-foreground block truncate text-xs"
            :title="item.detail"
          >
            {{ item.detail }}
          </span>
        </div>
        <Button
          type="button"
          size="icon-sm"
          variant="ghost"
          :aria-label="`Remove ${props.label}`"
          @click="removeUser(item.id)"
        >
          <XIcon class="size-3.5" />
        </Button>
      </div>
      <p v-if="selectedItems.length === 0" class="text-muted-foreground px-2 py-1 text-sm">
        {{ props.emptyText }}
      </p>
    </div>
  </div>
</template>
