import type { RouteLocationRaw, RouteRecordNameGeneric } from 'vue-router'
import type { User } from '@/services/api'

interface AccessRoute {
  name: RouteRecordNameGeneric | null
  meta: {
    requiresAuth?: boolean
    requiresSystemAdmin?: boolean
  }
}

export function nextRouteForAccess(
  route: AccessRoute,
  authenticated: boolean,
  currentUser: User | null = null,
): RouteLocationRaw | null {
  if (route.name === 'auth-callback') return null

  if (!authenticated && route.meta.requiresAuth !== false) {
    return route.name === 'auth' ? null : { name: 'auth' }
  }

  if (authenticated && route.name === 'auth') return { name: 'home' }

  if (authenticated && route.meta.requiresSystemAdmin && !currentUser?.system_admin) {
    return { name: 'home' }
  }

  return null
}
