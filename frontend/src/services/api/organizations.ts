import { request } from './client'
import type { Organization, OrganizationInput } from './types'

export const organizationsApi = {
  listOrganizations: () => request<Organization[]>('/api/v1/organizations'),
  createOrganization: (organization: OrganizationInput) =>
    request<Organization>('/api/v1/organizations', {
      method: 'POST',
      body: JSON.stringify({ organization }),
    }),
  updateOrganization: (organizationId: number, organization: OrganizationInput) =>
    request<Organization>(`/api/v1/organizations/${organizationId}`, {
      method: 'PATCH',
      body: JSON.stringify({ organization }),
    }),
  deleteOrganization: (organizationId: number) =>
    request<void>(`/api/v1/organizations/${organizationId}`, {
      method: 'DELETE',
    }),
}
