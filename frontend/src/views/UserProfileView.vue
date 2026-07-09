<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { ArrowLeftIcon, PencilIcon } from '@lucide/vue'
import { RouterLink } from 'vue-router'
import UserProfileDetails from '@/components/user-groups/UserProfileDetails.vue'
import UserProfileForm from '@/components/user-groups/UserProfileForm.vue'
import { Button } from '@/components/ui/button'
import type { Group, ManagedUser, UserProfileInput } from '@/services/api'

const props = defineProps<{
  userId: number
  users: readonly ManagedUser[]
  groups: readonly Group[]
  loading: boolean
  saving: boolean
  editing: boolean
  canManageSystemAdmins: boolean
}>()

const emit = defineEmits<{
  loadUser: [userId: number]
  loadGroups: []
  saveUserProfile: [userId: number, input: UserProfileInput]
  cancelEdit: []
}>()

const user = computed(() => props.users.find((item) => item.id === props.userId) ?? null)
const pageTitle = computed(() => user.value?.display_name || user.value?.email || 'User profile')
const pageDescription = computed(() =>
  props.editing ? 'Edit profile details for this user.' : 'View profile details for this user.',
)

onMounted(() => {
  loadProfile()
})

watch(
  () => props.userId,
  () => loadProfile(),
)

function loadProfile() {
  emit('loadUser', props.userId)
  if (props.groups.length === 0) emit('loadGroups')
}
</script>

<template>
  <div class="grid gap-5">
    <div class="flex flex-wrap items-center gap-3">
      <Button as-child variant="outline" size="sm">
        <RouterLink :to="{ name: 'users' }">
          <ArrowLeftIcon />
          Users
        </RouterLink>
      </Button>
      <div class="min-w-0">
        <h2 class="truncate text-xl font-semibold">
          {{ pageTitle }}
        </h2>
        <p class="text-muted-foreground text-sm">{{ pageDescription }}</p>
      </div>
      <Button v-if="user && !props.editing" as-child size="sm" class="ml-auto">
        <RouterLink :to="{ name: 'user-edit', params: { userId: props.userId } }">
          <PencilIcon />
          Edit
        </RouterLink>
      </Button>
    </div>

    <p v-if="props.loading && !user" class="text-muted-foreground text-sm">Loading profile...</p>

    <UserProfileForm
      v-else-if="props.editing && user"
      :user="user"
      :groups="props.groups"
      :saving="props.saving"
      :can-manage-system-admins="props.canManageSystemAdmins"
      @save-user-profile="emit('saveUserProfile', $event.userId, $event.input)"
      @cancel-edit="emit('cancelEdit')"
    />

    <div v-else-if="!user" class="border-border bg-card text-card-foreground rounded-lg border p-5">
      <h3 class="text-base font-medium">User not found</h3>
      <p class="text-muted-foreground mt-1 text-sm">This user may have been deleted.</p>
    </div>

    <UserProfileDetails v-else :user="user" :groups="props.groups" />
  </div>
</template>
