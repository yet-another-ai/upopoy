import { expect, test, type Page, type Route } from '@playwright/test'

interface ProjectPayload {
  id: number
  name: string
  description: string | null
  created_at: string
  updated_at: string
}

interface TaskStatusPayload {
  id: 'todo' | 'in_progress' | 'under_review' | 'done'
  name: string
  slug: string
  position: number
}

interface TaskPayload {
  id: number
  project_id: number
  status: TaskStatusPayload['id']
  priority: 'low' | 'medium' | 'high'
  title: string
  description: string | null
  deadline: string | null
  estimated_minutes: number | null
  position: number
  created_at: string
  updated_at: string
}

const timestamp = '2026-07-06T00:00:00Z'

async function json(route: Route, body: unknown, status = 200) {
  await route.fulfill({
    status,
    contentType: 'application/json',
    body: JSON.stringify(body),
  })
}

async function installMockApi(page: Page) {
  let nextTaskId = 100

  const project: ProjectPayload = {
    id: 1,
    name: 'MVP',
    description: 'Initial Kanban surface',
    created_at: timestamp,
    updated_at: timestamp,
  }

  const statuses: Array<TaskStatusPayload & { tasks: TaskPayload[] }> = [
    {
      id: 'todo',
      name: 'To Do',
      slug: 'todo',
      position: 0,
      tasks: [],
    },
    {
      id: 'in_progress',
      name: 'In Progress',
      slug: 'in_progress',
      position: 1,
      tasks: [],
    },
    {
      id: 'under_review',
      name: 'Under Review',
      slug: 'under_review',
      position: 2,
      tasks: [],
    },
    {
      id: 'done',
      name: 'Done',
      slug: 'done',
      position: 3,
      tasks: [],
    },
  ]

  await page.route('**/api/v1/projects', async (route) => {
    if (route.request().method() === 'GET') {
      await json(route, [project])
      return
    }

    await json(route, project, 201)
  })

  await page.route('**/api/v1/projects/1/board', async (route) => {
    await json(route, { project, statuses })
  })

  await page.route('**/api/v1/projects/1/tasks', async (route) => {
    const requestBody = route.request().postDataJSON() as {
      task: {
        status: TaskStatusPayload['id']
        priority?: TaskPayload['priority']
        title: string
        description?: string
        deadline?: string | null
        estimated_minutes?: number | null
      }
    }
    const task: TaskPayload = {
      id: nextTaskId++,
      project_id: 1,
      status: requestBody.task.status,
      priority: requestBody.task.priority ?? 'medium',
      title: requestBody.task.title,
      description: requestBody.task.description ?? null,
      deadline: requestBody.task.deadline ?? null,
      estimated_minutes: requestBody.task.estimated_minutes ?? null,
      position: 1,
      created_at: timestamp,
      updated_at: timestamp,
    }

    statuses.find((status) => status.id === task.status)?.tasks.push(task)
    await json(route, task, 201)
  })

  await page.route('**/api/v1/tasks/*', async (route) => {
    const taskId = Number(route.request().url().split('/').at(-1))
    const currentStatus = statuses.find((status) => status.tasks.some((task) => task.id === taskId))
    const task = currentStatus?.tasks.find((item) => item.id === taskId)

    if (!currentStatus || !task) {
      await json(route, { errors: { task: ['not found'] } }, 404)
      return
    }

    if (route.request().method() === 'GET') {
      await json(route, task)
      return
    }

    const requestBody = route.request().postDataJSON() as {
      task: {
        status?: TaskStatusPayload['id']
        priority?: TaskPayload['priority']
        title?: string
        description?: string
        deadline?: string | null
        estimated_minutes?: number | null
        position?: number
      }
    }

    currentStatus.tasks = currentStatus.tasks.filter((item) => item.id !== taskId)

    const updatedTask = {
      ...task,
      title: requestBody.task.title ?? task.title,
      description: requestBody.task.description ?? task.description,
      status: requestBody.task.status ?? task.status,
      priority: requestBody.task.priority ?? task.priority,
      deadline: Object.hasOwn(requestBody.task, 'deadline')
        ? requestBody.task.deadline!
        : task.deadline,
      estimated_minutes: Object.hasOwn(requestBody.task, 'estimated_minutes')
        ? requestBody.task.estimated_minutes!
        : task.estimated_minutes,
      position: requestBody.task.position ?? task.position,
      updated_at: timestamp,
    }
    statuses.find((status) => status.id === updatedTask.status)?.tasks.push(updatedTask)

    await json(route, updatedTask)
  })
}

test('manages a project board with fixed statuses and tasks', async ({ page }) => {
  await installMockApi(page)

  await page.goto('/')

  await expect(page.getByRole('heading', { name: 'MVP' })).toBeVisible()
  await expect(page.getByText('4 statuses')).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Under Review' })).toBeVisible()
  await expect(page.getByText('todo', { exact: true })).toBeHidden()

  await page.getByRole('button', { name: 'Add task' }).first().click()
  await page.getByLabel('Title').fill('Draft MCP contract')
  await page.getByLabel('Description').fill('## Scope\n\n- Describe the future agent API.')
  await page.getByRole('combobox', { name: 'Priority' }).click()
  await page.getByRole('option', { name: 'High' }).click()
  await page.getByRole('button', { name: 'Create task' }).click()

  await expect(page.getByTestId('task-card')).toContainText('Draft MCP contract')
  await expect(page.getByTestId('task-card')).toContainText('High')
  await expect(page.getByText('Describe the future agent API.')).toBeHidden()
  await expect(page.getByText('Drag to move', { exact: true })).toBeHidden()
  await expect(page.getByText('Details', { exact: true })).toBeHidden()
  await expect(page.getByText('1 tasks')).toBeVisible()

  const card = page.getByTestId('task-card').filter({ hasText: 'Draft MCP contract' })
  const doneColumn = page.getByTestId('kanban-column').filter({ hasText: 'Done' })
  const cardBox = await card.boundingBox()
  const doneBox = await doneColumn.boundingBox()

  expect(cardBox).not.toBeNull()
  expect(doneBox).not.toBeNull()

  await card.dispatchEvent('pointerdown', {
    bubbles: true,
    button: 0,
    buttons: 1,
    clientX: cardBox!.x + 32,
    clientY: cardBox!.y + 32,
    isPrimary: true,
    pointerId: 1,
    pointerType: 'mouse',
  })
  await page.evaluate(
    ({ x, y }) => {
      window.dispatchEvent(
        new PointerEvent('pointermove', {
          bubbles: true,
          button: 0,
          buttons: 1,
          clientX: x,
          clientY: y,
          isPrimary: true,
          pointerId: 1,
          pointerType: 'mouse',
        }),
      )
    },
    {
      x: doneBox!.x + doneBox!.width / 2,
      y: doneBox!.y + doneBox!.height / 2,
    },
  )

  await expect
    .poll(async () => {
      const movedBox = await card.boundingBox()
      return movedBox ? Math.round(movedBox.x) : null
    })
    .toBeGreaterThan(Math.round(cardBox!.x + 80))

  await doneColumn.dispatchEvent('pointerup', {
    bubbles: true,
    button: 0,
    clientX: doneBox!.x + doneBox!.width / 2,
    clientY: doneBox!.y + doneBox!.height / 2,
    isPrimary: true,
    pointerId: 1,
    pointerType: 'mouse',
  })

  await expect(doneColumn.getByTestId('task-card')).toContainText('Draft MCP contract')

  await doneColumn.getByRole('link', { name: 'Open task Draft MCP contract' }).click()

  await expect(page.getByRole('heading', { name: 'Draft MCP contract' })).toBeVisible()
  await expect(page.getByText('Description preview', { exact: true })).toBeHidden()
  await expect(page.getByRole('heading', { name: 'Scope' })).toBeVisible()
  await expect(page.getByText('Describe the future agent API.')).toBeVisible()
  await page.getByLabel('Edit description').click()
  await expect(page.getByRole('textbox', { name: 'Description' })).toBeVisible()
  await page
    .getByRole('textbox', { name: 'Description' })
    .fill('## Updated scope\n\n- Keep markdown in the task form.')
  await page.getByRole('combobox', { name: 'Priority' }).click()
  await page.getByRole('option', { name: 'Low' }).click()
  await page.getByRole('button', { name: 'Deadline date' }).click()
  await page.getByRole('button', { name: 'Friday, July 31, 2026' }).click()
  await page.getByLabel('Deadline time').fill('14:30')
  await page.getByLabel('Estimated time').fill('240')
  await page.getByRole('button', { name: 'Save task' }).click()

  await expect(page).toHaveURL('/')
  await expect(doneColumn.getByTestId('task-card')).toContainText('Low')
  await expect(doneColumn.getByTestId('task-card')).toContainText(/Jul 31, 2026/)
  await expect(doneColumn.getByTestId('task-card')).toContainText('4h')

  await doneColumn.getByRole('link', { name: 'Open task Draft MCP contract' }).click()
  await expect(page.getByRole('heading', { name: 'Draft MCP contract' })).toBeVisible()
  await page.getByRole('button', { name: 'Cancel' }).click()
  await expect(page).toHaveURL('/')
  await expect(page.getByRole('heading', { name: 'MVP' })).toBeVisible()
})
