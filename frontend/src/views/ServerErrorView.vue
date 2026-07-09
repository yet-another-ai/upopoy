<script setup lang="ts">
import { RefreshCcwIcon } from '@lucide/vue'
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'

const { t } = useI18n()

function reloadPage() {
  window.location.reload()
}
</script>

<template>
  <main class="bg-background text-foreground grid min-h-svh place-items-center px-5">
    <section class="grid w-full max-w-md gap-5 text-center">
      <div class="grid gap-2">
        <p class="text-muted-foreground text-sm font-medium">
          {{ t('serverError.status') }}
        </p>
        <h1 class="text-2xl font-semibold">
          {{ t('serverError.title') }}
        </h1>
        <p class="text-muted-foreground text-sm leading-6">
          {{ t('serverError.description') }}
        </p>
      </div>

      <div class="flex justify-center">
        <Button type="button" class="gap-2" @click="reloadPage">
          <RefreshCcwIcon class="size-4" />
          {{ t('serverError.retry') }}
        </Button>
      </div>
    </section>
  </main>
</template>
