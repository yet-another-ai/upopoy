<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, shallowRef, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import MarkdownEditorPanel from '@/components/drive/MarkdownEditorPanel.vue'
import { Button } from '@/components/ui/button'
import { positiveIntegerRouteParam } from '@/lib/route'
import type { DriveItem } from '@/services/api'
import { useDriveStore } from '@/stores/drive'
import { useToastsStore } from '@/stores/toasts'

const route = useRoute()
const router = useRouter()
const driveStore = useDriveStore()
const drive = storeToRefs(driveStore)
const toasts = useToastsStore()

const item = shallowRef<DriveItem | null>(null)
const content = shallowRef('')
const loading = shallowRef(false)

const driveItemId = computed(() => positiveIntegerRouteParam(route, 'driveItemId'))

watch(
  driveItemId,
  async (itemId) => {
    item.value = null
    content.value = ''
    drive.versions.value = []
    if (!itemId) return

    loading.value = true
    try {
      const loadedItem = await driveStore.loadItem(itemId)
      if (!loadedItem.markdown) {
        toasts.error('Unable to edit file', 'Only Markdown files can be edited.')
        await router.replace({ name: 'drive' })
        return
      }

      item.value = loadedItem
      content.value = await driveStore.loadContent(loadedItem)
      await driveStore.loadVersions(loadedItem)
    } catch (err) {
      notifyError(err, 'Unable to load Markdown document')
    } finally {
      loading.value = false
    }
  },
  { immediate: true },
)

async function saveMarkdown(nextContent: string) {
  if (!item.value) return

  try {
    item.value = await driveStore.saveContent(item.value, nextContent)
    content.value = nextContent
  } catch (err) {
    notifyError(err, 'Unable to save Markdown content')
  }
}

async function restoreVersion(version: Parameters<typeof driveStore.restoreVersion>[0]) {
  try {
    const restoredItem = await driveStore.restoreVersion(version)
    item.value = restoredItem
    content.value = await driveStore.loadContent(restoredItem)
  } catch (err) {
    notifyError(err, 'Unable to restore version')
  }
}

async function closeEditor() {
  await router.push({ name: 'drive' })
}

function notifyError(err: unknown, fallback: string) {
  toasts.error(fallback, err instanceof Error ? err.message : fallback)
}
</script>

<template>
  <main class="flex min-h-0 flex-1 flex-col gap-4 p-5">
    <div v-if="loading" class="text-muted-foreground grid min-h-0 flex-1 place-items-center text-sm">
      Loading document...
    </div>

    <MarkdownEditorPanel
      v-else-if="item"
      :item="item"
      :content="content"
      :versions="drive.versions.value"
      :saving="drive.saving.value"
      @close="closeEditor"
      @restore-version="restoreVersion"
      @save="saveMarkdown"
    />

    <div v-else class="grid min-h-0 flex-1 place-items-center">
      <div class="grid gap-3 text-center">
        <h2 class="text-xl font-semibold">Document unavailable</h2>
        <Button variant="outline" @click="closeEditor">Back to Drive</Button>
      </div>
    </div>
  </main>
</template>
