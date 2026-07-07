<script setup lang="ts">
import { onMounted, shallowRef } from 'vue'
import AuthForm from '@/components/auth/AuthForm.vue'
import { api, type AuthInput, type AuthProvider } from '@/services/api'

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

function submitAuth(input: AuthInput) {
  if (mode.value === 'login') emit('login', input)
  else emit('signup', input)
}

onMounted(async () => {
  try {
    providers.value = await api.listAuthProviders()
  } catch {
    providers.value = []
  }
})
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
        @submit="submitAuth"
        @change-mode="mode = $event"
      />
    </div>
  </main>
</template>
