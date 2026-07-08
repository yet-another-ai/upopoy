<script setup lang="ts">
import ResourceSearch from '@/components/search/ResourceSearch.vue'
import type { SearchResult } from '@/services/api'

const emit = defineEmits<{
  selectResult: [result: SearchResult]
}>()
</script>

<template>
  <ResourceSearch
    class="w-44 sm:w-72 md:w-96"
    placeholder="Search"
    aria-label="Search workspace"
    @select-result="emit('selectResult', $event)"
  />
</template>
