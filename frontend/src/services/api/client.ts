import { i18n } from '@/i18n'
import { preferredLocaleHeader } from '@/i18n/locales'
import type { AuthInput, AuthResponse, AuthSession } from './types'

function jsonHeaders() {
  return {
    Accept: 'application/json',
    'Accept-Language': preferredLocaleHeader(),
    'Content-Type': 'application/json',
  }
}

const AUTH_TOKEN_STORAGE_KEY = 'upopoy.authToken'

let authToken =
  typeof localStorage === 'undefined' ? null : localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)

export class ApiError extends Error {
  readonly status: number

  constructor(message: string, status: number) {
    super(message)
    this.name = 'ApiError'
    this.status = status
  }
}

export function setAuthToken(token: string | null) {
  authToken = token

  if (typeof localStorage === 'undefined') return

  if (token) localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, token)
  else localStorage.removeItem(AUTH_TOKEN_STORAGE_KEY)
}

export function getAuthToken() {
  return authToken
}

export async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(path, {
    ...options,
    headers: {
      ...jsonHeaders(),
      ...(authToken ? { Authorization: authToken } : {}),
      ...options.headers,
    },
  })

  if (response.status === 204) return undefined as T

  const data = await parseResponseBody(response)

  if (!response.ok) {
    throw new ApiError(errorMessage(data), response.status)
  }

  return data as T
}

export async function requestAuth(path: string, input: AuthInput): Promise<AuthSession> {
  const response = await fetch(path, {
    method: 'POST',
    headers: jsonHeaders(),
    body: JSON.stringify({ user: input }),
  })
  const data = await parseResponseBody(response)

  if (!response.ok) {
    throw new ApiError(errorMessage(data), response.status)
  }

  const token = response.headers.get('Authorization')
  if (!token)
    throw new ApiError(i18n.global.t('errors.authenticationTokenMissing'), response.status)

  return {
    user: (data as AuthResponse).user,
    token,
  }
}

async function parseResponseBody(response: Response) {
  const contentType = response.headers.get('Content-Type') ?? ''
  if (contentType.includes('application/json')) return response.json()

  return response.text()
}

function errorMessage(data: unknown) {
  if (typeof data === 'string' && data) return data
  if (data && typeof data === 'object') {
    if ('errors' in data)
      return Object.values(data.errors as Record<string, string[]>)
        .flat()
        .join(', ')
    if ('error' in data && typeof data.error === 'string') return data.error
    if ('message' in data && typeof data.message === 'string') return data.message
  }

  return i18n.global.t('errors.requestFailed')
}
