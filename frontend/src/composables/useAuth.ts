import { storeToRefs } from 'pinia'
import { useAuthStore } from '@/stores/auth'

export function useAuth() {
  const store = useAuthStore()
  const { user, authenticated, loading, error } = storeToRefs(store)

  return {
    user,
    authenticated,
    loading,
    error,
    restoreSession: store.restoreSession,
    login: store.login,
    signUp: store.signUp,
    acceptToken: store.acceptToken,
    failAuthentication: store.failAuthentication,
    logout: store.logout,
  }
}
