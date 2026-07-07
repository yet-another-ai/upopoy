import { expect, test, type Page, type Route } from '@playwright/test'

interface ProjectPayload {
  id: number
  group_id: number
  group_name: string | null
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
  iteration_id: number
  iteration_name: string
  iteration_starts_at: string | null
  iteration_deadline: string | null
  iteration_inbox: boolean
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

interface IterationPayload {
  id: number
  project_id: number
  name: string
  starts_at: string | null
  deadline: string | null
  inbox: boolean
  task_count: number
  created_at: string
  updated_at: string
}

const timestamp = '2026-07-06T00:00:00Z'
const authToken = 'Bearer e2e-token'

async function json(
  route: Route,
  body: unknown,
  status = 200,
  headers: Record<string, string> = {},
) {
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
  let nextTaskId = 100

  const project: ProjectPayload = {
    id: 1,
    group_id: 1,
    group_name: 'Engineering',
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
  const iterations: IterationPayload[] = [
    {
      id: 1,
      project_id: 1,
      name: 'Inbox',
      starts_at: null,
      deadline: null,
      inbox: true,
      task_count: 0,
      created_at: timestamp,
      updated_at: timestamp,
    },
  ]

  function syncIterationCounts() {
    for (const iteration of iterations) {
      iteration.task_count = statuses.reduce(
        (count, status) =>
          count + status.tasks.filter((task) => task.iteration_id === iteration.id).length,
        0,
      )
    }
  }

  function findIteration(iterationId: number | null | undefined) {
    return iterations.find((iteration) => iteration.id === iterationId) ?? iterations[0]
  }

  function isAuthorized(route: Route) {
    return route.request().headers().authorization === authToken
  }

  async function requireAuth(route: Route) {
    if (isAuthorized(route)) return true

    await json(route, { error: 'You need to sign in or sign up before continuing.' }, 401)
    return false
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

  await page.route('**/api/v1/auth/login', async (route) => {
    await json(
      route,
      {
        user: {
          id: 1,
          email: 'founder@example.com',
          created_at: timestamp,
          updated_at: timestamp,
        },
      },
      200,
      { Authorization: authToken },
    )
  })

  await page.route('**/api/v1/auth/signup', async (route) => {
    await json(
      route,
      {
        user: {
          id: 1,
          email: 'founder@example.com',
          created_at: timestamp,
          updated_at: timestamp,
        },
      },
      201,
      { Authorization: authToken },
    )
  })

  await page.route('**/api/v1/auth/me', async (route) => {
    if (!isAuthorized(route)) {
      await json(route, { error: 'You need to sign in or sign up before continuing.' }, 401)
      return
    }

    await json(route, {
      user: {
        id: 1,
        email: 'founder@example.com',
        created_at: timestamp,
        updated_at: timestamp,
      },
    })
  })

  await page.route('**/api/v1/auth/logout', async (route) => {
    if (!(await requireAuth(route))) return

    await json(route, { message: 'Signed out' })
  })

  await page.route('**/api/v1/projects', async (route) => {
    if (!(await requireAuth(route))) return

    if (route.request().method() === 'GET') {
      await json(route, [project])
      return
    }

    await json(route, project, 201)
  })

  await page.route('**/api/v1/groups', async (route) => {
    if (!(await requireAuth(route))) return

    await json(route, [
      {
        id: 1,
        name: 'Engineering',
        description: 'Product engineering workspace',
        parent_group_id: null,
        parent_group_name: null,
        user_ids: [1],
        users_count: 1,
        created_at: timestamp,
        updated_at: timestamp,
      },
    ])
  })

  await page.route('**/api/v1/projects/1/board', async (route) => {
    if (!(await requireAuth(route))) return

    syncIterationCounts()
    await json(route, { project, iterations, inbox_iteration: iterations[0], statuses })
  })

  await page.route('**/api/v1/projects/1/iterations', async (route) => {
    if (!(await requireAuth(route))) return

    if (route.request().method() === 'GET') {
      syncIterationCounts()
      await json(route, iterations)
      return
    }

    const requestBody = route.request().postDataJSON() as {
      iteration: {
        name: string
        starts_at: string
        deadline: string
      }
    }
    const iteration: IterationPayload = {
      id: iterations.length + 1,
      project_id: 1,
      name: requestBody.iteration.name,
      starts_at: requestBody.iteration.starts_at,
      deadline: requestBody.iteration.deadline,
      inbox: false,
      task_count: 0,
      created_at: timestamp,
      updated_at: timestamp,
    }
    iterations.push(iteration)
    await json(route, iteration, 201)
  })

  await page.route('**/api/v1/search**', async (route) => {
    if (!(await requireAuth(route))) return

    const url = new URL(route.request().url())
    const query = url.searchParams.get('q')?.toLowerCase() ?? ''

    await json(route, {
      results: query.includes('mvp')
        ? [
            {
              slug: 'project:1',
              type: 'project',
              id: 1,
              title: 'MVP',
              snippet: 'Initial Kanban surface',
              api_path: '/api/v1/projects/1',
              metadata: {},
              updated_at: timestamp,
            },
          ]
        : [],
    })
  })

  await page.route('**/api/v1/projects/1/tasks', async (route) => {
    if (!(await requireAuth(route))) return

    const requestBody = route.request().postDataJSON() as {
      task: {
        status: TaskStatusPayload['id']
        priority?: TaskPayload['priority']
        title: string
        description?: string
        deadline?: string | null
        estimated_minutes?: number | null
        iteration_id?: number | null
      }
    }
    const iteration = findIteration(requestBody.task.iteration_id)
    const task: TaskPayload = {
      id: nextTaskId++,
      project_id: 1,
      iteration_id: iteration.id,
      iteration_name: iteration.name,
      iteration_starts_at: iteration.starts_at,
      iteration_deadline: iteration.deadline,
      iteration_inbox: iteration.inbox,
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
    if (!(await requireAuth(route))) return

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

    if (route.request().method() === 'DELETE') {
      currentStatus.tasks = currentStatus.tasks.filter((item) => item.id !== taskId)
      await route.fulfill({ status: 204 })
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
        iteration_id?: number | null
        position?: number
      }
    }

    currentStatus.tasks = currentStatus.tasks.filter((item) => item.id !== taskId)
    const iteration = Object.hasOwn(requestBody.task, 'iteration_id')
      ? findIteration(requestBody.task.iteration_id)
      : findIteration(task.iteration_id)

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
      iteration_id: iteration.id,
      iteration_name: iteration.name,
      iteration_starts_at: iteration.starts_at,
      iteration_deadline: iteration.deadline,
      iteration_inbox: iteration.inbox,
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

  await expect(page).toHaveURL('/login')
  await expect(page.getByRole('heading', { name: 'Workspace access' })).toBeVisible()
  await expect(page.getByRole('link', { name: 'Continue with Developer' })).toBeVisible()
  await page.getByRole('button', { name: 'Create an account' }).click()
  await page.getByLabel('Email').fill('founder@example.com')
  await page.getByLabel('Password', { exact: true }).fill('password123')
  await page.getByLabel('Confirm password', { exact: true }).fill('password123')
  await page.getByRole('button', { name: 'Create account' }).click()

  await expect(page).toHaveURL('/')
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible()
  await page.getByLabel('Search workspace').fill('MVP')
  await expect(page.getByRole('button', { name: /MVP/ })).toBeVisible()
  await page.getByRole('button', { name: /MVP/ }).click()

  await expect(page).toHaveURL('/kanban')
  await expect(page.locator('h1', { hasText: 'MVP' })).toBeVisible()
  await page.getByRole('link', { name: 'Apps' }).click()

  await expect(page).toHaveURL('/')
  await expect(page.getByRole('link', { name: 'Open Project management' })).toBeVisible()
  await page.getByRole('link', { name: 'Open Project management' }).click()

  await expect(page).toHaveURL('/projects')
  await expect(page.getByText('Project management', { exact: true })).toBeVisible()
  await expect(page.getByText('New project', { exact: true })).toBeVisible()
  await expect(page.getByRole('heading', { name: 'MVP' })).toBeVisible()
  await page.getByRole('link', { name: 'Apps' }).click()

  await expect(page).toHaveURL('/')
  await expect(page.getByRole('link', { name: 'Open Kanban' })).toBeVisible()
  await page.getByRole('link', { name: 'Open Kanban' }).click()

  await expect(page).toHaveURL('/kanban')
  await expect(page.locator('h1', { hasText: 'MVP' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'New project' })).toHaveCount(0)
  await expect(page.getByText('Signed in as founder@example.com')).toBeVisible()
  await expect(page.getByText('4 statuses')).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Under Review' })).toBeVisible()
  await expect(page.getByText('todo', { exact: true })).toBeHidden()

  await page.getByRole('button', { name: 'Iterations' }).click()
  await expect(page.locator('h1', { hasText: 'MVP' })).toBeVisible()
  await expect(page.getByText('Inbox')).toBeVisible()
  await page.getByRole('button', { name: 'Iteration', exact: true }).click()
  await page.getByLabel('Name').fill('Sprint 1')
  await page.getByRole('button', { name: 'Start date' }).click()
  await page
    .getByLabel('Start date, July')
    .getByRole('button', { name: 'Monday, July 20, 2026' })
    .click()
  await page.getByLabel('Start time').fill('09:00')
  await page.getByRole('button', { name: 'Deadline date' }).click()
  await page
    .getByLabel('Deadline date, July')
    .getByRole('button', { name: 'Friday, July 31, 2026' })
    .click()
  await page.getByLabel('Deadline time').fill('09:00')
  await page.getByRole('button', { name: 'Create' }).click()
  await expect(page.getByText('Sprint 1')).toBeVisible()

  const sprintSection = page.getByTestId('iteration-section').filter({ hasText: 'Sprint 1' })
  await sprintSection.getByRole('button', { name: 'Task', exact: true }).click()
  await page.getByLabel('Title').fill('Draft MCP contract')
  await page.getByLabel('Description').fill('## Scope\n\n- Describe the future agent API.')
  await page.getByRole('combobox', { name: 'Priority' }).click()
  await page.getByRole('option', { name: 'High' }).click()
  await page.getByRole('button', { name: 'Create task' }).click()
  await expect(sprintSection.getByTestId('iteration-task-row')).toContainText('Draft MCP contract')
  await sprintSection.getByRole('link', { name: 'Open task Draft MCP contract' }).click()
  await expect(page.getByRole('heading', { name: 'Draft MCP contract' })).toBeVisible()
  await page.getByRole('link', { name: 'Board' }).click()
  await page.getByRole('button', { name: 'Kanban' }).click()

  await expect(page.getByTestId('task-card')).toContainText('Draft MCP contract')
  await expect(page.getByTestId('task-card')).toContainText('High')
  await expect(page.getByTestId('task-card')).toContainText('Sprint 1')
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

  await expect(page).toHaveURL('/kanban')
  await expect(doneColumn.getByTestId('task-card')).toContainText('Low')
  await expect(doneColumn.getByTestId('task-card')).toContainText(/Jul 31, 2026/)
  await expect(doneColumn.getByTestId('task-card')).toContainText('4h')

  await doneColumn.getByRole('link', { name: 'Open task Draft MCP contract' }).click()
  await expect(page.getByRole('heading', { name: 'Draft MCP contract' })).toBeVisible()
  await page.getByRole('button', { name: 'Cancel' }).click()
  await expect(page).toHaveURL('/kanban')
  await expect(page.locator('h1', { hasText: 'MVP' })).toBeVisible()

  await doneColumn.getByRole('button', { name: 'Task actions' }).click()
  await page.getByRole('menuitem', { name: 'Delete' }).click()
  await expect(page.getByRole('dialog')).toContainText('Delete task?')
  await page.getByRole('button', { name: 'Cancel' }).click()
  await expect(doneColumn.getByTestId('task-card')).toContainText('Draft MCP contract')

  await doneColumn.getByRole('button', { name: 'Task actions' }).click()
  await page.getByRole('menuitem', { name: 'Delete' }).click()
  await page.getByRole('dialog').getByRole('button', { name: 'Delete' }).click()
  await expect(doneColumn.getByTestId('task-card')).toHaveCount(0)

  await page.getByRole('button', { name: 'User menu' }).click()
  await page.getByRole('menuitem', { name: 'Sign out' }).click()
  await expect(page).toHaveURL('/login')
  await expect(page.getByRole('heading', { name: 'Workspace access' })).toBeVisible()
})

test('accepts an OAuth callback token', async ({ page }) => {
  await installMockApi(page)

  await page.goto('/auth/callback#token=e2e-token')

  await expect(page).toHaveURL('/')
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible()
  await expect(page.getByText('Signed in as founder@example.com')).toBeVisible()
})
