import { request, requestAuth } from './client'
import type { AuthInput, AuthProvider, AuthResponse, AuthSession } from './types'

export const authApi = {
  listAuthProviders: () => request<AuthProvider[]>('/api/v1/auth/providers'),
  signUp: (input: AuthInput): Promise<AuthSession> => requestAuth('/api/v1/auth/signup', input),
  login: (input: AuthInput): Promise<AuthSession> => requestAuth('/api/v1/auth/login', input),
  logout: () =>
    request<{ message: string }>('/api/v1/auth/logout', {
      method: 'DELETE',
    }),
  me: () => request<AuthResponse>('/api/v1/auth/me'),
}
