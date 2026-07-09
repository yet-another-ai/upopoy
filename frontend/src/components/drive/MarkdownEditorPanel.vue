<script setup lang="ts">
import { computed, shallowRef, watch } from 'vue'
import { HistoryIcon, RotateCcwIcon, SaveIcon, XIcon } from '@lucide/vue'
import { Button } from '@/components/ui/button'
import MarkdownEditor from '@/components/markdown/MarkdownEditor.vue'
import type { DriveItem, DriveItemVersion } from '@/services/api'

const props = defineProps<{
  item: DriveItem | null
  content: string
  versions: readonly DriveItemVersion[]
  saving: boolean
}>()

const emit = defineEmits<{
  close: []
  restoreVersion: [version: DriveItemVersion]
  save: [content: string]
}>()

const draft = shallowRef('')

const changed = computed(() => draft.value !== props.content)

watch(
  () => [props.item?.id, props.content] as const,
  () => {
    draft.value = props.content
  },
  { immediate: true },
)
</script>

<template>
  <section v-if="props.item" class="border-border bg-card flex min-h-0 flex-1 flex-col gap-3 rounded-lg border p-4">
    <div class="flex min-w-0 items-center gap-2">
      <div class="min-w-0">
        <h3 class="truncate text-base font-semibold">{{ props.item.name }}</h3>
      </div>
      <div class="ml-auto flex gap-1">
        <Button size="icon-sm" variant="ghost" :disabled="props.saving || !changed" aria-label="Save Markdown" @click="emit('save', draft)">
          <SaveIcon />
        </Button>
        <Button size="icon-sm" variant="ghost" aria-label="Back to Drive" @click="emit('close')">
          <XIcon />
        </Button>
      </div>
    </div>

    <div class="grid min-h-0 flex-1 gap-3 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_13rem]">
      <MarkdownEditor
        v-model="draft"
        class="lg:col-span-2"
        mode="split"
        editor-label="Markdown content"
        empty-text="Empty document"
        textarea-class="h-full min-h-[28rem] lg:min-h-[28rem]"
        preview-class="min-h-[28rem] lg:min-h-[28rem]"
      />

      <div class="border-border grid min-h-[20rem] content-start gap-2 overflow-auto rounded-lg border p-3 lg:min-h-0">
        <div class="text-muted-foreground flex items-center gap-1.5 text-xs font-medium uppercase">
          <HistoryIcon class="size-3.5" />
          Versions
        </div>
        <p v-if="props.versions.length === 0" class="text-muted-foreground text-sm">
          No versions yet.
        </p>
        <button
          v-for="version in props.versions"
          :key="version.id"
          type="button"
          class="hover:bg-accent grid rounded-md px-2 py-1.5 text-left text-sm"
          @click="emit('restoreVersion', version)"
        >
          <span class="flex items-center gap-1.5 font-medium">
            <RotateCcwIcon class="size-3.5" />
            v{{ version.version_number }}
          </span>
          <span class="text-muted-foreground truncate text-xs">{{ version.created_at }}</span>
        </button>
      </div>
    </div>
  </section>
</template>
