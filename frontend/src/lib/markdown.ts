import DOMPurify from 'dompurify'
import MarkdownIt from 'markdown-it'

export const markdownRenderer = new MarkdownIt({
  breaks: true,
  html: false,
  linkify: true,
})

export function renderMarkdown(source: string | null | undefined) {
  const content = source?.trim()
  if (!content) return ''

  return DOMPurify.sanitize(markdownRenderer.render(content), {
    USE_PROFILES: { html: true },
  })
}
