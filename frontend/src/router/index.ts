import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'board',
    component: { template: '<span />' },
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
