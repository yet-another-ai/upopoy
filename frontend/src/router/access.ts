import type { RouteLocationRaw, RouteRecordNameGeneric } from 'vue-router'

interface AccessRoute {
  name: RouteRecordNameGeneric | null
  meta: {
    requiresAuth?: boolean
  }
}

export function nextRouteForAccess(
  route: AccessRoute,
  authenticated: boolean,
): RouteLocationRaw | null {
  if (route.name === 'auth-callback') return null

  if (!authenticated && route.meta.requiresAuth !== false) {
    return route.name === 'auth' ? null : { name: 'auth' }
  }

  if (authenticated && route.name === 'auth') return { name: 'home' }

  return null
}
