import { describe, expect, it } from 'vitest'
import { renderMarkdown } from '../markdown'

describe('renderMarkdown', () => {
  it('renders common markdown syntax', () => {
    const html = renderMarkdown('## Plan\n\n- Build API\n- Ship UI\n\n`estimate`')

    expect(html).toContain('<h2>Plan</h2>')
    expect(html).toContain('<li>Build API</li>')
    expect(html).toContain('<code>estimate</code>')
  })

  it('does not render raw HTML from task descriptions', () => {
    const html = renderMarkdown('<img src=x onerror=alert(1)> **safe**')

    expect(html).not.toContain('<img')
    expect(html).toContain('&lt;img')
    expect(html).toContain('<strong>safe</strong>')
  })
})
