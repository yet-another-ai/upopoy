import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useChatsStore } from '../chats'
import { api, type ChatConversation, type ChatMessage, type User } from '@/services/api'

vi.mock('@/services/api', () => ({
  api: {
    listChatConversations: vi.fn(),
    getChatConversation: vi.fn(),
    createDirectConversation: vi.fn(),
    listChatChannels: vi.fn(),
    createChatChannel: vi.fn(),
    updateChatChannel: vi.fn(),
    deleteChatChannel: vi.fn(),
    listChatMessages: vi.fn(),
    createChatMessage: vi.fn(),
    createChatThread: vi.fn(),
  },
}))

const user: User = {
  id: 1,
  email: 'one@example.com',
  display_name: 'One',
  title: null,
  bio: null,
  system_admin: false,
  created_at: '2026-07-09T00:00:00Z',
  updated_at: '2026-07-09T00:00:00Z',
}

const otherUser: User = {
  ...user,
  id: 2,
  email: 'two@example.com',
  display_name: 'Two',
}

const conversation: ChatConversation = {
  id: 10,
  kind: 'direct',
  title: 'Two',
  group_id: null,
  group_name: null,
  channel_id: null,
  channel_name: null,
  participants: [user, otherUser],
  other_participant: otherUser,
  parent_message: null,
  last_message_at: null,
  can_manage: false,
  created_at: '2026-07-09T00:00:00Z',
  updated_at: '2026-07-09T00:00:00Z',
}

const message: ChatMessage = {
  id: 20,
  chat_conversation_id: 10,
  conversation_id: 10,
  author: user,
  body: 'Hello **world**',
  thread_conversation_id: null,
  thread_reply_count: 0,
  thread_last_message_at: null,
  created_at: '2026-07-09T00:00:00Z',
  updated_at: '2026-07-09T00:00:00Z',
}

describe('useChatsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('opens a conversation and sends a markdown message', async () => {
    vi.mocked(api.getChatConversation).mockResolvedValue(conversation)
    vi.mocked(api.listChatMessages).mockResolvedValue([])
    vi.mocked(api.createChatMessage).mockResolvedValue(message)
    const store = useChatsStore()

    await store.openConversation(conversation.id)
    await store.postMessage(message.body)

    expect(api.createChatMessage).toHaveBeenCalledWith(conversation.id, { body: message.body })
    expect(store.messages).toEqual([message])
  })

  it('creates a thread and loads replies separately from the main timeline', async () => {
    const threadConversation: ChatConversation = {
      ...conversation,
      id: 11,
      kind: 'thread',
      title: 'Thread',
      parent_message: message,
    }
    const reply = { ...message, id: 21, conversation_id: 11, chat_conversation_id: 11 }
    vi.mocked(api.getChatConversation).mockResolvedValue(conversation)
    vi.mocked(api.listChatMessages).mockResolvedValueOnce([message]).mockResolvedValueOnce([reply])
    vi.mocked(api.createChatThread).mockResolvedValue(threadConversation)
    const store = useChatsStore()

    await store.openConversation(conversation.id)
    await store.openThread(message)

    expect(store.messages).toHaveLength(1)
    expect(store.threadConversation?.id).toBe(threadConversation.id)
    expect(store.threadMessages).toEqual([reply])
  })
})
