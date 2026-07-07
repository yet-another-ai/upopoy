<script setup lang="ts">
import { onMounted, shallowRef, watch } from 'vue'
import AuthForm from '@/components/auth/AuthForm.vue'
import { api, type AuthInput, type AuthProvider, type AuthSettings } from '@/services/api'

defineProps<{
  loading: boolean
  error: string | null
}>()

const emit = defineEmits<{
  login: [input: AuthInput]
  signup: [input: AuthInput]
}>()

const mode = shallowRef<'login' | 'signup'>('login')
const providers = shallowRef<AuthProvider[]>([])
const authSettings = shallowRef<AuthSettings>({
  registration_enabled: true,
  email_login_enabled: true,
})

function submitAuth(input: AuthInput) {
  if (!authSettings.value.email_login_enabled) return
  if (mode.value === 'signup' && !authSettings.value.registration_enabled) return

  if (mode.value === 'login') emit('login', input)
  else emit('signup', input)
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
</script>

<template>
  <main class="bg-background text-foreground grid min-h-svh place-items-center p-6">
    <div class="grid w-full max-w-sm gap-5">
      <div class="grid gap-1">
        <p class="text-muted-foreground text-xs font-medium tracking-wider uppercase">upopoy</p>
        <h1 class="text-2xl font-semibold">Workspace access</h1>
      </div>

      <AuthForm
        :mode="mode"
        :loading="loading"
        :error="error"
        :providers="providers"
        :registration-enabled="authSettings.registration_enabled"
        :email-login-enabled="authSettings.email_login_enabled"
        @submit="submitAuth"
        @change-mode="changeMode"
      />
    </div>
  </main>
</template>
