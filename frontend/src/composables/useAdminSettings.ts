import { shallowRef } from 'vue'
import { api, type AdminSettings, type AdminSettingsInput } from '@/services/api'

export function useAdminSettings() {
  const settings = shallowRef<AdminSettings | null>(null)
  const loading = shallowRef(false)
  const saving = shallowRef(false)
  const error = shallowRef<string | null>(null)

  async function loadSettings() {
    loading.value = true
    error.value = null

    try {
      settings.value = await api.getAdminSettings()
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load admin settings'
    } finally {
      loading.value = false
    }
  }

  async function updateSettings(input: AdminSettingsInput) {
    saving.value = true
    error.value = null

    try {
      settings.value = await api.updateAdminSettings(input)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to update admin settings'
      throw err
    } finally {
      saving.value = false
    }
  }

  return {
    settings,
    loading,
    saving,
    error,
    loadSettings,
    updateSettings,
  }
}
