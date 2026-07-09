import ky, { type Options } from 'ky'
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
export const SERVER_UNAVAILABLE_EVENT = 'upopoy:server-unavailable'

let authToken =
  typeof localStorage === 'undefined' ? null : localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
let serverHealthCheck: Promise<void> | null = null

const apiClient = ky.create({
  retry: 0,
  throwHttpErrors: false,
})

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

export async function request<T>(path: string, options: Options = {}): Promise<T> {
  const response = await sendRequest(path, options, true)

  if (response.status === 204) return undefined as T

  const data = await parseResponseBody(response).catch((error: unknown) => {
    if (!response.ok) return null

    throw error
  })

  if (!response.ok) {
    if (shouldCheckServerHealth(response.status)) await checkServerHealth()
    throw new ApiError(errorMessage(data), response.status)
  }

  return data as T
}

export async function requestBlob(path: string, options: Options = {}): Promise<Blob> {
  const response = await sendRequest(path, options, true)

  if (!response.ok) {
    const data = await parseResponseBody(response).catch(() => null)
    if (shouldCheckServerHealth(response.status)) await checkServerHealth()
    throw new ApiError(errorMessage(data), response.status)
  }

  return response.blob()
}

export async function requestAuth(path: string, input: AuthInput): Promise<AuthSession> {
  const response = await sendRequest(path, {
    method: 'POST',
    body: JSON.stringify({ user: input }),
  })
  const data = await parseResponseBody(response).catch((error: unknown) => {
    if (!response.ok) return null

    throw error
  })

  if (!response.ok) {
    if (shouldCheckServerHealth(response.status)) await checkServerHealth()
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

async function sendRequest(path: string, options: Options = {}, includeAuth = false) {
  try {
    return await apiClient(requestUrl(path), {
      ...options,
      headers: requestHeaders(options.headers, includeAuth, isFormDataBody(options.body)),
    })
  } catch (error) {
    await checkServerHealth()
    throw error instanceof Error ? error : new ApiError(i18n.global.t('errors.requestFailed'), 0)
  }
}

function requestHeaders(headers: Options['headers'], includeAuth: boolean, formDataBody = false) {
  const mergedHeaders = new Headers(jsonHeaders())
  if (formDataBody) mergedHeaders.delete('Content-Type')
  if (includeAuth && authToken) mergedHeaders.set('Authorization', authToken)

  if (headers instanceof Headers) {
    headers.forEach((value, key) => {
      mergedHeaders.set(key, value)
    })
  } else if (Array.isArray(headers)) {
    for (const [key, value] of headers) mergedHeaders.set(key, value)
  } else if (headers) {
    for (const [key, value] of Object.entries(headers)) {
      if (value !== undefined) mergedHeaders.set(key, value)
    }
  }

  return mergedHeaders
}

function isFormDataBody(body: Options['body']) {
  return typeof FormData !== 'undefined' && body instanceof FormData
}

async function parseResponseBody(response: Response) {
  const contentType = response.headers.get('Content-Type') ?? ''
  if (contentType.includes('application/json')) return response.json()

  return response.text()
}

function shouldCheckServerHealth(status: number) {
  return status >= 500
}

async function checkServerHealth() {
  serverHealthCheck ??= ky
    .get(requestUrl('/up'), {
      retry: 0,
      timeout: 3000,
    })
    .then(() => undefined)
    .catch(() => {
      notifyServerUnavailable()
    })
    .finally(() => {
      serverHealthCheck = null
    })

  await serverHealthCheck
}

function requestUrl(path: string) {
  if (typeof window === 'undefined') return path

  return new URL(path, window.location.origin).toString()
}

function notifyServerUnavailable() {
  if (typeof window === 'undefined') return

  window.dispatchEvent(new CustomEvent(SERVER_UNAVAILABLE_EVENT))
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
