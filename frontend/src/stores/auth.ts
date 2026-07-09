import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, shallowRef } from 'vue'
import {
  api,
  getAuthToken,
  setAuthToken,
  type AuthInput,
  type AuthSession,
  type User,
} from '@/services/api'

export const useAuthStore = defineStore('auth', () => {
  const user = shallowRef<User | null>(null)
  const loading = shallowRef(false)
  const error = shallowRef<string | null>(null)

  const authenticated = computed(() => Boolean(user.value))

  async function restoreSession() {
    if (!getAuthToken()) return false

    loading.value = true
    error.value = null

    try {
      const response = await api.me()
      user.value = response.user
      return true
    } catch {
      setAuthToken(null)
      user.value = null
      return false
    } finally {
      loading.value = false
    }
  }

  async function login(input: AuthInput) {
    await authenticate(() => api.login(input))
  }

  async function signUp(input: AuthInput) {
    await authenticate(() => api.signUp(input))
  }

  async function acceptToken(token: string) {
    loading.value = true
    error.value = null
    setAuthToken(token.startsWith('Bearer ') ? token : `Bearer ${token}`)

    try {
      const response = await api.me()
      user.value = response.user
    } catch (err) {
      setAuthToken(null)
      user.value = null
      error.value = err instanceof Error ? err.message : 'Unable to authenticate'
      throw err
    } finally {
      loading.value = false
    }
  }

  function failAuthentication(message: string) {
    setAuthToken(null)
    user.value = null
    error.value = message
  }

  async function authenticate(request: () => Promise<AuthSession>) {
    loading.value = true
    error.value = null

    try {
      const session = await request()
      setAuthToken(session.token)
      user.value = session.user
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unable to authenticate'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    loading.value = true
    error.value = null

    try {
      if (getAuthToken()) await api.logout()
    } finally {
      setAuthToken(null)
      user.value = null
      loading.value = false
    }
  }

  function replaceCurrentUser(updatedUser: User) {
    if (user.value?.id !== updatedUser.id) return

    user.value = updatedUser
  }

  return {
    user,
    authenticated,
    loading,
    error,
    restoreSession,
    login,
    signUp,
    acceptToken,
    failAuthentication,
    replaceCurrentUser,
    logout,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useAuthStore, import.meta.hot))
}
