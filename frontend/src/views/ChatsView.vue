<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, onMounted, shallowRef } from 'vue'
import ChatConversationPane from '@/components/chats/ChatConversationPane.vue'
import ChannelDialog from '@/components/chats/ChannelDialog.vue'
import ChatSidebar from '@/components/chats/ChatSidebar.vue'
import ChatThreadPanel from '@/components/chats/ChatThreadPanel.vue'
import { useChatsStore } from '@/stores/chats'
import { useToastsStore } from '@/stores/toasts'
import { useOrganizationsStore } from '@/stores/organizations'
import type { ChatChannel, ChatChannelInput, Organization } from '@/services/api'

const chatsStore = useChatsStore()
const organizationsStore = useOrganizationsStore()
const toasts = useToastsStore()
const chats = storeToRefs(chatsStore)
const organizations = storeToRefs(organizationsStore)
const channelDialogOpen = shallowRef(false)
const selectedOrganization = shallowRef<Organization | null>(null)
const editingChannel = shallowRef<ChatChannel | null>(null)

const activeConversationId = computed(() => chats.activeConversation.value?.id ?? null)

onMounted(async () => {
  if (organizations.organizations.value.length === 0) await organizationsStore.loadOrganizations()
  await chatsStore.loadConversations()
  await Promise.all(organizations.organizations.value.map((organization) => chatsStore.loadChannels(organization.id)))
})

async function openConversation(conversationId: number) {
  try {
    await chatsStore.openConversation(conversationId)
  } catch (err) {
    notifyError(err, 'Unable to open chat')
  }
}

async function startDirect(userId: number) {
  try {
    await chatsStore.createDirectConversation(userId)
  } catch (err) {
    notifyError(err, 'Unable to start direct message')
  }
}

function openNewChannel(organization: Organization) {
  selectedOrganization.value = organization
  editingChannel.value = null
  channelDialogOpen.value = true
}

function openEditChannel(channel: ChatChannel) {
  selectedOrganization.value = organizations.organizations.value.find((organization) => organization.id === channel.organization_id) ?? null
  editingChannel.value = channel
  channelDialogOpen.value = true
}

async function saveChannel(input: ChatChannelInput) {
  try {
    if (editingChannel.value) {
      await chatsStore.updateChannel(editingChannel.value, input)
    } else if (selectedOrganization.value) {
      await chatsStore.createChannel(selectedOrganization.value.id, input)
    }
    closeChannelDialog()
  } catch (err) {
    notifyError(err, 'Unable to save channel')
  }
}

async function deleteChannel(channel: ChatChannel) {
  if (!window.confirm(`Delete #${channel.name}?`)) return

  try {
    await chatsStore.deleteChannel(channel)
  } catch (err) {
    notifyError(err, 'Unable to delete channel')
  }
}

function closeChannelDialog() {
  channelDialogOpen.value = false
  selectedOrganization.value = null
  editingChannel.value = null
}

async function sendMessage(body: string) {
  try {
    await chatsStore.postMessage(body)
  } catch (err) {
    notifyError(err, 'Unable to send message')
  }
}

async function sendThreadMessage(body: string) {
  try {
    await chatsStore.postThreadMessage(body)
  } catch (err) {
    notifyError(err, 'Unable to send reply')
  }
}

async function refreshMessages() {
  try {
    await chatsStore.refreshMessages()
  } catch (err) {
    notifyError(err, 'Unable to refresh messages')
  }
}

function notifyError(err: unknown, fallback: string) {
  toasts.error(fallback, err instanceof Error ? err.message : fallback)
}
</script>

<template>
  <main class="flex min-h-0 flex-1 flex-col lg:flex-row">
    <ChatSidebar
      :organizations="organizations.organizations.value"
      :direct-conversations="chats.directConversations.value"
      :channel-conversations="chats.channelConversations.value"
      :channels-by-organization-id="chats.channelsByOrganizationId.value"
      :active-conversation-id="activeConversationId"
      @open-conversation="openConversation"
      @start-direct="startDirect"
      @new-channel="openNewChannel"
      @edit-channel="openEditChannel"
      @delete-channel="deleteChannel"
    />

    <ChatConversationPane
      :conversation="chats.activeConversation.value"
      :messages="chats.messages.value"
      :loading="chats.loading.value"
      :saving="chats.saving.value"
      @refresh="refreshMessages"
      @send="sendMessage"
      @open-thread="chatsStore.openThread"
    />

    <ChatThreadPanel
      :conversation="chats.threadConversation.value"
      :messages="chats.threadMessages.value"
      :saving="chats.saving.value"
      @close="chatsStore.closeThread"
      @send="sendThreadMessage"
    />

    <ChannelDialog
      :open="channelDialogOpen"
      :channel="editingChannel"
      :saving="chats.saving.value"
      @close="closeChannelDialog"
      @save="saveChannel"
    />
  </main>
</template>
