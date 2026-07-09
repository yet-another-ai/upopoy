<script setup lang="ts">
import { computed } from 'vue'
import { HashIcon, MessageCircleIcon, PencilIcon, PlusIcon, Trash2Icon } from '@lucide/vue'
import { Button } from '@/components/ui/button'
import ResourceSearch from '@/components/search/ResourceSearch.vue'
import type { ChatChannel, ChatConversation, Organization, SearchResult } from '@/services/api'

const props = defineProps<{
  organizations: readonly Organization[]
  directConversations: readonly ChatConversation[]
  channelConversations: readonly ChatConversation[]
  channelsByOrganizationId: Record<number, ChatChannel[]>
  activeConversationId: number | null
}>()

const emit = defineEmits<{
  openConversation: [conversationId: number]
  startDirect: [userId: number]
  newChannel: [organization: Organization]
  editChannel: [channel: ChatChannel]
  deleteChannel: [channel: ChatChannel]
}>()

const channelsByConversationId = computed(() => {
  const channels = Object.values(props.channelsByOrganizationId).flat()
  return new Map(channels.map((channel) => [channel.conversation_id, channel]))
})

function startDirect(result: SearchResult) {
  if (result.type === 'user') emit('startDirect', result.id)
}

function channelsForOrganization(organizationId: number) {
  return props.channelConversations.filter((conversation) => conversation.organization_id === organizationId)
}
</script>

<template>
  <aside class="border-border bg-sidebar flex min-h-0 w-full flex-col border-r lg:w-80">
    <header class="border-border grid gap-3 border-b p-4">
      <div>
        <h2 class="text-base font-semibold">Chats</h2>
        <p class="text-muted-foreground text-xs">Direct messages and organization channels</p>
      </div>
      <ResourceSearch
        type="user"
        panel-width="input"
        :show-type-label="false"
        placeholder="Start a direct message"
        aria-label="Start a direct message"
        @select-result="startDirect"
      />
    </header>

    <div class="min-h-0 flex-1 overflow-auto p-3">
      <section class="grid gap-1">
        <p class="text-muted-foreground px-2 text-xs font-medium uppercase">Direct messages</p>
        <button
          v-for="conversation in props.directConversations"
          :key="conversation.id"
          type="button"
          class="hover:bg-sidebar-accent grid min-w-0 grid-cols-[auto_minmax(0,1fr)] items-center gap-2 rounded-md px-2 py-2 text-left text-sm"
          :class="{ 'bg-sidebar-accent': props.activeConversationId === conversation.id }"
          @click="emit('openConversation', conversation.id)"
        >
          <MessageCircleIcon class="text-muted-foreground size-4" />
          <span class="truncate">{{ conversation.title }}</span>
        </button>
        <p
          v-if="props.directConversations.length === 0"
          class="text-muted-foreground px-2 py-2 text-sm"
        >
          No direct messages yet.
        </p>
      </section>

      <section class="mt-5 grid gap-3">
        <div v-for="organization in props.organizations" :key="organization.id" class="grid gap-1">
          <div class="flex min-w-0 items-center gap-2 px-2">
            <p class="text-muted-foreground min-w-0 flex-1 truncate text-xs font-medium uppercase">
              {{ organization.name }}
            </p>
            <Button
              v-if="organization.can_admin"
              type="button"
              size="icon-sm"
              variant="ghost"
              :aria-label="`New channel in ${organization.name}`"
              @click="emit('newChannel', organization)"
            >
              <PlusIcon />
            </Button>
          </div>

          <div
            v-for="conversation in channelsForOrganization(organization.id)"
            :key="conversation.id"
            class="group hover:bg-sidebar-accent grid min-w-0 grid-cols-[minmax(0,1fr)_auto] items-center rounded-md"
            :class="{ 'bg-sidebar-accent': props.activeConversationId === conversation.id }"
          >
            <button
              type="button"
              class="grid min-w-0 grid-cols-[auto_minmax(0,1fr)] items-center gap-2 px-2 py-2 text-left text-sm"
              @click="emit('openConversation', conversation.id)"
            >
              <HashIcon class="text-muted-foreground size-4" />
              <span class="truncate">{{ conversation.channel_name ?? conversation.title }}</span>
            </button>
            <span v-if="conversation.can_manage" class="flex pr-1 opacity-0 group-hover:opacity-100">
              <Button
                v-if="channelsByConversationId.get(conversation.id)"
                type="button"
                size="icon-sm"
                variant="ghost"
                aria-label="Edit channel"
                @click.stop="emit('editChannel', channelsByConversationId.get(conversation.id)!)"
              >
                <PencilIcon />
              </Button>
              <Button
                v-if="channelsByConversationId.get(conversation.id)"
                type="button"
                size="icon-sm"
                variant="ghost"
                aria-label="Delete channel"
                @click.stop="emit('deleteChannel', channelsByConversationId.get(conversation.id)!)"
              >
                <Trash2Icon />
              </Button>
            </span>
          </div>

          <p
            v-if="channelsForOrganization(organization.id).length === 0"
            class="text-muted-foreground px-2 py-1 text-xs"
          >
            No channels.
          </p>
        </div>
      </section>
    </div>
  </aside>
</template>
