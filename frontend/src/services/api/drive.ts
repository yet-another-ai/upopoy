import { request, requestBlob } from './client'
import type { DriveItem, DriveItemContent, DriveItemInput, DriveItemVersion } from './types'

function driveItemPath(projectId: number, parentId?: number | null) {
  const search = parentId == null ? '' : `?parent_id=${parentId}`
  return `/api/v1/projects/${projectId}/drive_items${search}`
}

export const driveApi = {
  listDriveItems: (projectId: number, parentId?: number | null) =>
    request<DriveItem[]>(driveItemPath(projectId, parentId)),
  getDriveItem: (driveItemId: number) =>
    request<DriveItem>(`/api/v1/drive_items/${driveItemId}`),
  createDriveItem: (projectId: number, driveItem: DriveItemInput) =>
    request<DriveItem>(`/api/v1/projects/${projectId}/drive_items`, {
      method: 'POST',
      body: JSON.stringify({ drive_item: driveItem }),
    }),
  uploadDriveFile: (
    projectId: number,
    file: File,
    input: { name?: string; parent_id?: number | null; base_version_number?: number | null } = {},
  ) => {
    const body = new FormData()
    body.set('drive_item[kind]', 'file')
    body.set('drive_item[file]', file)
    body.set('drive_item[base_version_number]', versionNumberFormValue(input.base_version_number))
    if (input.name) body.set('drive_item[name]', input.name)
    if (input.parent_id != null) body.set('drive_item[parent_id]', String(input.parent_id))

    return request<DriveItem>(`/api/v1/projects/${projectId}/drive_items`, {
      method: 'POST',
      body,
    })
  },
  updateDriveItem: (driveItemId: number, driveItem: Pick<DriveItemInput, 'name' | 'parent_id'>) =>
    request<DriveItem>(`/api/v1/drive_items/${driveItemId}`, {
      method: 'PATCH',
      body: JSON.stringify({ drive_item: driveItem }),
    }),
  deleteDriveItem: (driveItemId: number) =>
    request<void>(`/api/v1/drive_items/${driveItemId}`, {
      method: 'DELETE',
    }),
  getDriveItemContent: (driveItemId: number) =>
    request<DriveItemContent>(`/api/v1/drive_items/${driveItemId}/content`),
  updateDriveItemContent: (driveItemId: number, content: string, baseVersionNumber: number | null) =>
    request<DriveItemContent>(`/api/v1/drive_items/${driveItemId}/content`, {
      method: 'PATCH',
      body: JSON.stringify({ drive_item: { content, base_version_number: baseVersionNumber } }),
    }),
  updateDriveFile: (
    driveItemId: number,
    file: File,
    input: { name?: string; base_version_number: number | null },
  ) => {
    const body = new FormData()
    body.set('drive_item[file]', file)
    body.set('drive_item[base_version_number]', versionNumberFormValue(input.base_version_number))
    if (input.name) body.set('drive_item[name]', input.name)

    return request<DriveItem>(`/api/v1/drive_items/${driveItemId}/file`, {
      method: 'PATCH',
      body,
    })
  },
  listDriveItemVersions: (driveItemId: number) =>
    request<DriveItemVersion[]>(`/api/v1/drive_items/${driveItemId}/versions`),
  getDriveItemVersionContent: (versionId: number) =>
    request<DriveItemContent>(`/api/v1/drive_item_versions/${versionId}/content`),
  restoreDriveItemVersion: (versionId: number) =>
    request<DriveItem>(`/api/v1/drive_item_versions/${versionId}/restore`, {
      method: 'POST',
    }),
  downloadDriveItemVersion: (versionId: number) =>
    requestBlob(`/api/v1/drive_item_versions/${versionId}/download`),
  downloadDriveItem: (driveItemId: number) => requestBlob(`/api/v1/drive_items/${driveItemId}/download`),
}

function versionNumberFormValue(versionNumber: number | null | undefined) {
  return versionNumber == null ? '' : String(versionNumber)
}
