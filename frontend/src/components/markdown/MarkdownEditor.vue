<script setup lang="ts">
import { computed, shallowRef, watch } from 'vue'
import { Columns2Icon, EyeIcon, PencilIcon } from '@lucide/vue'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import MarkdownPreview from './MarkdownPreview.vue'

type MarkdownEditorMode = 'edit' | 'preview' | 'split'

const props = withDefaults(
  defineProps<{
    editorLabel: string
    textareaId?: string
    emptyText?: string
    mode?: MarkdownEditorMode
    showModeToggle?: boolean
    textareaClass?: string
    previewClass?: string
    rows?: number
  }>(),
  {
    emptyText: 'Nothing written yet.',
    mode: 'split',
    showModeToggle: true,
    textareaClass: '',
    previewClass: '',
    rows: 6,
  },
)

const model = defineModel<string>({ required: true })
const activeMode = shallowRef<MarkdownEditorMode>(props.mode)

const showEditor = computed(() => activeMode.value === 'edit' || activeMode.value === 'split')
const showPreview = computed(() => activeMode.value === 'preview' || activeMode.value === 'split')
const gridClass = computed(() => (activeMode.value === 'split' ? 'md:grid-cols-2' : ''))

watch(
  () => props.mode,
  (mode) => {
    activeMode.value = mode
  },
)
</script>

<template>
  <div class="grid min-h-0 gap-2">
    <div v-if="props.showModeToggle" class="flex justify-end gap-1">
      <Button
        type="button"
        size="icon-sm"
        :variant="activeMode === 'edit' ? 'secondary' : 'ghost'"
        aria-label="Edit Markdown"
        @click="activeMode = 'edit'"
      >
        <PencilIcon />
      </Button>
      <Button
        type="button"
        size="icon-sm"
        :variant="activeMode === 'split' ? 'secondary' : 'ghost'"
        aria-label="Split Markdown editor"
        @click="activeMode = 'split'"
      >
        <Columns2Icon />
      </Button>
      <Button
        type="button"
        size="icon-sm"
        :variant="activeMode === 'preview' ? 'secondary' : 'ghost'"
        aria-label="Preview Markdown"
        @click="activeMode = 'preview'"
      >
        <EyeIcon />
      </Button>
    </div>

    <div class="grid min-h-0 gap-3" :class="gridClass">
      <Textarea
        v-if="showEditor"
        :id="props.textareaId"
        v-model="model"
        class="min-h-40 resize-none font-mono text-sm"
        :class="props.textareaClass"
        :rows="props.rows"
        :aria-label="props.editorLabel"
      />

      <div
        v-if="showPreview"
        class="border-border min-h-40 overflow-auto rounded-lg border p-4"
        :class="props.previewClass"
      >
        <MarkdownPreview :source="model" :empty-text="props.emptyText" />
      </div>
    </div>
  </div>
</template>
