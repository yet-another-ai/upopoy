<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, shallowRef, useTemplateRef, watch } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import DriveActionDialog, {
  type DriveActionPayload,
  type DriveDialogAction,
} from '@/components/drive/DriveActionDialog.vue'
import DriveBreadcrumb from '@/components/drive/DriveBreadcrumb.vue'
import DriveDetailsPanel from '@/components/drive/DriveDetailsPanel.vue'
import DriveItemList from '@/components/drive/DriveItemList.vue'
import DriveToolbar from '@/components/drive/DriveToolbar.vue'
import { Button } from '@/components/ui/button'
import type { DriveItem, Project } from '@/services/api'
import { useDriveStore } from '@/stores/drive'
import { useToastsStore } from '@/stores/toasts'

const props = defineProps<{
  project: Project | null
  projectsLoading: boolean
}>()

const driveStore = useDriveStore()
const drive = storeToRefs(driveStore)
const router = useRouter()
const toasts = useToastsStore()
const selectedItem = shallowRef<DriveItem | null>(null)
const dialogOpen = shallowRef(false)
const dialogAction = shallowRef<DriveDialogAction | null>(null)
const dialogItem = shallowRef<DriveItem | null>(null)
const toolbar = useTemplateRef<InstanceType<typeof DriveToolbar>>('toolbar')

const disabled = computed(() => !props.project || drive.saving.value)
const workspaceGridClass = computed(() =>
  selectedItem.value
    ? 'grid min-h-0 flex-1 gap-4 xl:grid-cols-[minmax(0,1fr)_minmax(20rem,24rem)]'
    : 'grid min-h-0 flex-1 gap-4',
)

watch(
  () => props.project?.id,
  async (projectId) => {
    driveStore.clearDrive()
    selectedItem.value = null
    if (projectId) await driveStore.loadItems(projectId)
  },
  { immediate: true },
)

async function refresh() {
  if (!props.project) return

  await driveStore.loadItems(props.project.id)
  if (drive.error.value) toasts.error('Unable to refresh drive', drive.error.value)
}

async function createFolder(name: string) {
  if (!props.project) return

  try {
    await driveStore.createFolder(props.project.id, name)
  } catch (err) {
    notifyError(err, 'Unable to create folder')
  }
}

async function createMarkdown(name: string) {
  if (!props.project) return

  try {
    const item = await driveStore.createMarkdown(props.project.id, name, `# ${name.replace(/\.(md|markdown)$/i, '')}\n`)
    await selectItem(item)
  } catch (err) {
    notifyError(err, 'Unable to create Markdown document')
  }
}

function openAction(action: DriveDialogAction, item: DriveItem | null = null) {
  dialogAction.value = action
  dialogItem.value = item
  dialogOpen.value = true
}

async function submitAction(payload: DriveActionPayload) {
  const action = dialogAction.value
  const item = dialogItem.value

  try {
    if (action === 'create-folder' && payload.name) await createFolder(payload.name)
    if (action === 'create-markdown' && payload.name) await createMarkdown(normalizedMarkdownName(payload.name))
    if (action === 'rename' && item && payload.name) await renameItem(item, payload.name)
    if (action === 'move' && item) await moveItem(item, payload.parentId ?? null)
    if (action === 'delete' && item) await deleteItem(item)

    dialogOpen.value = false
  } catch {
    // Individual actions already surface their errors.
  }
}

async function uploadFile(file: File) {
  if (!props.project) return

  try {
    await driveStore.uploadFile(props.project.id, file)
  } catch (err) {
    notifyError(err, 'Unable to upload file')
  }
}

async function openFolder(folder: DriveItem) {
  if (!props.project) return

  selectedItem.value = null
  await driveStore.openFolder(props.project.id, folder)
}

async function navigate(index: number) {
  if (!props.project) return

  selectedItem.value = null
  await driveStore.navigateTo(props.project.id, index)
}

async function selectItem(item: DriveItem) {
  selectedItem.value = item
  drive.versions.value = []
  if (item.kind !== 'file') return

  try {
    await driveStore.loadVersions(item)
  } catch (err) {
    notifyError(err, 'Unable to load versions')
  }
}

async function editMarkdown(item: DriveItem) {
  if (!item.markdown) return
  await router.push({ name: 'drive-item-edit', params: { driveItemId: item.id } })
}

async function renameItem(item: DriveItem, name: string) {
  if (!name || name === item.name) return

  try {
    const updated = await driveStore.renameItem(item, name)
    if (selectedItem.value?.id === updated.id) selectedItem.value = updated
  } catch (err) {
    notifyError(err, 'Unable to rename item')
  }
}

async function moveItem(item: DriveItem, parentId: number | null) {
  if (item.parent_id === parentId) return

  try {
    await driveStore.moveItem(item, parentId)
    if (selectedItem.value?.id === item.id) selectedItem.value = null
  } catch (err) {
    notifyError(err, 'Unable to move item')
  }
}

async function deleteItem(item: DriveItem) {
  try {
    await driveStore.deleteItem(item)
    if (selectedItem.value?.id === item.id) selectedItem.value = null
  } catch (err) {
    notifyError(err, 'Unable to delete item')
  }
}

async function downloadItem(item: DriveItem) {
  try {
    const blob = await driveStore.downloadItem(item)
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = item.name
    link.click()
    URL.revokeObjectURL(url)
  } catch (err) {
    notifyError(err, 'Unable to download file')
  }
}

function notifyError(err: unknown, fallback: string) {
  toasts.error(fallback, err instanceof Error ? err.message : fallback)
}

function normalizedMarkdownName(value: string) {
  const name = value.trim()
  if (!name) return ''
  return /\.(md|markdown)$/i.test(name) ? name : `${name}.md`
}
</script>

<template>
  <main class="flex min-h-0 flex-1 flex-col gap-4 p-5">
    <div v-if="!props.project && !props.projectsLoading" class="grid place-items-center">
      <div class="grid gap-3 text-center">
        <h2 class="text-xl font-semibold">No project selected</h2>
        <Button as-child variant="outline">
          <RouterLink :to="{ name: 'projects' }">Project management</RouterLink>
        </Button>
      </div>
    </div>

    <template v-else>
      <div class="grid gap-3">
        <div class="flex min-w-0 items-center justify-between gap-3">
          <DriveBreadcrumb :breadcrumbs="drive.breadcrumbs.value" @navigate="navigate" />
        </div>
        <DriveToolbar
          ref="toolbar"
          :disabled="disabled"
          @upload-file="uploadFile"
          @refresh="refresh"
        />
      </div>

      <div :class="workspaceGridClass">
        <DriveItemList
          :items="drive.items.value"
          :loading="drive.loading.value"
          :selected-item-id="selectedItem?.id ?? null"
          @create-folder="openAction('create-folder')"
          @create-markdown="openAction('create-markdown')"
          @upload="toolbar?.selectFile()"
          @refresh="refresh"
          @open="openFolder"
          @select="selectItem"
          @edit="editMarkdown"
          @rename="openAction('rename', $event)"
          @move="openAction('move', $event)"
          @delete="openAction('delete', $event)"
          @download="downloadItem"
        />

        <DriveDetailsPanel
          v-if="selectedItem"
          :item="selectedItem"
          :versions="drive.versions.value"
          @close="selectedItem = null"
          @edit="editMarkdown"
          @download="downloadItem"
        />
      </div>

      <DriveActionDialog
        v-model:open="dialogOpen"
        :action="dialogAction"
        :item="dialogItem"
        :folders="drive.folders.value"
        :saving="drive.saving.value"
        @submit="submitAction"
      />
    </template>
  </main>
</template>
