import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import AdminSettingsView from '@/views/AdminSettingsView.vue'
import AuthCallbackView from '@/views/AuthCallbackView.vue'
import AuthView from '@/views/AuthView.vue'
import BoardWorkspaceView from '@/views/BoardWorkspaceView.vue'
import DashboardView from '@/views/DashboardView.vue'
import ProjectsView from '@/views/ProjectsView.vue'
import ServerErrorView from '@/views/ServerErrorView.vue'
import UserGroupsView from '@/views/UserGroupsView.vue'

export type ContentClassKind = 'default' | 'wide' | 'workspace'

declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
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
    path: '/projects',
    name: 'projects',
    component: ProjectsView,
    meta: { requiresAuth: true, titleKey: 'navigation.projectManagement' },
  },
  {
    path: '/admin-settings',
    name: 'admin-settings',
    component: AdminSettingsView,
    meta: { requiresAuth: true, titleKey: 'navigation.adminSettings' },
  },
  {
    path: '/users',
    name: 'users',
    component: UserGroupsView,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndGroups',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/users/:userId',
    name: 'user-profile',
    component: UserGroupsView,
    props: true,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndGroups',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/users/:userId/edit',
    name: 'user-edit',
    component: UserGroupsView,
    props: true,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndGroups',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/groups',
    name: 'groups',
    component: UserGroupsView,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndGroups',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/groups/new',
    name: 'group-new',
    component: UserGroupsView,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndGroups',
      contentClassKind: 'wide',
    },
  },
  {
    path: '/groups/:groupId',
    name: 'group-detail',
    component: UserGroupsView,
    props: true,
    meta: {
      requiresAuth: true,
      titleKey: 'navigation.usersAndGroups',
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
