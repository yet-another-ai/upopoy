<script setup lang="ts">
import { ChevronLeftIcon, ChevronRightIcon } from '@lucide/vue'
import { Button } from '@/components/ui/button'
import type { UserPaginationMeta } from '@/services/api'

const props = defineProps<{
  meta: UserPaginationMeta
  loading: boolean
}>()

const emit = defineEmits<{
  changePage: [page: number]
}>()
</script>

<template>
  <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
    <p class="text-muted-foreground text-sm">
      Page {{ props.meta.current_page }} of {{ props.meta.total_pages || 1 }},
      {{ props.meta.total_count }} users
    </p>

    <div class="flex gap-2">
      <Button
        size="sm"
        variant="outline"
        :disabled="props.loading || props.meta.current_page <= 1"
        @click="emit('changePage', props.meta.current_page - 1)"
      >
        <ChevronLeftIcon />
        Previous
      </Button>
      <Button
        size="sm"
        variant="outline"
        :disabled="props.loading || props.meta.current_page >= props.meta.total_pages"
        @click="emit('changePage', props.meta.current_page + 1)"
      >
        Next
        <ChevronRightIcon />
      </Button>
    </div>
  </div>
</template>
