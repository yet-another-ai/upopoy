<script setup lang="ts">
import { computed, shallowRef, watch } from 'vue'
import { ChevronRightIcon, PencilIcon, Trash2Icon, UsersRoundIcon } from '@lucide/vue'
import { TreeItem, TreeRoot } from 'reka-ui'
import ConfirmDeleteDialog from '@/components/common/ConfirmDeleteDialog.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { cn } from '@/lib/utils'
import type { Group } from '@/services/api'

interface GroupTreeNode extends Group {
  children: GroupTreeNode[]
}

const props = defineProps<{
  groups: readonly Group[]
  selectedGroupId: number | null
  loading: boolean
}>()

const emit = defineEmits<{
  selectGroup: [groupId: number]
  deleteGroup: [groupId: number]
}>()

const expandedIds = shallowRef<string[]>([])

const treeNodes = computed(() => {
  const nodes = new Map<number, GroupTreeNode>()
  const roots: GroupTreeNode[] = []

  for (const group of props.groups) {
    nodes.set(group.id, { ...group, children: [] })
  }

  for (const node of nodes.values()) {
    const parent = node.parent_group_id ? nodes.get(node.parent_group_id) : null
    if (parent) parent.children.push(node)
    else roots.push(node)
  }

  const sortNodes = (items: GroupTreeNode[]) => {
    items.sort((first, second) => first.name.localeCompare(second.name))
    items.forEach((item) => sortNodes(item.children))
  }

  sortNodes(roots)
  return roots
})

const selectedNode = computed({
  get: () => findNode(treeNodes.value, props.selectedGroupId),
  set: (node: GroupTreeNode | undefined) => {
    if (node) emit('selectGroup', node.id)
  },
})

watch(
  () => props.groups,
  (groups) => {
    expandedIds.value = groups.map((group) => String(group.id))
  },
  { immediate: true },
)

function findNode(
  nodes: readonly GroupTreeNode[],
  groupId: number | null,
): GroupTreeNode | undefined {
  if (!groupId) return undefined

  for (const node of nodes) {
    if (node.id === groupId) return node

    const child = findNode(node.children, groupId)
    if (child) return child
  }

  return undefined
}

function getKey(node: GroupTreeNode) {
  return String(node.id)
}

function getChildren(node: GroupTreeNode) {
  return node.children.length > 0 ? node.children : undefined
}
</script>

<template>
  <Card class="rounded-lg shadow-none">
    <CardHeader>
      <CardTitle class="text-base">Groups</CardTitle>
    </CardHeader>
    <CardContent>
      <p v-if="props.loading" class="text-muted-foreground text-sm">Loading groups...</p>

      <TreeRoot
        v-else-if="treeNodes.length > 0"
        v-model="selectedNode"
        v-model:expanded="expandedIds"
        :items="treeNodes"
        :get-key="getKey"
        :get-children="getChildren"
        class="grid gap-1"
      >
        <template #default="{ flattenItems }">
          <TreeItem
            v-for="node in flattenItems"
            :key="node._id"
            v-bind="node.bind"
            v-slot="{ isExpanded, handleToggle }"
            :class="
              cn(
                'focus-visible:ring-ring grid rounded-lg border border-transparent outline-none focus-visible:ring-2',
                node.value.id === props.selectedGroupId && 'border-primary/30 bg-accent',
              )
            "
          >
            <div
              class="grid min-h-12 grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-2 rounded-lg px-2 py-2"
              :style="{ paddingLeft: `${(node.level - 1) * 1.25 + 0.5}rem` }"
            >
              <button
                type="button"
                class="hover:bg-muted grid size-7 place-items-center rounded-md"
                :class="!node.hasChildren && 'invisible'"
                tabindex="-1"
                @click.stop="handleToggle"
              >
                <ChevronRightIcon
                  class="text-muted-foreground size-4 transition"
                  :class="isExpanded && 'rotate-90'"
                />
              </button>

              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-2">
                  <h3 class="truncate text-sm font-medium">{{ node.value.name }}</h3>
                  <Badge v-if="node.value.id === props.selectedGroupId" variant="secondary">
                    Editing
                  </Badge>
                </div>
                <div class="text-muted-foreground mt-1 flex flex-wrap items-center gap-2 text-xs">
                  <span class="inline-flex items-center gap-1">
                    <UsersRoundIcon class="size-3.5" />
                    {{ node.value.users_count }} members
                  </span>
                  <Badge v-if="node.value.admins_count > 0" variant="secondary">
                    {{ node.value.admins_count }} admins
                  </Badge>
                  <span v-if="node.value.description" class="truncate">
                    {{ node.value.description }}
                  </span>
                </div>
              </div>

              <div v-if="node.value.can_admin" class="flex gap-1">
                <Button
                  size="icon-sm"
                  variant="ghost"
                  aria-label="Manage group"
                  @click.stop="emit('selectGroup', node.value.id)"
                >
                  <PencilIcon />
                </Button>
                <ConfirmDeleteDialog
                  title="Delete group?"
                  :description="`This will permanently delete '${node.value.name}'.`"
                  @confirm="emit('deleteGroup', node.value.id)"
                >
                  <template #trigger="{ open }">
                    <Button
                      size="icon-sm"
                      variant="ghost"
                      class="text-destructive"
                      aria-label="Delete group"
                      @click.stop="open"
                    >
                      <Trash2Icon />
                    </Button>
                  </template>
                </ConfirmDeleteDialog>
              </div>
            </div>
          </TreeItem>
        </template>
      </TreeRoot>

      <p v-else class="text-muted-foreground text-sm">Create a group to organize users.</p>
    </CardContent>
  </Card>
</template>
