import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import AdminSettingsView from '@/views/AdminSettingsView.vue'
import AuthCallbackView from '@/views/AuthCallbackView.vue'
import AuthView from '@/views/AuthView.vue'
import BoardWorkspaceView from '@/views/BoardWorkspaceView.vue'
import ChatsView from '@/views/ChatsView.vue'
import DashboardView from '@/views/DashboardView.vue'
import ProjectsView from '@/views/ProjectsView.vue'
import ServerErrorView from '@/views/ServerErrorView.vue'
import OrganizationsView from '@/views/OrganizationsView.vue'

export type ContentClassKind = 'default' | 'wide' | 'workspace'

declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
    requiresSystemAdmin?: boolean
    titleKey?: string
    contentClassKind?: ContentClassKind
  }
}

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'auth',
    component: AuthView,
    meta: { requiresAuth: false },
  },
  {
    path: '/auth/callback',
    name: 'auth-callback',
    component: AuthCallbackView,
    meta: { requiresAuth: false },
  },
  {
    path: '/server-error',
    name: 'server-error',
    component: ServerErrorView,
    meta: { requiresAuth: false },
  },
  {
    path: '/',
    name: 'home',
    component: DashboardView,
    meta: { requiresAuth: true, titleKey: 'navigation.apps' },
  },
  {
    path: '/kanban',
    name: 'board',
    component: BoardWorkspaceView,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.kanban',
      contentClassKind: 'workspace',
    },
  },
  {
    path: '/drive',
    name: 'drive',
    component: BoardWorkspaceView,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.drive',
      contentClassKind: 'workspace',
    },
  },
  {
    path: '/drive/items/:driveItemId/edit',
    name: 'drive-item-edit',
    component: BoardWorkspaceView,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.drive',
      contentClassKind: 'workspace',
    },
  },
  {
    path: '/chats',
    name: 'chats',
    component: ChatsView,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.chats',
      contentClassKind: 'workspace',
    },
  },
  {
    path: '/projects',
    name: 'projects',
    component: ProjectsView,
    meta: { requiresAuth: true, titleKey: 'navigation.projectManagement' },
  },
  {
    path: '/admin-settings',
    name: 'admin-settings',
    component: AdminSettingsView,
    meta: { requiresAuth: true, requiresSystemAdmin: true, titleKey: 'navigation.adminSettings' },
  },
  {
    path: '/users',
    name: 'users',
    component: OrganizationsView,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndOrganizations',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/users/:userId',
    name: 'user-profile',
    component: OrganizationsView,
    props: true,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndOrganizations',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/users/:userId/edit',
    name: 'user-edit',
    component: OrganizationsView,
    props: true,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndOrganizations',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/organizations',
    name: 'organizations',
    component: OrganizationsView,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndOrganizations',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/organizations/new',
    name: 'organization-new',
    component: OrganizationsView,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndOrganizations',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/organizations/:organizationId',
    name: 'organization-detail',
    component: OrganizationsView,
    props: true,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndOrganizations',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/tasks/:taskId',
    name: 'task-detail',
    component: BoardWorkspaceView,
    props: true,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.kanban',
      contentClassKind: 'workspace',
    },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
