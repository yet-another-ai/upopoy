<script setup lang="ts">
import { onClickOutside } from '@vueuse/core'
import { LoaderCircleIcon, SearchIcon, XIcon } from '@lucide/vue'
import { computed, shallowRef, useTemplateRef, watch } from 'vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useGlobalSearch } from '@/composables/useGlobalSearch'
import type { SearchResult, SearchResultType } from '@/services/api'

const emit = defineEmits<{
  selectResult: [result: SearchResult]
}>()

const searchRoot = useTemplateRef<HTMLElement>('searchRoot')
const open = shallowRef(false)
const activeIndex = shallowRef(-1)
const search = useGlobalSearch()

const hasQuery = computed(() => search.query.value.trim().length > 0)
const hasResults = computed(() => search.results.value.length > 0)
const showPanel = computed(
  () =>
    open.value &&
    hasQuery.value &&
    (hasResults.value || search.loading.value || search.searched.value || search.error.value),
)

watch(search.results, (results) => {
  activeIndex.value = results.length ? 0 : -1
})

onClickOutside(searchRoot, () => {
  open.value = false
})

function focusSearch() {
  open.value = true
}

function clearSearch() {
  search.clear()
  open.value = false
}

function chooseResult(result: SearchResult) {
  emit('selectResult', result)
  clearSearch()
}

function moveActiveIndex(offset: number) {
  if (!search.results.value.length) return

  const resultCount = search.results.value.length
  activeIndex.value = (activeIndex.value + offset + resultCount) % resultCount
}

function chooseActiveResult() {
  const result = search.results.value[activeIndex.value]
  if (result) chooseResult(result)
}

function resultTypeLabel(type: SearchResultType) {
  return {
    project: 'Project',
    task: 'Task',
    user: 'User',
    group: 'Group',
  }[type]
}
</script>

<template>
  <div ref="searchRoot" class="relative w-44 sm:w-72 md:w-96">
    <SearchIcon
      class="text-muted-foreground pointer-events-none absolute top-1/2 left-2.5 z-10 size-4 -translate-y-1/2"
      aria-hidden="true"
    />
    <Input
      v-model="search.query.value"
      type="search"
      class="h-9 pr-9 pl-8"
      placeholder="Search"
      aria-label="Search workspace"
      autocomplete="off"
      @focus="focusSearch"
      @keydown.down.prevent="moveActiveIndex(1)"
      @keydown.up.prevent="moveActiveIndex(-1)"
      @keydown.enter.prevent="chooseActiveResult"
      @keydown.esc.prevent="open = false"
    />
    <Button
      v-if="hasQuery"
      type="button"
      size="icon-sm"
      variant="ghost"
      class="absolute top-1/2 right-1 z-10 -translate-y-1/2"
      aria-label="Clear search"
      @click="clearSearch"
    >
      <XIcon class="size-3.5" />
    </Button>

    <div
      v-if="showPanel"
      class="bg-popover text-popover-foreground ring-foreground/10 absolute top-full right-0 z-50 mt-2 grid max-h-[min(28rem,calc(100vh-5rem))] w-[min(32rem,calc(100vw-2rem))] overflow-hidden rounded-lg shadow-lg ring-1"
    >
      <div v-if="search.loading.value" class="text-muted-foreground flex items-center gap-2 px-3 py-2 text-sm">
        <LoaderCircleIcon class="size-4 animate-spin" />
        Searching
      </div>

      <div v-else-if="search.error.value" class="text-destructive px-3 py-2 text-sm">
        {{ search.error.value }}
      </div>

      <div v-else-if="!hasResults" class="text-muted-foreground px-3 py-2 text-sm">
        No results
      </div>

      <div v-else class="grid max-h-[inherit] overflow-y-auto p-1">
        <button
          v-for="(result, index) in search.results.value"
          :key="result.slug"
          type="button"
          class="grid min-w-0 gap-1 rounded-md px-2.5 py-2 text-left outline-none"
          :class="index === activeIndex ? 'bg-accent text-accent-foreground' : 'hover:bg-accent/70'"
          @mouseenter="activeIndex = index"
          @click="chooseResult(result)"
        >
          <span class="flex min-w-0 items-center gap-2">
            <span class="truncate text-sm font-medium">{{ result.title }}</span>
            <span
              class="bg-muted text-muted-foreground shrink-0 rounded px-1.5 py-0.5 text-[0.625rem] leading-none font-medium uppercase"
            >
              {{ resultTypeLabel(result.type) }}
            </span>
          </span>
          <span v-if="result.snippet" class="text-muted-foreground line-clamp-1 text-xs">
            {{ result.snippet }}
          </span>
          <span class="text-muted-foreground font-mono text-[0.6875rem]">
            {{ result.slug }}
          </span>
        </button>
      </div>
    </div>
  </div>
</template>
