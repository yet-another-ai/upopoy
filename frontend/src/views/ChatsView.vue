<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, onMounted, shallowRef } from 'vue'
import ChatConversationPane from '@/components/chats/ChatConversationPane.vue'
import ChannelDialog from '@/components/chats/ChannelDialog.vue'
import ChatSidebar from '@/components/chats/ChatSidebar.vue'
import ChatThreadPanel from '@/components/chats/ChatThreadPanel.vue'
import { useChatsStore } from '@/stores/chats'
import { useToastsStore } from '@/stores/toasts'
import { useUserGroupsStore } from '@/stores/userGroups'
import type { ChatChannel, ChatChannelInput, Group } from '@/services/api'

const chatsStore = useChatsStore()
const userGroupsStore = useUserGroupsStore()
const toasts = useToastsStore()
const chats = storeToRefs(chatsStore)
const userGroups = storeToRefs(userGroupsStore)
const channelDialogOpen = shallowRef(false)
const selectedGroup = shallowRef<Group | null>(null)
const editingChannel = shallowRef<ChatChannel | null>(null)

const activeConversationId = computed(() => chats.activeConversation.value?.id ?? null)

onMounted(async () => {
  if (userGroups.groups.value.length === 0) await userGroupsStore.loadGroups()
  await chatsStore.loadConversations()
  await Promise.all(userGroups.groups.value.map((group) => chatsStore.loadChannels(group.id)))
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

function openNewChannel(group: Group) {
  selectedGroup.value = group
  editingChannel.value = null
  channelDialogOpen.value = true
}

function openEditChannel(channel: ChatChannel) {
  selectedGroup.value = userGroups.groups.value.find((group) => group.id === channel.group_id) ?? null
  editingChannel.value = channel
  channelDialogOpen.value = true
}

async function saveChannel(input: ChatChannelInput) {
  try {
    if (editingChannel.value) {
      await chatsStore.updateChannel(editingChannel.value, input)
    } else if (selectedGroup.value) {
      await chatsStore.createChannel(selectedGroup.value.id, input)
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
  selectedGroup.value = null
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
      :groups="userGroups.groups.value"
      :direct-conversations="chats.directConversations.value"
      :channel-conversations="chats.channelConversations.value"
      :channels-by-group-id="chats.channelsByGroupId.value"
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
