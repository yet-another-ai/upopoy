import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import MarkdownEditor from '../MarkdownEditor.vue'

describe('MarkdownEditor', () => {
  it('edits and previews markdown through the shared renderer', async () => {
    const wrapper = mount(MarkdownEditor, {
      props: {
        editorLabel: 'Markdown content',
        modelValue: '# Notes',
        'onUpdate:modelValue': (value: string) => wrapper.setProps({ modelValue: value }),
      },
    })

    expect(wrapper.html()).toContain('<h1>Notes</h1>')

    await wrapper.find('textarea').setValue('## Updated')

    expect(wrapper.props('modelValue')).toBe('## Updated')
    expect(wrapper.html()).toContain('<h2>Updated</h2>')
  })
})
