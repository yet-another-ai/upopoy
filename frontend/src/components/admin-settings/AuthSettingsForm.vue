<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { MailIcon, RotateCcwIcon, SaveIcon, UserPlusIcon } from '@lucide/vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import type { AdminSettings, AdminSettingsInput } from '@/services/api'

const props = defineProps<{
  settings: AdminSettings | null
  loading: boolean
  saving: boolean
}>()

const emit = defineEmits<{
  save: [input: AdminSettingsInput]
}>()

const draft = reactive({
  registrationEnabled: true,
  emailLoginEnabled: true,
})

const registrationEnabled = computed(() => props.settings?.registration_enabled ?? true)
const emailLoginEnabled = computed(() => props.settings?.email_login_enabled ?? true)
const hasChanges = computed(
  () =>
    draft.registrationEnabled !== registrationEnabled.value ||
    draft.emailLoginEnabled !== emailLoginEnabled.value,
)

watch(
  () => props.settings,
  () => resetDraft(),
  { immediate: true },
)

function checked(event: Event) {
  return event.target instanceof HTMLInputElement && event.target.checked
}

function resetDraft() {
  draft.registrationEnabled = registrationEnabled.value
  draft.emailLoginEnabled = emailLoginEnabled.value
}

function saveChanges() {
  if (!hasChanges.value) return

  emit('save', {
    registration_enabled: draft.registrationEnabled,
    email_login_enabled: draft.emailLoginEnabled,
  })
}
</script>

<!-- eslint-disable vue/html-self-closing -->
<template>
  <Card class="rounded-lg shadow-none">
    <CardHeader>
      <CardTitle>Authentication</CardTitle>
      <CardDescription>Control which sign-in methods are available to users.</CardDescription>
    </CardHeader>
    <CardContent class="grid gap-4">
      <p v-if="props.loading && !props.settings" class="text-muted-foreground text-sm">
        Loading settings...
      </p>

      <template v-else>
        <div class="border-border grid gap-4 rounded-lg border p-4 sm:grid-cols-[auto_1fr_auto]">
          <span
            class="bg-primary text-primary-foreground grid size-10 place-items-center rounded-md"
            aria-hidden="true"
          >
            <UserPlusIcon class="size-5" />
          </span>
          <div class="min-w-0">
            <h3 class="text-sm font-medium">Registration</h3>
            <p class="text-muted-foreground mt-1 text-sm">
              Allow users to create accounts with email and password.
            </p>
          </div>
          <label class="inline-flex items-center gap-2 justify-self-start sm:justify-self-end">
            <input
              type="checkbox"
              class="peer sr-only"
              :checked="draft.registrationEnabled"
              :disabled="props.saving || props.loading"
              @change="draft.registrationEnabled = checked($event)"
            />
            <span
              class="peer-checked:bg-primary bg-muted after:bg-background relative h-6 w-10 rounded-full transition after:absolute after:top-1 after:left-1 after:size-4 after:rounded-full after:transition peer-checked:after:translate-x-4"
              aria-hidden="true"
            />
            <span class="text-sm">{{ draft.registrationEnabled ? 'Enabled' : 'Disabled' }}</span>
          </label>
        </div>

        <div class="border-border grid gap-4 rounded-lg border p-4 sm:grid-cols-[auto_1fr_auto]">
          <span
            class="bg-primary text-primary-foreground grid size-10 place-items-center rounded-md"
            aria-hidden="true"
          >
            <MailIcon class="size-5" />
          </span>
          <div class="min-w-0">
            <h3 class="text-sm font-medium">Email login</h3>
            <p class="text-muted-foreground mt-1 text-sm">
              Allow users to sign in with email and password instead of OAuth only.
            </p>
          </div>
          <label class="inline-flex items-center gap-2 justify-self-start sm:justify-self-end">
            <input
              type="checkbox"
              class="peer sr-only"
              :checked="draft.emailLoginEnabled"
              :disabled="props.saving || props.loading"
              @change="draft.emailLoginEnabled = checked($event)"
            />
            <span
              class="peer-checked:bg-primary bg-muted after:bg-background relative h-6 w-10 rounded-full transition after:absolute after:top-1 after:left-1 after:size-4 after:rounded-full after:transition peer-checked:after:translate-x-4"
              aria-hidden="true"
            />
            <span class="text-sm">{{ draft.emailLoginEnabled ? 'Enabled' : 'Disabled' }}</span>
          </label>
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <Button
            type="button"
            :disabled="props.loading || props.saving || !hasChanges"
            @click="saveChanges"
          >
            <SaveIcon />
            {{ props.saving ? 'Saving...' : 'Save changes' }}
          </Button>
          <Button
            type="button"
            variant="outline"
            :disabled="props.loading || props.saving || !hasChanges"
            @click="resetDraft"
          >
            <RotateCcwIcon />
            Reset
          </Button>
          <span v-if="hasChanges" class="text-muted-foreground text-sm">Unsaved changes</span>
        </div>
      </template>
    </CardContent>
  </Card>
</template>
