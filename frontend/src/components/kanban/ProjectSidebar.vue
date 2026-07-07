<script setup lang="ts">
import { LogOutIcon, PlusIcon } from '@lucide/vue'
import { reactive, shallowRef } from 'vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Separator } from '@/components/ui/separator'
import { Textarea } from '@/components/ui/textarea'
import type { Project, ProjectInput, User } from '@/services/api'

const props = defineProps<{
  projects: readonly Project[]
  selectedProjectId: number | null
  loading: boolean
  currentUser: User
}>()

const emit = defineEmits<{
  selectProject: [projectId: number]
  createProject: [input: ProjectInput]
  signOut: []
}>()

const form = reactive({
  name: '',
  description: '',
})
const creating = shallowRef(false)

function submitProject() {
  if (!form.name.trim()) return

  emit('createProject', {
    name: form.name.trim(),
    description: form.description.trim(),
  })
  form.name = ''
  form.description = ''
  creating.value = false
}
</script>

<template>
  <aside
    class="border-border bg-sidebar text-sidebar-foreground flex h-full w-full flex-col border-r p-4 lg:w-80"
  >
    <div class="flex items-center justify-between gap-3">
      <div>
        <p class="text-muted-foreground text-xs font-medium tracking-wider uppercase">upopoy</p>
        <h1 class="text-xl leading-tight font-semibold">Projects</h1>
      </div>
      <Button size="icon" variant="outline" aria-label="New project" @click="creating = !creating">
        <PlusIcon />
      </Button>
    </div>

    <Card v-if="creating" class="mt-4">
      <CardHeader class="pb-2">
        <CardTitle class="text-sm"> New project </CardTitle>
      </CardHeader>
      <CardContent>
        <form class="grid gap-3" @submit.prevent="submitProject">
          <div class="grid gap-1.5">
            <Label for="project-name">Name</Label>
            <Input id="project-name" v-model="form.name" placeholder="Website relaunch" />
          </div>
          <div class="grid gap-1.5">
            <Label for="project-description">Description</Label>
            <Textarea id="project-description" v-model="form.description" rows="3" />
          </div>
          <Button type="submit" size="sm"> Create project </Button>
        </form>
      </CardContent>
    </Card>

    <Separator class="my-4" />

    <div class="grid gap-2">
      <Button
        v-for="project in props.projects"
        :key="project.id"
        class="h-auto justify-start px-3 py-2 text-left"
        :variant="project.id === props.selectedProjectId ? 'secondary' : 'ghost'"
        @click="emit('selectProject', project.id)"
      >
        <span class="min-w-0">
          <span class="block truncate font-medium">{{ project.name }}</span>
          <span v-if="project.description" class="text-muted-foreground block truncate text-xs">
            {{ project.description }}
          </span>
        </span>
      </Button>
    </div>

    <p
      v-if="!props.loading && props.projects.length === 0"
      class="text-muted-foreground mt-6 text-sm"
    >
      Create a project to start shaping the board.
    </p>

    <div class="mt-auto grid gap-3 pt-6">
      <Separator />
      <div class="flex items-center justify-between gap-3">
        <div class="min-w-0">
          <p class="text-muted-foreground text-xs">Signed in as</p>
          <p class="truncate text-sm font-medium">{{ props.currentUser.email }}</p>
        </div>
        <Button size="icon" variant="ghost" aria-label="Sign out" @click="emit('signOut')">
          <LogOutIcon />
        </Button>
      </div>
    </div>
  </aside>
</template>
