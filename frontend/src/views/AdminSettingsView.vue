<script setup lang="ts">
import { onMounted } from 'vue'
import AuthSettingsForm from '@/components/admin-settings/AuthSettingsForm.vue'
import { useAdminSettings } from '@/composables/useAdminSettings'
import { useToastsStore } from '@/stores/toasts'
import type { AdminSettingsInput } from '@/services/api'

const adminSettings = useAdminSettings()
const toasts = useToastsStore()

onMounted(() => {
  void adminSettings.loadSettings()
})

async function saveSettings(input: AdminSettingsInput) {
  try {
    await adminSettings.updateSettings(input)
  } catch (err) {
    toasts.error(
      'Unable to update admin settings',
      err instanceof Error ? err.message : 'Unable to update admin settings',
    )
  }
}
</script>

<template>
  <div class="grid gap-5">
    <div class="grid gap-1">
      <h2 class="text-2xl font-semibold">Admin Settings</h2>
      <p class="text-muted-foreground text-sm">Configure workspace authentication options.</p>
    </div>

    <AuthSettingsForm
      :settings="adminSettings.settings.value"
      :loading="adminSettings.loading.value"
      :saving="adminSettings.saving.value"
      @save="saveSettings"
    />

    <p v-if="adminSettings.error.value" role="alert" class="text-destructive text-sm">
      {{ adminSettings.error.value }}
    </p>
  </div>
</template>
