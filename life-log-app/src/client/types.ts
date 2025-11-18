import type { AnalysisJSON } from '../types/analysis'

export type TimelineSegment = {
  id: string
  content: string | null
  startTime: string | null
  endTime: string | null
  nodeType: string | null
  speakerName: string | null
}

export type AnalysisPayload = AnalysisJSON | null

export type TimelineEntry = {
  id: string
  title: string | null
  startTime: string | null
  endTime: string | null
  dateLabel: string | null
  durationMinutes: number | null
  segments: TimelineSegment[]
  analysis?: AnalysisPayload
  markdown?: string | null
}

export type IntegrationSuggestion = {
  id: string
  title: string
  description: string
  action: string
  target: string
}

export type TimelineResponse = {
  lastSyncedAt: string | null
  lastAnalyzedAt: string | null
  timeline: TimelineEntry[]
  integrations: IntegrationSuggestion[]
}
