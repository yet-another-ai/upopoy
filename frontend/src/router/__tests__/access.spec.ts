import { describe, expect, it } from 'vitest'
import { nextRouteForAccess } from '../access'
import router from '../index'

describe('route access', () => {
  const regularUser = {
    id: 1,
    email: 'user@example.com',
    display_name: null,
    title: null,
    bio: null,
    system_admin: false,
    created_at: '2026-07-09T00:00:00Z',
    updated_at: '2026-07-09T00:00:00Z',
  }
  const systemAdmin = { ...regularUser, system_admin: true }

  it('sends unauthenticated users from protected routes to login', () => {
    const route = router.resolve({ name: 'board' })

    expect(nextRouteForAccess(route, false)).toEqual({ name: 'auth' })
  })

  it('allows public routes before session restore', () => {
    const loginRoute = router.resolve({ name: 'auth' })
    const callbackRoute = router.resolve({ name: 'auth-callback' })

    expect(nextRouteForAccess(loginRoute, false)).toBeNull()
    expect(nextRouteForAccess(callbackRoute, false)).toBeNull()
  })

  it('sends authenticated users away from the login route', () => {
    const route = router.resolve({ name: 'auth' })

    expect(nextRouteForAccess(route, true)).toEqual({ name: 'home' })
  })

  it('sends regular users away from system admin routes', () => {
    const route = router.resolve({ name: 'admin-settings' })

    expect(nextRouteForAccess(route, true, regularUser)).toEqual({ name: 'home' })
  })

  it('allows system admins on system admin routes', () => {
    const route = router.resolve({ name: 'admin-settings' })

    expect(nextRouteForAccess(route, true, systemAdmin)).toBeNull()
  })
})
