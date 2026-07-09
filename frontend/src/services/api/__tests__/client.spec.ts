import { afterEach, describe, expect, it, vi } from 'vitest'
import { request, SERVER_UNAVAILABLE_EVENT, setAuthToken } from '../client'

function jsonResponse(body: unknown, status = 200, headers: HeadersInit = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  })
}

function responsePath(input: RequestInfo | URL) {
  if (input instanceof Request) return new URL(input.url).pathname
  return new URL(String(input), window.location.origin).pathname
}

describe('api client', () => {
  afterEach(() => {
    setAuthToken(null)
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('uses ky-backed requests with auth and locale headers', async () => {
    setAuthToken('Bearer test-token')
    const fetchMock = vi.fn<(input: RequestInfo | URL) => Promise<Response>>(async () =>
      jsonResponse({ ok: true }),
    )
    vi.stubGlobal('fetch', fetchMock)

    await expect(request<{ ok: boolean }>('/api/v1/projects')).resolves.toEqual({ ok: true })

    const sentRequest = fetchMock.mock.calls[0]?.[0] as Request
    expect(sentRequest).toBeInstanceOf(Request)
    expect(sentRequest.headers.get('Authorization')).toBe('Bearer test-token')
    expect(sentRequest.headers.get('Accept')).toBe('application/json')
  })

  it('does not run a health check for business validation errors', async () => {
    const fetchMock = vi.fn<(input: RequestInfo | URL) => Promise<Response>>(async () =>
      jsonResponse({ error: 'Invalid input' }, 422),
    )
    vi.stubGlobal('fetch', fetchMock)

    await expect(request('/api/v1/projects')).rejects.toMatchObject({
      status: 422,
      message: 'Invalid input',
    })
    expect(fetchMock).toHaveBeenCalledOnce()
  })

  it('checks /up and emits a server unavailable event after server errors', async () => {
    const serverUnavailable = vi.fn()
    window.addEventListener(SERVER_UNAVAILABLE_EVENT, serverUnavailable)

    try {
      const fetchMock = vi.fn<(input: RequestInfo | URL) => Promise<Response>>(async (input) => {
        if (responsePath(input) === '/up') return new Response('down', { status: 500 })

        return jsonResponse({ error: 'Server error' }, 500)
      })
      vi.stubGlobal('fetch', fetchMock)

      await expect(request('/api/v1/projects')).rejects.toMatchObject({
        status: 500,
        message: 'Server error',
      })

      expect(fetchMock).toHaveBeenCalledTimes(2)
      expect(fetchMock.mock.calls.map(([input]) => responsePath(input))).toEqual([
        '/api/v1/projects',
        '/up',
      ])
      expect(serverUnavailable).toHaveBeenCalledOnce()
    } finally {
      window.removeEventListener(SERVER_UNAVAILABLE_EVENT, serverUnavailable)
    }
  })
})
