import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import TaskForm from '../TaskForm.vue'
import type { TaskStatusOption } from '@/services/api'

const statuses: TaskStatusOption[] = [
  {
    id: 'todo',
    name: 'To Do',
    slug: 'todo',
    position: 0,
  },
]

describe('TaskForm', () => {
  it('emits trimmed task input when submitted', async () => {
    const wrapper = mount(TaskForm, {
      props: {
        statuses,
        defaultStatus: 'todo',
        submitLabel: 'Create task',
      },
    })

    await wrapper.find('#task-title').setValue('  Draft workflow  ')
    await wrapper.find('#task-description').setValue('  Check the API contract.  ')
    await wrapper.find('form').trigger('submit')

    expect(wrapper.emitted('submit')).toEqual([
      [
        {
          title: 'Draft workflow',
          description: 'Check the API contract.',
          status: 'todo',
          priority: 'medium',
        },
      ],
    ])
  })

  it('does not submit an empty title', async () => {
    const wrapper = mount(TaskForm, {
      props: {
        statuses,
        defaultStatus: 'todo',
        submitLabel: 'Create task',
      },
    })

    await wrapper.find('#task-title').setValue('   ')
    await wrapper.find('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
  })
})
