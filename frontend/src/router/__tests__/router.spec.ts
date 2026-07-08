import { describe, expect, it } from 'vitest'
import router from '../index'

describe('router', () => {
  it('marks login and OAuth callback routes as public', () => {
    expect(router.resolve({ name: 'auth' }).meta.requiresAuth).toBe(false)
    expect(router.resolve({ name: 'auth-callback' }).meta.requiresAuth).toBe(false)
  })

  it('marks workspace routes as authenticated and assigns layout metadata', () => {
    expect(router.resolve({ name: 'home' }).meta.requiresAuth).toBe(true)
    expect(router.resolve({ name: 'board' }).meta).toMatchObject({
      requiresAuth: true,
      titleKey: 'navigation.kanban',
      contentClassKind: 'workspace',
    })
    expect(router.resolve({ name: 'task-detail', params: { taskId: 1 } }).meta).toMatchObject({
      requiresAuth: true,
      titleKey: 'navigation.kanban',
      contentClassKind: 'workspace',
    })
    expect(router.resolve({ name: 'users' }).meta.contentClassKind).toBe('wide')
  })
})
