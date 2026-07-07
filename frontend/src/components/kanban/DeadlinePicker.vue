<script setup lang="ts">
import { ChevronDownIcon, XIcon } from '@lucide/vue'
import { getLocalTimeZone, parseDate, type DateValue } from '@internationalized/date'
import { computed, shallowRef, watch } from 'vue'
import { Button } from '@/components/ui/button'
import { Calendar } from '@/components/ui/calendar'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { buildDeadlineIso, deadlineDatePart, deadlineTimePart } from '@/lib/deadline'

const props = defineProps<{
  id?: string
  label?: string
  modelValue?: string | null
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string | null]
}>()

const open = shallowRef(false)
const selectedDate = shallowRef<DateValue>()
const timeValue = shallowRef('09:00')

const dateLabel = computed(() =>
  selectedDate.value
    ? selectedDate.value.toDate(getLocalTimeZone()).toLocaleDateString()
    : 'Select date',
)
const fieldLabel = computed(() => props.label ?? 'Deadline')

watch(
  () => props.modelValue,
  (value) => {
    const datePart = deadlineDatePart(value)
    selectedDate.value = datePart ? parseDate(datePart) : undefined
    timeValue.value = deadlineTimePart(value)
  },
  { immediate: true },
)

function selectDate(value: DateValue | undefined) {
  selectedDate.value = value
  commitDeadline()
  open.value = false
}

function updateTime(value: string | number) {
  timeValue.value = String(value)
  commitDeadline()
}

function clearDeadline() {
  selectedDate.value = undefined
  timeValue.value = '09:00'
  emit('update:modelValue', null)
}

function commitDeadline() {
  if (!selectedDate.value) {
    emit('update:modelValue', null)
    return
  }

  emit('update:modelValue', buildDeadlineIso(selectedDate.value.toString(), timeValue.value))
}
</script>

<template>
  <div class="flex flex-wrap items-end gap-4">
    <div class="flex min-w-36 flex-col gap-3">
      <Label :for="props.id" class="px-1"> Date </Label>
      <Popover v-model:open="open">
        <PopoverTrigger as-child>
          <Button
            :id="props.id"
            type="button"
            variant="outline"
            class="w-36 justify-between font-normal"
            :aria-label="`${fieldLabel} date`"
          >
            {{ dateLabel }}
            <ChevronDownIcon />
          </Button>
        </PopoverTrigger>
        <PopoverContent class="w-auto overflow-hidden p-0" align="start">
          <Calendar
            :model-value="selectedDate"
            :calendar-label="`${fieldLabel} date`"
            prevent-deselect
            @update:model-value="selectDate"
          />
        </PopoverContent>
      </Popover>
    </div>

    <div class="flex min-w-32 flex-col gap-3">
      <Label for="task-deadline-time" class="px-1"> Time </Label>
      <Input
        id="task-deadline-time"
        type="time"
        step="1"
        :model-value="timeValue"
        :disabled="!selectedDate"
        :aria-label="`${fieldLabel} time`"
        class="bg-background appearance-none [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
        @update:model-value="updateTime"
      />
    </div>

    <Button
      type="button"
      variant="ghost"
      size="icon-sm"
      :disabled="!selectedDate"
      aria-label="Clear deadline"
      @click="clearDeadline"
    >
      <XIcon />
    </Button>
  </div>
</template>
