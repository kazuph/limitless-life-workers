import { desc, inArray } from 'drizzle-orm'
import type { Database } from '../db/client'
import {
  lifelogAnalyses,
  lifelogEntries,
  lifelogSegments
} from '../db/schema'
import type { AnalysisJSON } from '../types/analysis'

export type TimelineSegmentDTO = {
  id: string
  content: string | null
  startTime: string | null
  endTime: string | null
  nodeType: string | null
  speakerName: string | null
}

export type TimelineEntryDTO = {
  id: string
  title: string | null
  startTime: string | null
  endTime: string | null
  dateLabel: string | null
  durationMinutes: number | null
  segments: TimelineSegmentDTO[]
  markdown?: string | null
  analysis?: AnalysisJSON | null
}

export const getTimelineSnapshot = async (
  db: Database,
  opts: { limit?: number } = {}
): Promise<TimelineEntryDTO[]> => {
  const limit = opts.limit ?? 14
  const entries = await db
    .select({
      id: lifelogEntries.id,
      title: lifelogEntries.title,
      startTime: lifelogEntries.startTime,
      endTime: lifelogEntries.endTime,
      markdown: lifelogEntries.markdown
    })
    .from(lifelogEntries)
    .orderBy(desc(lifelogEntries.startTime))
    .limit(limit)

  if (!entries.length) {
    return []
  }

  const ids = entries.map((entry) => entry.id)
  const segments = await db
    .select({
      entryId: lifelogSegments.entryId,
      nodeId: lifelogSegments.nodeId,
      content: lifelogSegments.content,
      startTime: lifelogSegments.startTime,
      endTime: lifelogSegments.endTime,
      nodeType: lifelogSegments.nodeType,
      speakerName: lifelogSegments.speakerName
    })
    .from(lifelogSegments)
    .where(inArray(lifelogSegments.entryId, ids))

  const analyses = await db
    .select({
      entryId: lifelogAnalyses.entryId,
      json: lifelogAnalyses.insightsJson
    })
    .from(lifelogAnalyses)
    .where(inArray(lifelogAnalyses.entryId, ids))

  const analysisMap = new Map<string, AnalysisJSON>()
  for (const analysis of analyses) {
    if (analysis.entryId && analysis.json) {
      try {
        analysisMap.set(analysis.entryId, JSON.parse(analysis.json) as AnalysisJSON)
      } catch (error) {
        console.error('Failed to parse analysis JSON', error)
      }
    }
  }

  return entries.map((entry) => {
    const entrySegments = segments
      .filter((segment) => segment.entryId === entry.id)
      .map((segment) => ({
        id: segment.nodeId ?? crypto.randomUUID(),
        content: segment.content ?? null,
        startTime: segment.startTime ?? null,
        endTime: segment.endTime ?? null,
        nodeType: segment.nodeType ?? null,
        speakerName: segment.speakerName ?? null
      }))

    return {
      id: entry.id,
      title: entry.title ?? 'Untitled',
      startTime: entry.startTime ?? null,
      endTime: entry.endTime ?? null,
      dateLabel: entry.startTime ? entry.startTime.split('T')[0] : null,
      durationMinutes: computeDuration(entry.startTime, entry.endTime),
      segments: entrySegments,
      markdown: entry.markdown ?? null,
      analysis: analysisMap.get(entry.id) ?? null
    } satisfies TimelineEntryDTO
  })
}

const computeDuration = (start?: string | null, end?: string | null) => {
  if (!start || !end) return null
  const startDate = new Date(start)
  const endDate = new Date(end)
  const diff = endDate.getTime() - startDate.getTime()
  if (Number.isNaN(diff)) return null
  return Math.max(Math.round(diff / 60000), 1)
}
