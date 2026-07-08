import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/login',
    name: 'auth',
    component: { template: '<span />' },
  },
  {
    path: '/auth/callback',
    name: 'auth-callback',
    component: { template: '<span />' },
  },
  {
    path: '/',
    name: 'home',
    component: { template: '<span />' },
  },
  {
    path: '/kanban',
    name: 'board',
    component: { template: '<span />' },
  },
  {
    path: '/projects',
    name: 'projects',
    component: { template: '<span />' },
  },
  {
    path: '/admin-settings',
    name: 'admin-settings',
    component: { template: '<span />' },
  },
  {
    path: '/users',
    name: 'users',
    component: { template: '<span />' },
  },
  {
    path: '/users/:userId',
    name: 'user-profile',
    component: { template: '<span />' },
    props: true,
  },
  {
    path: '/users/:userId/edit',
    name: 'user-edit',
    component: { template: '<span />' },
    props: true,
  },
  {
    path: '/groups',
    name: 'groups',
    component: { template: '<span />' },
  },
  {
    path: '/groups/new',
    name: 'group-new',
    component: { template: '<span />' },
  },
  {
    path: '/groups/:groupId',
    name: 'group-detail',
    component: { template: '<span />' },
    props: true,
  },
  {
    path: '/tasks/:taskId',
    name: 'task-detail',
    component: { template: '<span />' },
    props: true,
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
