<script setup lang="ts">
import { AlertCircleIcon, CheckCircle2Icon, InfoIcon, XIcon } from '@lucide/vue'
import { computed, type Component } from 'vue'
import { Button } from '@/components/ui/button'
import { useToastsStore, type ToastMessage, type ToastVariant } from '@/stores/toasts'

const toastsStore = useToastsStore()

const variantStyles: Record<ToastVariant, string> = {
  success:
    'border-emerald-200 bg-emerald-50 text-emerald-950 dark:border-emerald-900 dark:bg-emerald-950 dark:text-emerald-50',
  error:
    'border-destructive/30 bg-destructive/10 text-foreground dark:border-destructive/50 dark:bg-destructive/20',
  info: 'border-border bg-popover text-popover-foreground',
}

const variantIcons: Record<ToastVariant, Component> = {
  success: CheckCircle2Icon,
  error: AlertCircleIcon,
  info: InfoIcon,
}

const toasts = computed(() => toastsStore.toasts)

function toastClass(toast: ToastMessage) {
  return variantStyles[toast.variant]
}

function toastIcon(toast: ToastMessage) {
  return variantIcons[toast.variant]
}
</script>

<template>
  <div
    v-if="toasts.length"
    class="pointer-events-none fixed right-4 bottom-4 z-[80] grid w-[min(24rem,calc(100vw-2rem))] gap-2"
    aria-live="polite"
    aria-atomic="false"
  >
    <div
      v-for="toast in toasts"
      :key="toast.id"
      role="status"
      class="pointer-events-auto grid grid-cols-[auto_minmax(0,1fr)_auto] gap-3 rounded-lg border p-3 shadow-lg"
      :class="toastClass(toast)"
    >
      <component :is="toastIcon(toast)" class="mt-0.5 size-4 shrink-0" aria-hidden="true" />
      <div class="min-w-0">
        <p class="truncate text-sm font-medium" :title="toast.title">{{ toast.title }}</p>
        <p
          v-if="toast.description"
          class="text-muted-foreground mt-0.5 line-clamp-2 text-xs"
          :title="toast.description"
        >
          {{ toast.description }}
        </p>
      </div>
      <Button
        type="button"
        size="icon-sm"
        variant="ghost"
        aria-label="Dismiss notification"
        @click="toastsStore.dismissToast(toast.id)"
      >
        <XIcon class="size-3.5" />
      </Button>
    </div>
  </div>
</template>
