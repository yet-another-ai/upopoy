<script setup lang="ts">
import { reactive } from 'vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import type { ProjectInput } from '@/services/api'

const emit = defineEmits<{
  createProject: [input: ProjectInput]
}>()

const form = reactive({
  name: '',
  description: '',
})

function submitProject() {
  if (!form.name.trim()) return

  emit('createProject', {
    name: form.name.trim(),
    description: form.description.trim(),
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
        <Button type="submit" class="justify-self-start">Create project</Button>
      </form>
    </CardContent>
  </Card>
</template>
