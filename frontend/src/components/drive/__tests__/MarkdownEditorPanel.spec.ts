import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import MarkdownEditorPanel from '../MarkdownEditorPanel.vue'
import type { DriveItem } from '@/services/api'

const item: DriveItem = {
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

describe('MarkdownEditorPanel', () => {
  it('previews markdown and emits edited content on save', async () => {
    const wrapper = mount(MarkdownEditorPanel, {
      props: {
        item,
        content: '# Notes',
        versions: [],
        saving: false,
      },
    })

    expect(wrapper.text()).toContain('Notes.md')
    expect(wrapper.html()).toContain('<h1>Notes</h1>')

    await wrapper.find('textarea').setValue('# Updated')
    await wrapper.find('[aria-label="Save Markdown"]').trigger('click')

    expect(wrapper.emitted('save')).toEqual([['# Updated']])
  })

  it('emits close', async () => {
    const wrapper = mount(MarkdownEditorPanel, {
      props: {
        item,
        content: '# Notes',
        versions: [],
        saving: false,
      },
    })

    await wrapper.find('[aria-label="Back to Drive"]').trigger('click')

    expect(wrapper.emitted('close')).toHaveLength(1)
  })
})
