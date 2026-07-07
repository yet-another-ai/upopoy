<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { ArrowLeftIcon } from '@lucide/vue'
import { RouterLink } from 'vue-router'
import UserProfileForm from '@/components/user-groups/UserProfileForm.vue'
import { Button } from '@/components/ui/button'
import type { Group, ManagedUser, UserProfileInput } from '@/services/api'

const props = defineProps<{
  userId: number
  users: readonly ManagedUser[]
  groups: readonly Group[]
  loading: boolean
  saving: boolean
}>()

const emit = defineEmits<{
  loadUser: [userId: number]
  loadGroups: []
  saveUserProfile: [userId: number, input: UserProfileInput]
}>()

const user = computed(() => props.users.find((item) => item.id === props.userId) ?? null)

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
          {{ user?.display_name || user?.email || 'User profile' }}
        </h2>
        <p class="text-muted-foreground text-sm">Edit profile details for this user.</p>
      </div>
    </div>

    <p v-if="props.loading && !user" class="text-muted-foreground text-sm">Loading profile...</p>

    <UserProfileForm
      v-else
      :user="user"
      :groups="props.groups"
      :saving="props.saving"
      @save-user-profile="emit('saveUserProfile', $event.userId, $event.input)"
    />
  </div>
</template>
