import { request } from './client'
import type {
  ChatChannel,
  ChatChannelInput,
  ChatConversation,
  ChatMessage,
  ChatMessageInput,
  ChatMessageListParams,
} from './types'

function messageListPath(conversationId: number, params: ChatMessageListParams = {}) {
  const searchParams = new URLSearchParams()
  if (params.beforeId) searchParams.set('before_id', String(params.beforeId))
  if (params.limit) searchParams.set('limit', String(params.limit))

  const query = searchParams.toString()
  return `/api/v1/chats/conversations/${conversationId}/messages${query ? `?${query}` : ''}`
}

export const chatsApi = {
  listChatConversations: () => request<ChatConversation[]>('/api/v1/chats/conversations'),
  getChatConversation: (conversationId: number) =>
    request<ChatConversation>(`/api/v1/chats/conversations/${conversationId}`),
  createDirectConversation: (userId: number) =>
    request<ChatConversation>('/api/v1/chats/direct_conversations', {
      method: 'POST',
      body: JSON.stringify({ user_id: userId }),
    }),
  listChatChannels: (organizationId: number) =>
    request<ChatChannel[]>(`/api/v1/organizations/${organizationId}/chat_channels`),
  createChatChannel: (organizationId: number, chatChannel: ChatChannelInput) =>
    request<ChatChannel>(`/api/v1/organizations/${organizationId}/chat_channels`, {
      method: 'POST',
      body: JSON.stringify({ chat_channel: chatChannel }),
    }),
  updateChatChannel: (channelId: number, chatChannel: ChatChannelInput) =>
    request<ChatChannel>(`/api/v1/chat_channels/${channelId}`, {
      method: 'PATCH',
      body: JSON.stringify({ chat_channel: chatChannel }),
    }),
  deleteChatChannel: (channelId: number) =>
    request<void>(`/api/v1/chat_channels/${channelId}`, {
      method: 'DELETE',
    }),
  listChatMessages: (conversationId: number, params?: ChatMessageListParams) =>
    request<ChatMessage[]>(messageListPath(conversationId, params)),
  createChatMessage: (conversationId: number, message: ChatMessageInput) =>
    request<ChatMessage>(`/api/v1/chats/conversations/${conversationId}/messages`, {
      method: 'POST',
      body: JSON.stringify({ message }),
    }),
  createChatThread: (messageId: number) =>
    request<ChatConversation>(`/api/v1/chats/messages/${messageId}/thread`, {
      method: 'POST',
    }),
}
