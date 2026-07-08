<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, onMounted, shallowRef, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { RouterView, useRoute, useRouter } from 'vue-router'
import ToastViewport from '@/components/common/ToastViewport.vue'
import AuthenticatedLayout from '@/components/layout/AuthenticatedLayout.vue'
import GlobalSearch from '@/components/search/GlobalSearch.vue'
import { nextRouteForAccess } from '@/router/access'
import { useAuthStore } from '@/stores/auth'
import { useBoardStore } from '@/stores/board'
import { useProjectsStore } from '@/stores/projects'
import { useToastsStore } from '@/stores/toasts'
import { useUserGroupsStore } from '@/stores/userGroups'
import type { ContentClassKind } from '@/router'
import type { SearchResult } from '@/services/api'

const authStore = useAuthStore()
const projectsStore = useProjectsStore()
const boardStore = useBoardStore()
const userGroupsStore = useUserGroupsStore()
const toasts = useToastsStore()
const auth = storeToRefs(authStore)
const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const ready = shallowRef(false)

const publicRoute = computed(() => route.meta.requiresAuth === false)
const authenticatedPageTitle = computed(() => t(route.meta.titleKey ?? 'navigation.apps'))
const authenticatedContentClass = computed(() => contentClassFor(route.meta.contentClassKind))

onMounted(() => {
  void initializeApp()
})

watch(
  [() => route.fullPath, () => auth.authenticated.value],
  () => {
    if (ready.value) void enforceRouteAccess()
  },
)

async function initializeApp() {
  await router.isReady()

  if (route.name === 'auth-callback') {
    ready.value = true
    return
  }

  const authenticated = await authStore.restoreSession()
  ready.value = true

  if (!authenticated) {
    await enforceRouteAccess()
    return
  }

  await preloadWorkspaceData()
  await enforceRouteAccess()
}

async function enforceRouteAccess() {
  const nextRoute = nextRouteForAccess(route, auth.authenticated.value)
  if (nextRoute) await router.replace(nextRoute)
}

async function preloadWorkspaceData() {
  await Promise.all([projectsStore.loadProjects(), userGroupsStore.loadGroups()])
}

async function signOut() {
  await authStore.logout()
  projectsStore.clearProjects()
  boardStore.clearBoard()
  userGroupsStore.clearDirectory()
  toasts.clearToasts()
  await router.push({ name: 'auth' })
}

async function openSearchResult(result: SearchResult) {
  if (result.type === 'project') {
    projectsStore.selectProject(result.id)
    await boardStore.loadBoard(result.id)
    await router.push({ name: 'board' })
    return
  }

  if (result.type === 'task') {
    const projectId = Number(result.metadata.project_id)
    if (Number.isInteger(projectId) && projectId > 0) projectsStore.selectProject(projectId)

    await router.push({ name: 'task-detail', params: { taskId: result.id } })
    return
  }

  if (result.type === 'user') {
    await router.push({ name: 'user-profile', params: { userId: result.id } })
    return
  }

  await router.push({ name: 'group-detail', params: { groupId: result.id } })
}

function contentClassFor(kind: ContentClassKind = 'default') {
  if (kind === 'workspace') return 'flex min-h-0 w-full flex-1 flex-col p-0 lg:flex-row'
  if (kind === 'wide') return 'mx-auto w-full max-w-6xl px-5 py-6'

  return 'mx-auto w-full max-w-5xl px-5 py-6'
}
</script>

<template>
  <main v-if="!ready" class="bg-background text-muted-foreground grid min-h-svh place-items-center">
    {{ t('common.loading') }}
  </main>

  <RouterView v-else-if="publicRoute" />

  <AuthenticatedLayout
    v-else-if="auth.user.value"
    :current-user="auth.user.value"
    :title="authenticatedPageTitle"
    :content-class="authenticatedContentClass"
    @sign-out="signOut"
  >
    <template #header-actions>
      <GlobalSearch @select-result="openSearchResult" />
    </template>

    <RouterView />
  </AuthenticatedLayout>

  <main v-else class="bg-background text-muted-foreground grid min-h-svh place-items-center">
    {{ t('common.loading') }}
  </main>

  <ToastViewport />
</template>
