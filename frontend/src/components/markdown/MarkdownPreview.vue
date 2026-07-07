<!-- eslint-disable vue/no-v-html -->
<script setup lang="ts">
import { computed } from 'vue'
import { renderMarkdown } from '@/lib/markdown'

const props = withDefaults(
  defineProps<{
    source?: string | null
    emptyText?: string
  }>(),
  {
    source: null,
    emptyText: 'No description yet.',
  },
)

const hasSource = computed(() => Boolean(props.source?.trim()))
const renderedHtml = computed(() => renderMarkdown(props.source))
</script>

<template>
  <!-- eslint-disable-next-line vue/no-v-html -->
  <article v-if="hasSource" class="markdown-body" v-html="renderedHtml" />
  <p v-else class="text-muted-foreground text-sm">
    {{ props.emptyText }}
  </p>
</template>

<style scoped>
.markdown-body {
  color: hsl(var(--foreground));
  font-size: 0.9375rem;
  line-height: 1.65;
  overflow-wrap: anywhere;
}

.markdown-body :deep(*) {
  margin-top: 0;
}

.markdown-body :deep(* + *) {
  margin-top: 0.75rem;
}

.markdown-body :deep(h1),
.markdown-body :deep(h2),
.markdown-body :deep(h3) {
  font-weight: 650;
  line-height: 1.25;
}

.markdown-body :deep(h1) {
  font-size: 1.35rem;
}

.markdown-body :deep(h2) {
  font-size: 1.15rem;
}

.markdown-body :deep(h3) {
  font-size: 1rem;
}

.markdown-body :deep(ul),
.markdown-body :deep(ol) {
  padding-left: 1.25rem;
}

.markdown-body :deep(ul) {
  list-style: disc;
}

.markdown-body :deep(ol) {
  list-style: decimal;
}

.markdown-body :deep(code) {
  border-radius: 0.25rem;
  background: hsl(var(--muted));
  padding: 0.1rem 0.3rem;
  font-size: 0.875em;
}

.markdown-body :deep(pre) {
  overflow-x: auto;
  border-radius: 0.5rem;
  background: hsl(var(--muted));
  padding: 0.875rem;
}

.markdown-body :deep(pre code) {
  background: transparent;
  padding: 0;
}

.markdown-body :deep(blockquote) {
  border-left: 3px solid hsl(var(--border));
  color: hsl(var(--muted-foreground));
  padding-left: 0.875rem;
}

.markdown-body :deep(a) {
  color: hsl(var(--primary));
  text-decoration: underline;
  text-underline-offset: 3px;
}
</style>
