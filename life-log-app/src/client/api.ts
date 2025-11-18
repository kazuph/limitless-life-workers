import type { TimelineResponse } from './types'

const buildHeaders = () => {
  const headers: Record<string, string> = { Accept: 'application/json' }
  if (import.meta.env?.VITE_E2E === '1') {
    headers['x-test-skip-sync'] = '1'
    headers['x-test-skip-analysis'] = '1'
  }
  return headers
}

export const fetchTimeline = async (): Promise<TimelineResponse> => {
  const response = await fetch('/api/lifelogs', {
    headers: buildHeaders()
  })

  if (!response.ok) {
    throw new Error('Failed to load lifelog timeline')
  }

  return (await response.json()) as TimelineResponse
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
