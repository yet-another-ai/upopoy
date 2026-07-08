import { describe, expect, it } from 'vitest'
import { nextRouteForAccess } from '../access'
import router from '../index'

describe('route access', () => {
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
})
