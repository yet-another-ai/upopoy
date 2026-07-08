import { acceptHMRUpdate, defineStore } from 'pinia'
import { shallowRef } from 'vue'

export type ToastVariant = 'success' | 'error' | 'info'

export interface ToastMessage {
  id: number
  title: string
  description?: string
  variant: ToastVariant
}

interface AddToastInput {
  title: string
  description?: string
  variant?: ToastVariant
  durationMs?: number
}

export const useToastsStore = defineStore('toasts', () => {
  const toasts = shallowRef<ToastMessage[]>([])
  let nextToastId = 1
  const timers = new Map<number, ReturnType<typeof setTimeout>>()

  function addToast(input: AddToastInput) {
    const id = nextToastId
    nextToastId += 1

    const toast: ToastMessage = {
      id,
      title: input.title,
      description: input.description,
      variant: input.variant ?? 'info',
    }

    toasts.value = [toast, ...toasts.value].slice(0, 4)

    const durationMs = input.durationMs ?? (toast.variant === 'error' ? 6000 : 4000)
    timers.set(
      id,
      setTimeout(() => {
        dismissToast(id)
      }, durationMs),
    )

    return id
  }

  function success(title: string, description?: string) {
    return addToast({ title, description, variant: 'success' })
  }

  function error(title: string, description?: string) {
    return addToast({ title, description, variant: 'error' })
  }

  function info(title: string, description?: string) {
    return addToast({ title, description, variant: 'info' })
  }

  function dismissToast(id: number) {
    const timer = timers.get(id)
    if (timer) clearTimeout(timer)

    timers.delete(id)
    toasts.value = toasts.value.filter((toast) => toast.id !== id)
  }

  function clearToasts() {
    for (const timer of timers.values()) clearTimeout(timer)

    timers.clear()
    toasts.value = []
  }

  return {
    toasts,
    addToast,
    success,
    error,
    info,
    dismissToast,
    clearToasts,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useToastsStore, import.meta.hot))
}
