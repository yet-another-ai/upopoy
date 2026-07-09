<script setup lang="ts">
import { RefreshCcwIcon, UploadIcon } from '@lucide/vue'
import { useTemplateRef } from 'vue'
import { Button } from '@/components/ui/button'

const props = defineProps<{
  disabled: boolean
}>()

const emit = defineEmits<{
  uploadFile: [file: File]
  refresh: []
}>()

const fileInput = useTemplateRef<HTMLInputElement>('fileInput')

function selectFile() {
  fileInput.value?.click()
}

function uploadFile(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (file) emit('uploadFile', file)
  input.value = ''
}

defineExpose({ selectFile })
</script>

<template>
  <div class="flex flex-wrap items-center justify-end gap-2">
    <input ref="fileInput" class="sr-only" type="file" @change="uploadFile">
    <Button type="button" variant="outline" :disabled="props.disabled" @click="selectFile">
      <UploadIcon />
      Upload
    </Button>

    <Button type="button" variant="ghost" :disabled="props.disabled" @click="emit('refresh')">
      <RefreshCcwIcon />
      Refresh
    </Button>
  </div>
</template>
