import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, shallowRef } from 'vue'
import {
  api,
  type ChatChannel,
  type ChatChannelInput,
  type ChatConversation,
  type ChatMessage,
} from '@/services/api'

export const useChatsStore = defineStore('chats', () => {
  const conversations = shallowRef<ChatConversation[]>([])
  const channelsByGroupId = shallowRef<Record<number, ChatChannel[]>>({})
  const activeConversation = shallowRef<ChatConversation | null>(null)
  const messages = shallowRef<ChatMessage[]>([])
  const threadConversation = shallowRef<ChatConversation | null>(null)
  const threadMessages = shallowRef<ChatMessage[]>([])
  const loading = shallowRef(false)
  const saving = shallowRef(false)
  const error = shallowRef<string | null>(null)

  const directConversations = computed(() =>
    conversations.value.filter((conversation) => conversation.kind === 'direct'),
  )
  const channelConversations = computed(() =>
    conversations.value.filter((conversation) => conversation.kind === 'channel'),
  )

  async function loadConversations() {
    loading.value = true
    error.value = null

    try {
      conversations.value = await api.listChatConversations()
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load chats'
    } finally {
      loading.value = false
    }
  }

  async function openConversation(conversationId: number) {
    loading.value = true
    error.value = null
    threadConversation.value = null
    threadMessages.value = []

    try {
      activeConversation.value = await api.getChatConversation(conversationId)
      messages.value = await api.listChatMessages(conversationId)
      upsertConversation(activeConversation.value)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to open chat'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createDirectConversation(userId: number) {
    const conversation = await api.createDirectConversation(userId)
    upsertConversation(conversation)
    await openConversation(conversation.id)
    return conversation
  }

  async function loadChannels(groupId: number) {
    const channels = await api.listChatChannels(groupId)
    channelsByGroupId.value = {
      ...channelsByGroupId.value,
      [groupId]: channels,
    }
    return channels
  }

  async function createChannel(groupId: number, input: ChatChannelInput) {
    saving.value = true
    error.value = null

    try {
      const channel = await api.createChatChannel(groupId, input)
      await syncChannelConversation(channel)
      await loadChannels(groupId)
      return channel
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to create channel'
      throw err
    } finally {
      saving.value = false
    }
  }

  async function updateChannel(channel: ChatChannel, input: ChatChannelInput) {
    saving.value = true
    error.value = null

    try {
      const updated = await api.updateChatChannel(channel.id, input)
      await syncChannelConversation(updated)
      await loadChannels(updated.group_id)
      return updated
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to update channel'
      throw err
    } finally {
      saving.value = false
    }
  }

  async function deleteChannel(channel: ChatChannel) {
    saving.value = true
    error.value = null

    try {
      await api.deleteChatChannel(channel.id)
      channelsByGroupId.value = {
        ...channelsByGroupId.value,
        [channel.group_id]: (channelsByGroupId.value[channel.group_id] ?? []).filter(
          (item) => item.id !== channel.id,
        ),
      }
      conversations.value = conversations.value.filter(
        (conversation) => conversation.id !== channel.conversation_id,
      )
      if (activeConversation.value?.id === channel.conversation_id) {
        activeConversation.value = null
        messages.value = []
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to delete channel'
      throw err
    } finally {
      saving.value = false
    }
  }

  async function refreshMessages() {
    if (!activeConversation.value) return

    messages.value = await api.listChatMessages(activeConversation.value.id)
  }

  async function postMessage(body: string) {
    if (!activeConversation.value) return null

    const message = await createMessage(activeConversation.value.id, body)
    messages.value = [...messages.value, message]
    await refreshActiveConversation()
    return message
  }

  async function openThread(message: ChatMessage) {
    threadConversation.value = await api.createChatThread(message.id)
    threadMessages.value = await api.listChatMessages(threadConversation.value.id)
    replaceMessage({
      ...message,
      thread_conversation_id: threadConversation.value.id,
      thread_reply_count: Math.max(message.thread_reply_count, threadMessages.value.length),
      thread_last_message_at: threadConversation.value.last_message_at,
    })
  }

  async function postThreadMessage(body: string) {
    if (!threadConversation.value) return null

    const message = await createMessage(threadConversation.value.id, body)
    threadMessages.value = [...threadMessages.value, message]
    await refreshThreadConversation()
    await refreshMessages()
    return message
  }

  function closeThread() {
    threadConversation.value = null
    threadMessages.value = []
  }

  function clearChats() {
    conversations.value = []
    channelsByGroupId.value = {}
    activeConversation.value = null
    messages.value = []
    threadConversation.value = null
    threadMessages.value = []
    error.value = null
  }

  async function createMessage(conversationId: number, body: string) {
    saving.value = true
    error.value = null

    try {
      return await api.createChatMessage(conversationId, { body })
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to send message'
      throw err
    } finally {
      saving.value = false
    }
  }

  async function refreshActiveConversation() {
    if (!activeConversation.value) return

    activeConversation.value = await api.getChatConversation(activeConversation.value.id)
    upsertConversation(activeConversation.value)
  }

  async function refreshThreadConversation() {
    if (!threadConversation.value) return

    threadConversation.value = await api.getChatConversation(threadConversation.value.id)
  }

  async function syncChannelConversation(channel: ChatChannel) {
    const conversation = await api.getChatConversation(channel.conversation_id)
    upsertConversation(conversation)
  }

  function upsertConversation(conversation: ChatConversation) {
    const existing = conversations.value.some((item) => item.id === conversation.id)
    const next = existing
      ? conversations.value.map((item) => (item.id === conversation.id ? conversation : item))
      : [conversation, ...conversations.value]
    conversations.value = sortConversations(next)
  }

  function replaceMessage(message: ChatMessage) {
    messages.value = messages.value.map((item) => (item.id === message.id ? message : item))
  }

  return {
    conversations,
    directConversations,
    channelConversations,
    channelsByGroupId,
    activeConversation,
    messages,
    threadConversation,
    threadMessages,
    loading,
    saving,
    error,
    loadConversations,
    openConversation,
    createDirectConversation,
    loadChannels,
    createChannel,
    updateChannel,
    deleteChannel,
    refreshMessages,
    postMessage,
    openThread,
    postThreadMessage,
    closeThread,
    clearChats,
  }
})

function sortConversations(conversations: readonly ChatConversation[]) {
  return [...conversations].sort((first, second) => {
    const firstTime = first.last_message_at ?? first.created_at
    const secondTime = second.last_message_at ?? second.created_at

    return secondTime.localeCompare(firstTime)
  })
}

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useChatsStore, import.meta.hot))
}
