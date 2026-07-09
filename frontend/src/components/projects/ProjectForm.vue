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
import type { Organization, ProjectInput, User } from '@/services/api'

const props = defineProps<{
  organizations: readonly Organization[]
  currentUser: User | null
  loadingOrganizations: boolean
}>()

const emit = defineEmits<{
  createProject: [input: ProjectInput]
}>()

const form = reactive({
  name: '',
  description: '',
  ownerValue: '',
})

const ownerOptions = computed(() => {
  const personal = props.currentUser
    ? [
        {
          value: `User:${props.currentUser.id}`,
          label: props.currentUser.display_name || props.currentUser.email,
          detail: 'Personal',
        },
      ]
    : []
  const organizations = props.organizations
    .filter((organization) => organization.can_admin)
    .map((organization) => ({
      value: `Organization:${organization.id}`,
      label: organization.name,
      detail: 'Organization',
    }))

  return [...personal, ...organizations]
})
const canSubmit = computed(() => form.name.trim().length > 0 && form.ownerValue.length > 0)

watch(
  ownerOptions,
  (owners) => {
    if (form.ownerValue && owners.some((owner) => owner.value === form.ownerValue)) return

    form.ownerValue = owners[0]?.value ?? ''
  },
  { immediate: true },
)

function submitProject() {
  if (!canSubmit.value) return
  const [ownerType, ownerId] = form.ownerValue.split(':')

  emit('createProject', {
    name: form.name.trim(),
    description: form.description.trim(),
    owner_type: ownerType as ProjectInput['owner_type'],
    owner_id: Number.parseInt(ownerId, 10),
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
          <Label for="project-owner">Owner</Label>
          <Select
            v-model="form.ownerValue"
            :disabled="props.loadingOrganizations || ownerOptions.length === 0"
          >
            <SelectTrigger id="project-owner" class="w-full" aria-label="Owner">
              <SelectValue placeholder="Select owner" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem v-for="owner in ownerOptions" :key="owner.value" :value="owner.value">
                {{ owner.label }} · {{ owner.detail }}
              </SelectItem>
            </SelectContent>
          </Select>
          <p
            v-if="!props.loadingOrganizations && ownerOptions.length === 0"
            class="text-muted-foreground text-sm"
          >
            You need an account before creating a project.
          </p>
        </div>
        <Button type="submit" class="justify-self-start" :disabled="!canSubmit">
          Create project
        </Button>
      </form>
    </CardContent>
  </Card>
</template>
