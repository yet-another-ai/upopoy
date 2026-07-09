import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import ChatMessageItem from '../ChatMessageItem.vue'
import type { ChatMessage, User } from '@/services/api'

const author: User = {
  id: 1,
  email: 'one@example.com',
  display_name: 'One',
  title: null,
  bio: null,
  system_admin: false,
  created_at: '2026-07-09T00:00:00Z',
  updated_at: '2026-07-09T00:00:00Z',
}

const message: ChatMessage = {
  id: 20,
  chat_conversation_id: 10,
  conversation_id: 10,
  author,
  body: 'Hello **world**',
  thread_conversation_id: null,
  thread_reply_count: 0,
  thread_last_message_at: null,
  created_at: '2026-07-09T00:00:00Z',
  updated_at: '2026-07-09T00:00:00Z',
}

describe('ChatMessageItem', () => {
  it('renders markdown and opens new threads from the context menu', async () => {
    const wrapper = mount(ChatMessageItem, { props: { message } })

    expect(wrapper.html()).toContain('<strong>world</strong>')
    expect(wrapper.text()).not.toContain('Start thread')

    await wrapper.get('article').trigger('contextmenu', { clientX: 12, clientY: 16 })
    await wrapper.get('[role="menuitem"]').trigger('click')

    expect(wrapper.emitted('openThread')).toEqual([[message]])
  })

  it('opens existing threads from the replies button', async () => {
    const messageWithReplies = {
      ...message,
      thread_conversation_id: 30,
      thread_reply_count: 2,
      thread_last_message_at: '2026-07-09T00:05:00Z',
    }
    const wrapper = mount(ChatMessageItem, { props: { message: messageWithReplies } })

    await wrapper.get('button').trigger('click')

    expect(wrapper.emitted('openThread')).toEqual([[messageWithReplies]])
  })
})
