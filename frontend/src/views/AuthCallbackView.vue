<script setup lang="ts">
import { onMounted, shallowRef } from 'vue'

const emit = defineEmits<{
  complete: [token: string]
  failed: [message: string]
}>()

const message = shallowRef('Finishing sign in...')

onMounted(() => {
  const params = new URLSearchParams(window.location.hash.replace(/^#/, ''))
  const token = params.get('token')
  const error = params.get('error')

  window.history.replaceState({}, document.title, window.location.pathname)

  if (token) {
    emit('complete', token)
    return
  }

  message.value = error ?? 'Authentication did not return a token.'
  emit('failed', message.value)
})
</script>

<template>
  <main class="bg-background text-muted-foreground grid min-h-svh place-items-center">
    {{ message }}
  </main>
</template>
