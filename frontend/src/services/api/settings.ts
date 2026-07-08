import { request } from './client'
import type { AdminSettings, AdminSettingsInput, AuthSettings } from './types'

export const settingsApi = {
  getAuthSettings: () => request<AuthSettings>('/api/v1/auth/settings'),
  getAdminSettings: () => request<AdminSettings>('/api/v1/admin/settings'),
  updateAdminSettings: (settings: AdminSettingsInput) =>
    request<AdminSettings>('/api/v1/admin/settings', {
      method: 'PATCH',
      body: JSON.stringify({ settings }),
    }),
}
