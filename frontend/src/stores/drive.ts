import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, shallowRef } from 'vue'
import { api, type DriveItem, type DriveItemInput, type DriveItemVersion } from '@/services/api'

export const useDriveStore = defineStore('drive', () => {
  const items = shallowRef<DriveItem[]>([])
  const breadcrumbs = shallowRef<DriveItem[]>([])
  const loading = shallowRef(false)
  const saving = shallowRef(false)
  const error = shallowRef<string | null>(null)
  const versions = shallowRef<DriveItemVersion[]>([])

  const currentParentId = computed(() => breadcrumbs.value.at(-1)?.id ?? null)
  const folders = computed(() => items.value.filter((item) => item.kind === 'folder'))

  async function loadItems(projectId: number, parentId: number | null = currentParentId.value) {
    loading.value = true
    error.value = null

    try {
      items.value = await api.listDriveItems(projectId, parentId)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to load drive'
    } finally {
      loading.value = false
    }
  }

  async function openFolder(projectId: number, folder: DriveItem) {
    breadcrumbs.value = [...breadcrumbs.value, folder]
    await loadItems(projectId, folder.id)
  }

  async function navigateTo(projectId: number, index: number) {
    breadcrumbs.value = index < 0 ? [] : breadcrumbs.value.slice(0, index + 1)
    await loadItems(projectId, currentParentId.value)
  }

  async function createFolder(projectId: number, name: string) {
    return createItem(projectId, { kind: 'folder', name, parent_id: currentParentId.value, base_version_number: null })
  }

  async function createMarkdown(projectId: number, name: string, content = '') {
    return createItem(projectId, { kind: 'file', name, content, parent_id: currentParentId.value, base_version_number: null })
  }

  async function createItem(projectId: number, input: DriveItemInput) {
    saving.value = true
    try {
      const item = await api.createDriveItem(projectId, input)
      items.value = sortItems([...items.value, item])
      return item
    } finally {
      saving.value = false
    }
  }

  async function loadItem(itemId: number) {
    return api.getDriveItem(itemId)
  }

  async function uploadFile(projectId: number, file: File) {
    saving.value = true
    try {
      const item = await api.uploadDriveFile(projectId, file, {
        parent_id: currentParentId.value,
        base_version_number: null,
      })
      items.value = sortItems([...items.value, item])
      return item
    } finally {
      saving.value = false
    }
  }

  async function renameItem(item: DriveItem, name: string) {
    const updated = await api.updateDriveItem(item.id, { name, parent_id: item.parent_id })
    replaceItem(updated)
    return updated
  }

  async function moveItem(item: DriveItem, parentId: number | null) {
    const updated = await api.updateDriveItem(item.id, { name: item.name, parent_id: parentId })
    items.value = items.value.filter((existing) => existing.id !== updated.id)
    return updated
  }

  async function deleteItem(item: DriveItem) {
    await api.deleteDriveItem(item.id)
    items.value = items.value.filter((existing) => existing.id !== item.id)
  }

  async function loadContent(item: DriveItem) {
    return (await api.getDriveItemContent(item.id)).content
  }

  async function saveContent(item: DriveItem, content: string) {
    await api.updateDriveItemContent(item.id, content, item.latest_version_number)
    const updated = {
      ...item,
      text_content_cache: content,
      versions_count: item.versions_count + 1,
      latest_version_number: (item.latest_version_number ?? 0) + 1,
      updated_at: new Date().toISOString(),
    }
    replaceItem(updated)
    versions.value = await api.listDriveItemVersions(item.id)
    return updated
  }

  async function downloadItem(item: DriveItem) {
    return api.downloadDriveItem(item.id)
  }

  async function loadVersions(item: DriveItem) {
    versions.value = await api.listDriveItemVersions(item.id)
    return versions.value
  }

  async function restoreVersion(version: DriveItemVersion) {
    const item = await api.restoreDriveItemVersion(version.id)
    replaceItem(item)
    versions.value = await api.listDriveItemVersions(item.id)
    return item
  }

  async function loadVersionContent(version: DriveItemVersion) {
    return (await api.getDriveItemVersionContent(version.id)).content
  }

  async function uploadNewVersion(item: DriveItem, file: File) {
    const updated = await api.updateDriveFile(item.id, file, { base_version_number: item.latest_version_number })
    replaceItem(updated)
    versions.value = await api.listDriveItemVersions(item.id)
    return updated
  }

  function replaceItem(item: DriveItem) {
    items.value = sortItems(items.value.map((existing) => (existing.id === item.id ? item : existing)))
  }

  function clearDrive() {
    items.value = []
    breadcrumbs.value = []
    versions.value = []
    error.value = null
  }

  return {
    items,
    folders,
    breadcrumbs,
    currentParentId,
    versions,
    loading,
    saving,
    error,
    loadItems,
    loadItem,
    openFolder,
    navigateTo,
    createFolder,
    createMarkdown,
    uploadFile,
    renameItem,
    moveItem,
    deleteItem,
    loadContent,
    saveContent,
    downloadItem,
    loadVersions,
    restoreVersion,
    loadVersionContent,
    uploadNewVersion,
    clearDrive,
  }
})

function sortItems(items: DriveItem[]) {
  return [...items].sort((a, b) => {
    if (a.kind !== b.kind) return a.kind === 'folder' ? -1 : 1

    return a.name.localeCompare(b.name)
  })
}

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useDriveStore, import.meta.hot))
}
