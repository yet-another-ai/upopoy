<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import type { Group, ProjectInput } from '@/services/api'

const props = defineProps<{
  groups: readonly Group[]
  loadingGroups: boolean
}>()

const emit = defineEmits<{
  createProject: [input: ProjectInput]
}>()

const form = reactive({
  name: '',
  description: '',
  groupId: '',
})

const canSubmit = computed(() => form.name.trim().length > 0 && form.groupId.length > 0)

watch(
  () => props.groups,
  (groups) => {
    if (form.groupId && groups.some((group) => String(group.id) === form.groupId)) return

    form.groupId = groups[0] ? String(groups[0].id) : ''
  },
  { immediate: true },
)

function submitProject() {
  if (!canSubmit.value) return

  emit('createProject', {
    name: form.name.trim(),
    description: form.description.trim(),
    group_id: Number.parseInt(form.groupId, 10),
  })
  form.name = ''
  form.description = ''
}
</script>

<template>
  <Card class="rounded-lg shadow-none">
    <CardHeader>
      <CardTitle class="text-base">New project</CardTitle>
    </CardHeader>
    <CardContent>
      <form class="grid gap-4" @submit.prevent="submitProject">
        <div class="grid gap-1.5">
          <Label for="project-name">Name</Label>
          <Input id="project-name" v-model="form.name" placeholder="Website relaunch" />
        </div>
        <div class="grid gap-1.5">
          <Label for="project-description">Description</Label>
          <Textarea id="project-description" v-model="form.description" rows="4" />
        </div>
        <div class="grid gap-1.5">
          <Label for="project-group">Group</Label>
          <Select
            v-model="form.groupId"
            :disabled="props.loadingGroups || props.groups.length === 0"
          >
            <SelectTrigger id="project-group" class="w-full" aria-label="Group">
              <SelectValue placeholder="Select group" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem v-for="group in props.groups" :key="group.id" :value="String(group.id)">
                {{ group.name }}
              </SelectItem>
            </SelectContent>
          </Select>
          <p
            v-if="!props.loadingGroups && props.groups.length === 0"
            class="text-muted-foreground text-sm"
          >
            Create a group before creating a project.
          </p>
        </div>
        <Button type="submit" class="justify-self-start" :disabled="!canSubmit">
          Create project
        </Button>
      </form>
    </CardContent>
  </Card>
</template>
