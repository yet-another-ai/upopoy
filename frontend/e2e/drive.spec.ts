import { expect, test, type Page, type Route } from '@playwright/test'

interface ProjectPayload {
  id: number
  owner_type: 'User' | 'Organization'
  owner_id: number
  owner_name: string
  name: string
  description: string | null
  created_at: string
  updated_at: string
}

interface DriveItemPayload {
  id: number
  project_id: number
  parent_id: number | null
  kind: 'folder' | 'file'
  name: string
  text_content_cache: string
  markdown: boolean
  content_type: string | null
  byte_size: number | null
  download_path: string | null
  deleted_at: string | null
  versions_count: number
  latest_version_number: number | null
  created_at: string
  updated_at: string
}

interface DriveItemVersionPayload {
  id: number
  drive_item_id: number
  version_number: number
  name: string
  content_type: string | null
  byte_size: number | null
  text_content_cache: string
  markdown: boolean
  download_path: string
  created_at: string
  updated_at: string
}

const timestamp = '2026-07-09T00:00:00Z'
const authToken = 'Bearer e2e-token'

async function json(route: Route, body: unknown, status = 200, headers: Record<string, string> = {}) {
  await route.fulfill({
    status,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: JSON.stringify(body),
  })
}

async function installMockApi(page: Page) {
  let nextDriveItemId = 10
  let nextVersionId = 100
  const contents = new Map<number, string>()
  const project: ProjectPayload = {
    id: 1,
    owner_type: 'Organization',
    owner_id: 1,
    owner_name: 'Engineering',
    name: 'MVP',
    description: 'Initial workspace',
    created_at: timestamp,
    updated_at: timestamp,
  }
  let driveItems: DriveItemPayload[] = []
  const versions: DriveItemVersionPayload[] = []

  function isAuthorized(route: Route) {
    return route.request().headers().authorization === authToken
  }

  async function requireAuth(route: Route) {
    if (isAuthorized(route)) return true

    await json(route, { error: 'You need to sign in or sign up before continuing.' }, 401)
    return false
  }

  function driveItemPayload(input: Partial<DriveItemPayload> & Pick<DriveItemPayload, 'kind' | 'name'>) {
    const item: DriveItemPayload = {
      id: nextDriveItemId++,
      project_id: 1,
      parent_id: input.parent_id ?? null,
      kind: input.kind,
      name: input.name,
      text_content_cache: input.text_content_cache ?? '',
      markdown: input.kind === 'file' && /\.(md|markdown)$/i.test(input.name),
      content_type: input.content_type ?? (input.kind === 'file' ? 'text/markdown' : null),
      byte_size: input.byte_size ?? (input.kind === 'file' ? input.text_content_cache?.length ?? 0 : null),
      download_path: input.kind === 'file' ? `/api/v1/drive_items/${nextDriveItemId - 1}/download` : null,
      deleted_at: null,
      versions_count: 0,
      latest_version_number: null,
      created_at: timestamp,
      updated_at: timestamp,
    }
    driveItems.push(item)
    if (item.markdown) contents.set(item.id, item.text_content_cache)
    if (item.kind === 'file') recordVersion(item)
    return item
  }

  function recordVersion(item: DriveItemPayload) {
    const versionNumber = (item.latest_version_number ?? 0) + 1
    item.latest_version_number = versionNumber
    item.versions_count += 1
    versions.push({
      id: nextVersionId++,
      drive_item_id: item.id,
      version_number: versionNumber,
      name: item.name,
      content_type: item.content_type,
      byte_size: item.text_content_cache.length,
      text_content_cache: item.text_content_cache,
      markdown: item.markdown,
      download_path: `/api/v1/drive_item_versions/${nextVersionId - 1}/download`,
      created_at: timestamp,
      updated_at: timestamp,
    })
  }

  await page.route('**/api/v1/auth/providers', async (route) => {
    await json(route, [
      {
        name: 'developer',
        label: 'Developer',
        authorize_path: '/api/v1/auth/developer',
      },
    ])
  })

  await page.route('**/api/v1/auth/settings', async (route) => {
    await json(route, {
      registration_enabled: true,
      email_login_enabled: true,
    })
  })

  await page.route('**/api/v1/auth/signup', async (route) => {
    await json(
      route,
      {
        user: {
          id: 1,
          email: 'founder@example.com',
          display_name: null,
          title: null,
          bio: null,
          system_admin: true,
          created_at: timestamp,
          updated_at: timestamp,
        },
      },
      201,
      { Authorization: authToken },
    )
  })

  await page.route('**/api/v1/auth/me', async (route) => {
    if (!(await requireAuth(route))) return

    await json(route, {
      user: {
        id: 1,
        email: 'founder@example.com',
        display_name: null,
        title: null,
        bio: null,
        system_admin: true,
        created_at: timestamp,
        updated_at: timestamp,
      },
    })
  })

  await page.route('**/api/v1/projects', async (route) => {
    if (!(await requireAuth(route))) return

    await json(route, [project])
  })

  await page.route('**/api/v1/organizations', async (route) => {
    if (!(await requireAuth(route))) return

    await json(route, [])
  })

  await page.route('**/api/v1/search**', async (route) => {
    if (!(await requireAuth(route))) return

    await json(route, { results: [] })
  })

  await page.route('**/api/v1/projects/1/drive_items**', async (route) => {
    if (!(await requireAuth(route))) return

    if (route.request().method() === 'GET') {
      const url = new URL(route.request().url())
      const parentId = url.searchParams.get('parent_id')
      await json(
        route,
        driveItems.filter((item) => item.parent_id === (parentId ? Number(parentId) : null)),
      )
      return
    }

    const contentType = route.request().headers()['content-type'] ?? ''
    if (contentType.includes('multipart/form-data')) {
      await json(route, driveItemPayload({ kind: 'file', name: 'Upload.md', text_content_cache: '# Upload' }), 201)
      return
    }

    const requestBody = route.request().postDataJSON() as {
      drive_item: {
        kind: DriveItemPayload['kind']
        name?: string
        parent_id?: number | null
        content?: string
        base_version_number?: number | null
      }
    }
    await json(
      route,
      driveItemPayload({
        kind: requestBody.drive_item.kind,
        name: requestBody.drive_item.name ?? 'Untitled.md',
        parent_id: requestBody.drive_item.parent_id ?? null,
        text_content_cache: requestBody.drive_item.content ?? '',
      }),
      201,
    )
  })

  await page.route('**/api/v1/drive_items/*/content', async (route) => {
    if (!(await requireAuth(route))) return

    const itemId = Number(route.request().url().split('/').at(-2))
    const item = driveItems.find((driveItem) => driveItem.id === itemId)
    if (!item) {
      await json(route, { error: 'Not found' }, 404)
      return
    }

    if (route.request().method() === 'GET') {
      await json(route, { content: contents.get(itemId) ?? '' })
      return
    }

    const requestBody = route.request().postDataJSON() as {
      drive_item: { content: string; base_version_number: number | null }
    }
    if (requestBody.drive_item.base_version_number !== item.latest_version_number) {
      await json(route, { errors: { base_version_number: ['does not match current version'] } }, 409)
      return
    }
    contents.set(itemId, requestBody.drive_item.content)
    item.text_content_cache = requestBody.drive_item.content
    recordVersion(item)
    await json(route, { content: requestBody.drive_item.content })
  })

  await page.route('**/api/v1/drive_items/*/versions', async (route) => {
    if (!(await requireAuth(route))) return

    const itemId = Number(route.request().url().split('/').at(-2))
    await json(
      route,
      versions
        .filter((version) => version.drive_item_id === itemId)
        .sort((a, b) => b.version_number - a.version_number),
    )
  })

  await page.route('**/api/v1/drive_item_versions/*/restore', async (route) => {
    if (!(await requireAuth(route))) return

    const versionId = Number(route.request().url().split('/').at(-2))
    const version = versions.find((itemVersion) => itemVersion.id === versionId)
    const item = driveItems.find((driveItem) => driveItem.id === version?.drive_item_id)
    if (!version || !item) {
      await json(route, { error: 'Not found' }, 404)
      return
    }

    item.text_content_cache = version.text_content_cache
    contents.set(item.id, version.text_content_cache)
    recordVersion(item)
    await json(route, item)
  })

  await page.route('**/api/v1/drive_items/*', async (route) => {
    if (!(await requireAuth(route))) return

    const itemId = Number(route.request().url().split('/').at(-1))
    const item = driveItems.find((driveItem) => driveItem.id === itemId)
    if (!item) {
      await json(route, { error: 'Not found' }, 404)
      return
    }

    if (route.request().method() === 'GET') {
      await json(route, item)
      return
    }

    if (route.request().method() === 'DELETE') {
      const removeIds = new Set<number>([item.id])
      let changed = true
      while (changed) {
        changed = false
        for (const driveItem of driveItems) {
          if (driveItem.parent_id && removeIds.has(driveItem.parent_id) && !removeIds.has(driveItem.id)) {
            removeIds.add(driveItem.id)
            changed = true
          }
        }
      }
      driveItems = driveItems.filter((driveItem) => !removeIds.has(driveItem.id))
      await route.fulfill({ status: 204 })
      return
    }

    const requestBody = route.request().postDataJSON() as {
      drive_item: { name?: string; parent_id?: number | null }
    }
    item.name = requestBody.drive_item.name ?? item.name
    item.parent_id = requestBody.drive_item.parent_id ?? null
    await json(route, item)
  })
}

test('manages project drive files and markdown documents', async ({ page }) => {
  await installMockApi(page)

  await page.goto('/')
  await expect(page).toHaveURL('/login')
  await page.getByRole('button', { name: 'Create an account' }).click()
  await page.getByLabel('Email').fill('founder@example.com')
  await page.getByLabel('Password', { exact: true }).fill('password123')
  await page.getByLabel('Confirm password', { exact: true }).fill('password123')
  await page.getByRole('button', { name: 'Create account' }).click()

  await expect(page).toHaveURL('/')
  await page.getByRole('link', { name: 'Open Drive' }).click()
  await expect(page).toHaveURL('/drive')
  await expect(page.getByRole('navigation', { name: 'Drive app' }).getByRole('button', { name: 'Drive' })).toBeVisible()
  await expect(page.getByRole('navigation', { name: 'Drive app' }).getByRole('button', { name: 'Kanban' })).toHaveCount(0)
  await expect(page.getByLabel('Drive folders').getByRole('button', { name: 'Drive' })).toBeVisible()
  const driveListBox = await page.getByLabel('Drive file list').boundingBox()
  expect(driveListBox?.width).toBeGreaterThan(700)

  await page.getByLabel('Drive file list').click({ button: 'right', position: { x: 16, y: 180 } })
  await page.getByRole('menuitem', { name: 'New folder' }).click()
  await page.getByLabel('Name').fill('Specs')
  await page.getByRole('button', { name: 'Create folder' }).click()
  await expect(page.getByRole('button', { name: 'Specs' })).toBeVisible()

  await page.getByLabel('Drive file list').click({ button: 'right', position: { x: 16, y: 180 } })
  await page.getByRole('menuitem', { name: 'New Markdown document' }).click()
  await page.getByLabel('Name').fill('Plan')
  await page.getByRole('button', { name: 'Create document' }).click()
  await expect(page.getByRole('heading', { name: 'Plan.md' })).toBeVisible()
  await expect(page.getByText('Markdown document')).toBeVisible()

  await page.getByRole('button', { name: /Plan.md/ }).dblclick()
  await expect(page).toHaveURL(/\/drive\/items\/\d+\/edit$/)
  await expect(page.locator('.markdown-body')).toContainText('Plan')
  const editorBox = await page.getByLabel('Markdown content').boundingBox()
  expect(editorBox?.width).toBeGreaterThan(300)
  expect(editorBox?.height).toBeGreaterThan(400)
  await page.getByLabel('Markdown content').fill('## Updated\n\n- Keep project docs here.')
  await page.getByLabel('Save Markdown').click()
  await expect(page.locator('.markdown-body')).toContainText('Updated')
  await page.getByLabel('Back to Drive').click()
  await expect(page).toHaveURL('/drive')

  await page.locator('input[type="file"]').setInputFiles({
    name: 'Upload.md',
    mimeType: 'text/markdown',
    buffer: Buffer.from('# Upload'),
  })
  await expect(page.getByRole('button', { name: /Upload.md/ })).toBeVisible()

  await page.getByRole('button', { name: /Specs/ }).click()
  await expect(page.getByLabel('Drive folders').getByRole('button', { name: 'Drive' })).toBeVisible()
  await page.getByLabel('Drive folders').getByRole('button', { name: 'Drive' }).click()
  await page.getByRole('button', { name: 'Specs' }).click({ button: 'right' })
  await page.getByRole('menuitem', { name: 'Delete' }).click()
  await page.getByRole('button', { name: 'Delete' }).click()
  await expect(page.getByRole('button', { name: 'Specs' })).toHaveCount(0)
})
