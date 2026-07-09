import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useDriveStore } from '../drive'
import { api, type DriveItem } from '@/services/api'

vi.mock('@/services/api', () => ({
  api: {
    listDriveItems: vi.fn(),
    getDriveItem: vi.fn(),
    createDriveItem: vi.fn(),
    uploadDriveFile: vi.fn(),
    updateDriveItem: vi.fn(),
    deleteDriveItem: vi.fn(),
    getDriveItemContent: vi.fn(),
    updateDriveItemContent: vi.fn(),
    downloadDriveItem: vi.fn(),
    listDriveItemVersions: vi.fn(),
    getDriveItemVersionContent: vi.fn(),
    restoreDriveItemVersion: vi.fn(),
    updateDriveFile: vi.fn(),
  },
}))

const folder: DriveItem = {
  id: 1,
  project_id: 1,
  parent_id: null,
  kind: 'folder',
  name: 'Specs',
  text_content_cache: '',
  markdown: false,
  content_type: null,
  byte_size: null,
  download_path: null,
  deleted_at: null,
  versions_count: 0,
  latest_version_number: null,
  created_at: '2026-07-09T00:00:00Z',
  updated_at: '2026-07-09T00:00:00Z',
}

const markdown: DriveItem = {
  id: 2,
  project_id: 1,
  parent_id: null,
  kind: 'file',
  name: 'Notes.md',
  text_content_cache: '# Notes',
  markdown: true,
  content_type: 'text/markdown',
  byte_size: 7,
  download_path: '/api/v1/drive_items/2/download',
  deleted_at: null,
  versions_count: 1,
  latest_version_number: 1,
  created_at: '2026-07-09T00:00:00Z',
  updated_at: '2026-07-09T00:00:00Z',
}

describe('useDriveStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('loads drive items and derives folders', async () => {
    vi.mocked(api.listDriveItems).mockResolvedValue([markdown, folder])
    const store = useDriveStore()

    await store.loadItems(1)

    expect(store.items.map((item) => item.name)).toEqual(['Notes.md', 'Specs'])
    expect(store.folders).toEqual([folder])
  })

  it('opens folders and tracks breadcrumbs', async () => {
    vi.mocked(api.listDriveItems).mockResolvedValue([])
    const store = useDriveStore()

    await store.openFolder(1, folder)

    expect(api.listDriveItems).toHaveBeenCalledWith(1, folder.id)
    expect(store.currentParentId).toBe(folder.id)
    expect(store.breadcrumbs.map((item) => item.name)).toEqual(['Specs'])
  })

  it('creates folders in the current folder', async () => {
    vi.mocked(api.listDriveItems).mockResolvedValue([])
    vi.mocked(api.createDriveItem).mockResolvedValue({ ...folder, id: 3, parent_id: folder.id, name: 'API' })
    const store = useDriveStore()

    await store.openFolder(1, folder)
    await store.createFolder(1, 'API')

    expect(api.createDriveItem).toHaveBeenCalledWith(1, {
      kind: 'folder',
      name: 'API',
      parent_id: folder.id,
      base_version_number: null,
    })
    expect(store.items.map((item) => item.name)).toEqual(['API'])
  })

  it('moves items out of the current list', async () => {
    vi.mocked(api.listDriveItems).mockResolvedValue([markdown])
    vi.mocked(api.updateDriveItem).mockResolvedValue({ ...markdown, parent_id: folder.id })
    const store = useDriveStore()

    await store.loadItems(1)
    await store.moveItem(markdown, folder.id)

    expect(store.items).toEqual([])
  })

  it('loads and saves markdown content', async () => {
    vi.mocked(api.getDriveItemContent).mockResolvedValue({ content: '# Notes' })
    vi.mocked(api.updateDriveItemContent).mockResolvedValue({ content: '# Updated' })
    vi.mocked(api.listDriveItemVersions).mockResolvedValue([])
    const store = useDriveStore()

    await expect(store.loadContent(markdown)).resolves.toBe('# Notes')
    await store.saveContent(markdown, '# Updated')

    expect(api.updateDriveItemContent).toHaveBeenCalledWith(markdown.id, '# Updated', markdown.latest_version_number)
  })
})
