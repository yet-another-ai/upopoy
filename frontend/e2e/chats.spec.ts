import { expect, test, type Page, type Route } from '@playwright/test'

const timestamp = '2026-07-09T00:00:00Z'
const authToken = 'Bearer e2e-token'

interface UserPayload {
  id: number
  email: string
  display_name: string
  title: string | null
  bio: string | null
  system_admin: boolean
  created_at: string
  updated_at: string
}

interface ConversationPayload {
  id: number
  kind: string
  title: string
  organization_id: number | null
  organization_name: string | null
  channel_id: number | null
  channel_name: string | null
  participants: UserPayload[]
  other_participant: UserPayload | null
  parent_message: MessagePayload | null
  last_message_at: string | null
  can_manage: boolean
  created_at: string
  updated_at: string
}

interface MessagePayload {
  id: number
  chat_conversation_id: number
  conversation_id: number
  author: UserPayload
  body: string
  thread_conversation_id: number | null
  thread_reply_count: number
  thread_last_message_at: string | null
  created_at: string
  updated_at: string
}

async function json(route: Route, body: unknown, status = 200) {
  await route.fulfill({
    status,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
}

async function installMockApi(page: Page) {
  let nextMessageId = 30
  const currentUser = userPayload(1, 'founder@example.com', 'Founder')
  const otherUser = userPayload(2, 'teammate@example.com', 'Teammate')
  const organization = {
    id: 1,
    name: 'Engineering',
    description: null,
    user_ids: [1, 2],
    users_count: 2,
    admin_user_ids: [1],
    admins_count: 1,
    can_admin: true,
    created_at: timestamp,
    updated_at: timestamp,
  }
  const conversations = [
    conversationPayload({
      id: 10,
      kind: 'channel',
      title: 'general',
      organization_id: 1,
      organization_name: 'Engineering',
      channel_id: 100,
      channel_name: 'general',
      can_manage: true,
    }),
  ]
  const channels = [
    {
      id: 100,
      organization_id: 1,
      name: 'general',
      description: 'Team chat',
      conversation_id: 10,
      can_manage: true,
      created_at: timestamp,
      updated_at: timestamp,
    },
  ]
  const messagesByConversation = new Map<number, MessagePayload[]>([
    [
      10,
      [
        messagePayload({
          id: 20,
          conversation_id: 10,
          author: otherUser,
          body: 'Welcome to **general**',
        }),
      ],
    ],
  ])
  let threadConversation: ConversationPayload | null = null

  await page.addInitScript((token) => {
    localStorage.setItem('upopoy.authToken', token)
  }, authToken)

  await page.route('**/api/v1/auth/me', async (route) => {
    await json(route, { user: currentUser })
  })

  await page.route('**/api/v1/projects', async (route) => {
    await json(route, [])
  })

  await page.route('**/api/v1/organizations', async (route) => {
    await json(route, [organization])
  })

  await page.route('**/api/v1/search**', async (route) => {
    await json(route, {
      results: [
        {
          slug: 'user:2',
          type: 'user',
          id: 2,
          title: 'Teammate',
          snippet: 'teammate@example.com',
          api_path: '/api/v1/users/2',
          metadata: {},
          updated_at: timestamp,
        },
      ],
    })
  })

  await page.route('**/api/v1/chats/conversations', async (route) => {
    await json(route, conversations)
  })

  await page.route('**/api/v1/chats/direct_conversations', async (route) => {
    const direct = conversationPayload({
      id: 11,
      kind: 'direct',
      title: 'Teammate',
      participants: [currentUser, otherUser],
      other_participant: otherUser,
    })
    conversations.unshift(direct)
    messagesByConversation.set(11, [])
    await json(route, direct, 201)
  })

  await page.route('**/api/v1/organizations/1/chat_channels', async (route) => {
    if (route.request().method() === 'GET') {
      await json(route, channels)
      return
    }

    const requestBody = route.request().postDataJSON() as { chat_channel: { name: string; description?: string } }
    const channel = {
      id: 101,
      organization_id: 1,
      name: requestBody.chat_channel.name,
      description: requestBody.chat_channel.description ?? null,
      conversation_id: 12,
      can_manage: true,
      created_at: timestamp,
      updated_at: timestamp,
    }
    channels.push(channel)
    conversations.unshift(
      conversationPayload({
        id: 12,
        kind: 'channel',
        title: channel.name,
        organization_id: 1,
        organization_name: 'Engineering',
        channel_id: channel.id,
        channel_name: channel.name,
        can_manage: true,
      }),
    )
    messagesByConversation.set(12, [])
    await json(route, channel, 201)
  })

  await page.route('**/api/v1/chats/conversations/*/messages', async (route) => {
    const conversationId = Number(route.request().url().split('/').at(-2))
    if (route.request().method() === 'GET') {
      await json(route, messagesByConversation.get(conversationId) ?? [])
      return
    }

    const requestBody = route.request().postDataJSON() as { message: { body: string } }
    const message = messagePayload({
      id: nextMessageId++,
      conversation_id: conversationId,
      author: currentUser,
      body: requestBody.message.body,
    })
    messagesByConversation.set(conversationId, [...(messagesByConversation.get(conversationId) ?? []), message])
    await json(route, message, 201)
  })

  await page.route('**/api/v1/chats/messages/20/thread', async (route) => {
    threadConversation = conversationPayload({
      id: 13,
      kind: 'thread',
      title: 'Thread',
      parent_message: messagesByConversation.get(10)?.[0],
    })
    messagesByConversation.set(13, [])
    await json(route, threadConversation, 201)
  })

  await page.route('**/api/v1/chats/conversations/*', async (route) => {
    const id = Number(route.request().url().split('/').at(-1))
    await json(route, [...conversations, threadConversation].find((conversation) => conversation?.id === id))
  })
}

function userPayload(id: number, email: string, displayName: string): UserPayload {
  return {
    id,
    email,
    display_name: displayName,
    title: null,
    bio: null,
    system_admin: false,
    created_at: timestamp,
    updated_at: timestamp,
  }
}

function conversationPayload(input: {
  id: number
  kind: string
  title: string
  organization_id?: number
  organization_name?: string
  channel_id?: number
  channel_name?: string
  participants?: UserPayload[]
  other_participant?: UserPayload
  parent_message?: MessagePayload
  can_manage?: boolean
}): ConversationPayload {
  return {
    id: input.id,
    kind: input.kind,
    title: input.title,
    organization_id: input.organization_id ?? null,
    organization_name: input.organization_name ?? null,
    channel_id: input.channel_id ?? null,
    channel_name: input.channel_name ?? null,
    participants: input.participants ?? [],
    other_participant: input.other_participant ?? null,
    parent_message: input.parent_message ?? null,
    last_message_at: null,
    can_manage: input.can_manage ?? false,
    created_at: timestamp,
    updated_at: timestamp,
  }
}

function messagePayload(input: { id: number; conversation_id: number; author: UserPayload; body: string }): MessagePayload {
  return {
    id: input.id,
    chat_conversation_id: input.conversation_id,
    conversation_id: input.conversation_id,
    author: input.author,
    body: input.body,
    thread_conversation_id: null,
    thread_reply_count: 0,
    thread_last_message_at: null,
    created_at: timestamp,
    updated_at: timestamp,
  }
}

test('uses chats, channels, markdown messages, and threads', async ({ page }) => {
  await installMockApi(page)

  await page.goto('/chats')

  await expect(page.getByText('general')).toBeVisible()
  await page.getByRole('button', { name: 'general' }).click()
  await expect(page.locator('.markdown-body')).toContainText('Welcome to general')

  await page.getByLabel('Chat message').fill('## Update\n\n- Shipped')
  await page.getByRole('button', { name: 'Send' }).click()
  await expect(page.getByText('Update Shipped')).toBeVisible()

  await expect(page.getByRole('button', { name: 'Start thread' })).toHaveCount(0)
  await page.getByText('Welcome to general').click({ button: 'right' })
  await page.getByRole('menuitem', { name: 'Start thread' }).click()
  await expect(page.getByText('Parent message')).toBeVisible()
  await page.getByLabel('Thread reply').fill('Thread **reply**')
  await page.locator('aside').getByRole('button', { name: 'Send' }).click()
  await expect(page.locator('aside').getByText('Thread reply')).toBeVisible()

  await page.getByLabel('Start a direct message').fill('Team')
  await page.getByRole('button', { name: /Teammate/ }).click()
  await expect(page.getByRole('heading', { name: 'Teammate' })).toBeVisible()

  await page.getByLabel('New channel in Engineering').click()
  await page.getByLabel('Name').fill('planning')
  await page.getByRole('button', { name: 'Save channel' }).click()
  await expect(page.getByText('planning')).toBeVisible()
})
