<script setup lang="ts">
import { onMounted, shallowRef } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useProjectsStore } from '@/stores/projects'
import { useOrganizationsStore } from '@/stores/organizations'

const authStore = useAuthStore()
const projectsStore = useProjectsStore()
const organizationsStore = useOrganizationsStore()
const router = useRouter()
const { t } = useI18n()
const message = shallowRef(t('auth.finishingSignIn'))

onMounted(async () => {
  const params = new URLSearchParams(window.location.hash.replace(/^#/, ''))
  const token = params.get('token')
  const error = params.get('error')

  window.history.replaceState({}, document.title, window.location.pathname)

  if (token) {
    await authStore.acceptToken(token)
    await router.push({ name: 'home' })
    await projectsStore.loadProjects()
    await organizationsStore.loadOrganizations()
    return
  }

  message.value = error ?? t('auth.missingToken')
  authStore.failAuthentication(message.value)
  await router.replace({ name: 'auth' })
})
</script>

<template>
  <main class="bg-background text-muted-foreground grid min-h-svh place-items-center">
    {{ message }}
  </main>
</template>
