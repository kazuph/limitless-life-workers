import { desc, inArray, sql } from 'drizzle-orm'
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
  opts: { days?: number; offset?: number } = {}
): Promise<TimelineEntryDTO[]> => {
  const days = opts.days ?? 7
  const offset = opts.offset ?? 0

  // Calculate date range
  const now = new Date()
  const startDate = new Date(now)
  startDate.setDate(startDate.getDate() - (days + offset))
  const endDate = new Date(now)
  endDate.setDate(endDate.getDate() - offset)

  const entries = await db
    .select({
      id: lifelogEntries.id,
      title: lifelogEntries.title,
      startTime: lifelogEntries.startTime,
      endTime: lifelogEntries.endTime,
      markdown: lifelogEntries.markdown
    })
    .from(lifelogEntries)
    .where(sql`${lifelogEntries.startTime} >= ${startDate.toISOString()} AND ${lifelogEntries.startTime} < ${endDate.toISOString()}`)
    .orderBy(desc(lifelogEntries.startTime))

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
      dateLabel: entry.startTime ? formatLocalDate(entry.startTime) : null,
      durationMinutes: computeDuration(entry.startTime, entry.endTime),
      segments: entrySegments,
      markdown: entry.markdown ?? null,
      analysis: analysisMap.get(entry.id) ?? null
    } satisfies TimelineEntryDTO
  })
}

const formatLocalDate = (isoString: string): string => {
  const date = new Date(isoString)
  // Convert to JST (UTC+9) by adding 9 hours
  const jstDate = new Date(date.getTime() + 9 * 60 * 60 * 1000)
  // Use UTC methods on the adjusted date to get JST values
  const year = jstDate.getUTCFullYear()
  const month = String(jstDate.getUTCMonth() + 1).padStart(2, '0')
  const day = String(jstDate.getUTCDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

const computeDuration = (start?: string | null, end?: string | null) => {
  if (!start || !end) return null
  const startDate = new Date(start)
  const endDate = new Date(end)
  const diff = endDate.getTime() - startDate.getTime()
  if (Number.isNaN(diff)) return null
  return Math.max(Math.round(diff / 60000), 1)
}
