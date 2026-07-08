<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { onMounted, shallowRef, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import AuthForm from '@/components/auth/AuthForm.vue'
import { useAuthStore } from '@/stores/auth'
import { useProjectsStore } from '@/stores/projects'
import { useUserGroupsStore } from '@/stores/userGroups'
import { api, type AuthInput, type AuthProvider, type AuthSettings } from '@/services/api'

const authStore = useAuthStore()
const projectsStore = useProjectsStore()
const userGroupsStore = useUserGroupsStore()
const auth = storeToRefs(authStore)
const router = useRouter()
const { t } = useI18n()
const mode = shallowRef<'login' | 'signup'>('login')
const providers = shallowRef<AuthProvider[]>([])
const authSettings = shallowRef<AuthSettings>({
  registration_enabled: true,
  email_login_enabled: true,
})

function submitAuth(input: AuthInput) {
  if (!authSettings.value.email_login_enabled) return
  if (mode.value === 'signup' && !authSettings.value.registration_enabled) return

  void authenticate(input)
}

function changeMode(nextMode: 'login' | 'signup') {
  if (nextMode === 'signup' && !authSettings.value.registration_enabled) return

  mode.value = nextMode
}

onMounted(async () => {
  try {
    const [settings, authProviders] = await Promise.all([
      api.getAuthSettings(),
      api.listAuthProviders(),
    ])
    authSettings.value = settings
    providers.value = authProviders
  } catch {
    providers.value = []
  }
})

watch(
  () => authSettings.value.registration_enabled,
  (registrationEnabled) => {
    if (!registrationEnabled && mode.value === 'signup') mode.value = 'login'
  },
)

async function authenticate(input: AuthInput) {
  if (mode.value === 'login') await authStore.login(input)
  else await authStore.signUp(input)

  await router.push({ name: 'home' })
  await projectsStore.loadProjects()
  await userGroupsStore.loadGroups()
}
</script>

<template>
  <main class="bg-background text-foreground grid min-h-svh place-items-center p-6">
    <div class="grid w-full max-w-sm gap-5">
      <div class="grid gap-1">
        <p class="text-muted-foreground text-xs font-medium tracking-wider uppercase">upopoy</p>
        <h1 class="text-2xl font-semibold">{{ t('auth.workspaceAccess') }}</h1>
      </div>

      <AuthForm
        :mode="mode"
        :loading="auth.loading.value"
        :error="auth.error.value"
        :providers="providers"
        :registration-enabled="authSettings.registration_enabled"
        :email-login-enabled="authSettings.email_login_enabled"
        @submit="submitAuth"
        @change-mode="changeMode"
      />
    </div>
  </main>
</template>
