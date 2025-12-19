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
  opts: { days?: number; offset?: number; detail?: boolean; analysisLimit?: number } = {}
): Promise<TimelineEntryDTO[]> => {
  const days = opts.days ?? 7
  const offset = opts.offset ?? 0
  const detail = opts.detail ?? true
  const analysisLimit = opts.analysisLimit ?? 4

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
      markdown: detail ? lifelogEntries.markdown : sql<null>`null`
    })
    .from(lifelogEntries)
    .where(sql`${lifelogEntries.startTime} >= ${startDate.toISOString()} AND ${lifelogEntries.startTime} < ${endDate.toISOString()}`)
    .orderBy(desc(lifelogEntries.startTime))

  if (!entries.length) {
    return []
  }

  const ids = entries.map((entry) => entry.id)
  const segments = detail
    ? await selectInChunks(ids, CHUNK_SIZE, (idsChunk) =>
        db
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
          .where(inArray(lifelogSegments.entryId, idsChunk))
      )
    : []

  const analysisIds = detail ? ids : ids.slice(0, analysisLimit)
  const analyses = analysisIds.length
    ? await selectInChunks(analysisIds, CHUNK_SIZE, (idsChunk) =>
        db
          .select({
            entryId: lifelogAnalyses.entryId,
            json: lifelogAnalyses.insightsJson
          })
          .from(lifelogAnalyses)
          .where(inArray(lifelogAnalyses.entryId, idsChunk))
      )
    : []

  const analysisMap = new Map<string, AnalysisJSON>()
  for (const analysis of analyses) {
    if (analysis.entryId && analysis.json) {
      try {
        const parsed = JSON.parse(analysis.json) as AnalysisJSON
        analysisMap.set(analysis.entryId, detail ? parsed : trimAnalysis(parsed))
      } catch (error) {
        console.error('Failed to parse analysis JSON', error)
      }
    }
  }

  return entries.map((entry) => {
    const entrySegments = detail
      ? segments
          .filter((segment) => segment.entryId === entry.id)
          .map((segment) => ({
            id: segment.nodeId ?? crypto.randomUUID(),
            content: segment.content ?? null,
            startTime: segment.startTime ?? null,
            endTime: segment.endTime ?? null,
            nodeType: segment.nodeType ?? null,
            speakerName: segment.speakerName ?? null
          }))
      : []

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

export const getTimelineEntryDetail = async (
  db: Database,
  entryId: string
): Promise<TimelineEntryDTO | null> => {
  const entry = await db
    .select({
      id: lifelogEntries.id,
      title: lifelogEntries.title,
      startTime: lifelogEntries.startTime,
      endTime: lifelogEntries.endTime,
      markdown: lifelogEntries.markdown
    })
    .from(lifelogEntries)
    .where(sql`${lifelogEntries.id} = ${entryId}`)
    .limit(1)
    .then((rows) => rows[0])

  if (!entry) return null

  const [segments, analyses] = await Promise.all([
    db
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
      .where(sql`${lifelogSegments.entryId} = ${entryId}`),
    db
      .select({
        entryId: lifelogAnalyses.entryId,
        json: lifelogAnalyses.insightsJson
      })
      .from(lifelogAnalyses)
      .where(sql`${lifelogAnalyses.entryId} = ${entryId}`)
  ])

  let analysis: AnalysisJSON | null = null
  const analysisRow = analyses[0]
  if (analysisRow?.json) {
    try {
      analysis = JSON.parse(analysisRow.json) as AnalysisJSON
    } catch (error) {
      console.error('Failed to parse analysis JSON', error)
    }
  }

  const entrySegments = segments.map((segment) => ({
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
    analysis
  }
}

const CHUNK_SIZE = 50

const selectInChunks = async <TResult>(
  ids: string[],
  chunkSize: number,
  runQuery: (chunk: string[]) => Promise<TResult[]>
): Promise<TResult[]> => {
  const chunks: string[][] = []
  for (let i = 0; i < ids.length; i += chunkSize) {
    const chunk = ids.slice(i, i + chunkSize)
    if (chunk.length) {
      chunks.push(chunk)
    }
  }

  if (!chunks.length) {
    return []
  }

  const results = await Promise.all(chunks.map(runQuery))
  return results.flat()
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

const trimAnalysis = (analysis: AnalysisJSON): AnalysisJSON => ({
  summary: analysis.summary,
  mood: analysis.mood,
  tags: analysis.tags?.slice(0, 2) ?? [],
  time_blocks: analysis.time_blocks?.slice(0, 3) ?? [],
  action_items: analysis.action_items?.slice(0, 3) ?? [],
  suggestions: analysis.suggestions?.slice(0, 2) ?? []
})
