import DOMPurify from 'dompurify'
import MarkdownIt from 'markdown-it'

const markdown = new MarkdownIt({
  breaks: true,
  html: false,
  linkify: true,
})

export function renderMarkdown(source: string | null | undefined) {
  const content = source?.trim()
  if (!content) return ''

  return DOMPurify.sanitize(markdown.render(content), {
    USE_PROFILES: { html: true },
  })
}
