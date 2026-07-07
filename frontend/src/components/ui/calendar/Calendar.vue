<script setup lang="ts">
import { ChevronLeftIcon, ChevronRightIcon } from '@lucide/vue'
import { reactiveOmit } from '@vueuse/core'
import {
  CalendarCell,
  CalendarCellTrigger,
  CalendarGrid,
  CalendarGridBody,
  CalendarGridHead,
  CalendarGridRow,
  CalendarHeadCell,
  CalendarHeader,
  CalendarHeading,
  CalendarNext,
  CalendarPrev,
  CalendarRoot,
  useForwardPropsEmits,
} from 'reka-ui'
import { cn } from '@/lib/utils'
import type { HTMLAttributes } from 'vue'
import type { CalendarRootEmits, CalendarRootProps } from 'reka-ui'

const props = withDefaults(defineProps<CalendarRootProps & { class?: HTMLAttributes['class'] }>(), {
  weekdayFormat: 'short',
  fixedWeeks: true,
  initialFocus: true,
})
const emits = defineEmits<CalendarRootEmits>()

const delegatedProps = reactiveOmit(props, 'class')
const forwarded = useForwardPropsEmits(delegatedProps, emits)
</script>

<template>
  <CalendarRoot
    v-slot="{ grid, weekDays }"
    data-slot="calendar"
    v-bind="forwarded"
    :class="cn('p-3', props.class)"
  >
    <CalendarHeader class="mb-2 flex items-center justify-between gap-2">
      <CalendarPrev
        class="hover:bg-accent hover:text-accent-foreground focus-visible:ring-ring/50 inline-flex size-8 items-center justify-center rounded-md outline-none focus-visible:ring-3 disabled:pointer-events-none disabled:opacity-50"
      >
        <ChevronLeftIcon class="size-4" />
      </CalendarPrev>
      <CalendarHeading class="text-sm font-medium" />
      <CalendarNext
        class="hover:bg-accent hover:text-accent-foreground focus-visible:ring-ring/50 inline-flex size-8 items-center justify-center rounded-md outline-none focus-visible:ring-3 disabled:pointer-events-none disabled:opacity-50"
      >
        <ChevronRightIcon class="size-4" />
      </CalendarNext>
    </CalendarHeader>

    <div class="grid gap-2">
      <CalendarGrid
        v-for="month in grid"
        :key="month.value.toString()"
        class="w-full border-collapse"
      >
        <CalendarGridHead>
          <CalendarGridRow>
            <CalendarHeadCell
              v-for="day in weekDays"
              :key="day"
              class="text-muted-foreground h-8 w-9 text-xs font-normal"
            >
              {{ day }}
            </CalendarHeadCell>
          </CalendarGridRow>
        </CalendarGridHead>
        <CalendarGridBody>
          <CalendarGridRow v-for="weekDates in month.rows" :key="weekDates.toString()">
            <CalendarCell
              v-for="weekDate in weekDates"
              :key="weekDate.toString()"
              :date="weekDate"
              class="p-0"
            >
              <CalendarCellTrigger
                :day="weekDate"
                :month="month.value"
                :class="
                  cn(
                    'hover:bg-accent hover:text-accent-foreground focus-visible:ring-ring/50 inline-flex size-9 items-center justify-center rounded-md text-sm transition outline-none focus-visible:ring-3',
                    'data-selected:bg-primary data-selected:text-primary-foreground data-today:border-border data-today:border',
                    'data-outside-view:text-muted-foreground data-disabled:pointer-events-none data-disabled:opacity-40 data-outside-view:opacity-50',
                  )
                "
              />
            </CalendarCell>
          </CalendarGridRow>
        </CalendarGridBody>
      </CalendarGrid>
    </div>
  </CalendarRoot>
</template>
