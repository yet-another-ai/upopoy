<script setup lang="ts">
import { onMounted } from 'vue'
import AuthSettingsForm from '@/components/admin-settings/AuthSettingsForm.vue'
import { useAdminSettings } from '@/composables/useAdminSettings'
import type { AdminSettingsInput } from '@/services/api'

const adminSettings = useAdminSettings()

onMounted(() => {
  void adminSettings.loadSettings()
})

async function saveSettings(input: AdminSettingsInput) {
  await adminSettings.updateSettings(input)
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
