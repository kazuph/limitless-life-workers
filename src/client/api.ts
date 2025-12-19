import type { TimelineResponse } from './types'

const buildHeaders = () => {
  const headers: Record<string, string> = { Accept: 'application/json' }
  if (import.meta.env?.VITE_E2E === '1') {
    headers['x-test-skip-sync'] = '1'
    headers['x-test-skip-analysis'] = '1'
  }

  // Extract basic auth credentials from URL if present
  const url = new URL(window.location.href)
  if (url.username && url.password) {
    const credentials = btoa(`${url.username}:${url.password}`)
    headers['Authorization'] = `Basic ${credentials}`
  }

  return headers
}

export const fetchTimeline = async (
  opts: { days?: number; offset?: number; detail?: boolean } = {}
): Promise<TimelineResponse> => {
  const params = new URLSearchParams()
  if (opts.days !== undefined) params.set('days', opts.days.toString())
  if (opts.offset !== undefined) params.set('offset', opts.offset.toString())
  if (opts.detail) params.set('detail', '1')

  const url = `/api/lifelogs${params.toString() ? `?${params.toString()}` : ''}`
  const response = await fetch(url, {
    headers: buildHeaders()
  })

  if (!response.ok) {
    throw new Error('Failed to load lifelog timeline')
  }

  return (await response.json()) as TimelineResponse
}

export const fetchTimelineEntry = async (entryId: string) => {
  const response = await fetch(`/api/lifelogs/${entryId}`, {
    headers: buildHeaders()
  })
  if (!response.ok) {
    throw new Error('Failed to load entry details')
  }
  return (await response.json()) as TimelineResponse['timeline'][number]
}

export const fetchDaySummary = async (date: string) => {
  const response = await fetch(`/api/day-summary?date=${encodeURIComponent(date)}`, {
    headers: buildHeaders()
  })
  if (!response.ok) {
    throw new Error('Failed to load day summary')
  }
  return (await response.json()) as {
    date: string
    tweets: string[]
    generatedAt: string
    source: 'cached' | 'generated' | 'unavailable'
    model?: string
  }
}

export const triggerSync = async () => {
  const response = await fetch('/api/sync', {
    method: 'POST',
    headers: buildHeaders()
  })
  if (!response.ok) {
    throw new Error('Sync request failed')
  }
  return response.json()
}

export const triggerAnalysis = async (entryId: string) => {
  const response = await fetch(`/api/analyze/${entryId}`, {
    method: 'POST',
    headers: buildHeaders()
  })
  if (!response.ok) {
    throw new Error('Analysis request failed')
  }
  return response.json()
}
