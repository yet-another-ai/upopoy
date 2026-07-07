<script setup lang="ts">
import { computed, reactive } from 'vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import type { AuthInput, AuthProvider } from '@/services/api'

const props = defineProps<{
  mode: 'login' | 'signup'
  loading: boolean
  error: string | null
  providers: readonly AuthProvider[]
  registrationEnabled: boolean
  emailLoginEnabled: boolean
}>()

const emit = defineEmits<{
  submit: [input: AuthInput]
  changeMode: [mode: 'login' | 'signup']
}>()

const form = reactive({
  email: '',
  password: '',
  passwordConfirmation: '',
})

const title = computed(() => (props.mode === 'login' ? 'Sign in' : 'Create account'))
const submitLabel = computed(() => (props.mode === 'login' ? 'Sign in' : 'Create account'))
const alternateLabel = computed(() =>
  props.mode === 'login' ? 'Create an account' : 'Use an existing account',
)
const alternateMode = computed(() => (props.mode === 'login' ? 'signup' : 'login'))
const showAlternateMode = computed(() => props.registrationEnabled || props.mode === 'signup')
const showEmailForm = computed(() => props.emailLoginEnabled)
const passwordConfirmationMismatch = computed(
  () =>
    props.mode === 'signup' &&
    Boolean(form.passwordConfirmation) &&
    form.password !== form.passwordConfirmation,
)

function submitForm() {
  if (!showEmailForm.value) return
  if (!form.email.trim() || !form.password) return
  if (props.mode === 'signup' && !props.registrationEnabled) return
  if (props.mode === 'signup' && form.password !== form.passwordConfirmation) return

  emit('submit', {
    email: form.email.trim(),
    password: form.password,
    password_confirmation: props.mode === 'signup' ? form.passwordConfirmation : undefined,
  })
}
</script>

<template>
  <Card class="w-full max-w-sm rounded-lg shadow-none">
    <CardHeader>
      <CardTitle>{{ title }}</CardTitle>
    </CardHeader>
    <CardContent>
      <form v-if="showEmailForm" class="grid gap-4" @submit.prevent="submitForm">
        <div class="grid gap-1.5">
          <Label for="auth-email">Email</Label>
          <Input
            id="auth-email"
            v-model="form.email"
            type="email"
            autocomplete="email"
            placeholder="you@example.com"
          />
        </div>

        <div class="grid gap-1.5">
          <Label for="auth-password">Password</Label>
          <Input
            id="auth-password"
            v-model="form.password"
            type="password"
            :autocomplete="props.mode === 'login' ? 'current-password' : 'new-password'"
          />
        </div>

        <div v-if="props.mode === 'signup'" class="grid gap-1.5">
          <Label for="auth-password-confirmation">Confirm password</Label>
          <Input
            id="auth-password-confirmation"
            v-model="form.passwordConfirmation"
            type="password"
            autocomplete="new-password"
          />
        </div>

        <p
          v-if="props.error || passwordConfirmationMismatch"
          role="alert"
          class="text-destructive text-sm"
        >
          {{ props.error ?? 'Password confirmation must match the password.' }}
        </p>

        <Button type="submit" :disabled="props.loading">
          {{ props.loading ? 'Working...' : submitLabel }}
        </Button>

        <Button
          v-if="showAlternateMode"
          type="button"
          variant="ghost"
          :disabled="props.loading"
          @click="emit('changeMode', alternateMode)"
        >
          {{ alternateLabel }}
        </Button>
      </form>

      <div v-if="props.providers.length" :class="showEmailForm ? 'mt-4 grid gap-3' : 'grid gap-3'">
        <div v-if="showEmailForm" class="flex items-center gap-3">
          <div class="bg-border h-px flex-1" />
          <span class="text-muted-foreground text-xs">or</span>
          <div class="bg-border h-px flex-1" />
        </div>

        <Button
          v-for="provider in props.providers"
          :key="provider.name"
          as="a"
          variant="outline"
          :href="provider.authorize_path"
          :aria-label="`Continue with ${provider.label}`"
        >
          Continue with {{ provider.label }}
        </Button>
      </div>

      <p v-else-if="!showEmailForm" class="text-muted-foreground text-sm">
        Email login is disabled and no OAuth providers are configured.
      </p>
    </CardContent>
  </Card>
</template>
