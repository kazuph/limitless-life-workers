import { eq } from 'drizzle-orm'
import type { Database } from '../db/client'
import { lifelogEntries, lifelogSegments } from '../db/schema'
import type { Bindings } from '../env'
import { lifelogToEntry, lifelogToSegments, lifelogHashSeed } from '../lib/lifelog-transformers'
import { toSha1 } from '../lib/hash'
import { fetchLifelogs } from './limitless'
import { getSyncStateValue, upsertSyncState } from './state'

const LAST_UPDATED_KEY = 'lifelog:lastUpdatedAt'
const LAST_SYNC_KEY = 'lifelog:lastSyncedAt'
// D1 allows up to 100 bound parameters per statement.
// Each segment insert binds 11 params, so batch at most 9 rows (9 * 11 = 99).
const SEGMENT_BATCH_SIZE = 9

export type SyncStats = {
  processed: number
  lastUpdatedAt?: string | null
}

export const syncLifelogs = async (
  db: Database,
  env: Bindings,
  opts: { fullRefresh?: boolean } = {}
): Promise<SyncStats> => {
  const apiKey = env.LIMITLESS_API_KEY

  if (env.DISABLE_LIMITLESS_SYNC === '1' || apiKey === 'skip') {
    console.info('Limitless sync disabled via DISABLE_LIMITLESS_SYNC flag; skipping fetch.')
    return { processed: 0, lastUpdatedAt: null }
  }
  if (!apiKey) {
    console.warn('Missing LIMITLESS_API_KEY; skipping Limitless sync.')
    return { processed: 0, lastUpdatedAt: null }
  }
  let cursor: string | undefined
  let processed = 0
  let lastUpdatedAt: string | null = null
  let attempted = false
  const storedSince = await getSyncStateValue(db, LAST_UPDATED_KEY)

  // Determine the starting point for sync
  // - fullRefresh: fetch all data (since = null)
  // - has storedSince: fetch from backfillWindow (6 hours before last sync)
  // - no storedSince: fetch last 7 days only to avoid excessive API calls on first run
  const since = opts.fullRefresh
    ? null
    : storedSince
      ? storedSince
      : getDefaultStartDate()

  do {
    attempted = true
    const response = await fetchLifelogs(env, {
      cursor,
      start: since ? backfillWindow(since) : undefined,
      limit: 100
    })

    for (const lifelog of response.data.lifelogs) {
      const entry = lifelogToEntry(lifelog)
      entry.summaryHash = await toSha1(lifelogHashSeed(lifelog))

      await db
        .insert(lifelogEntries)
        .values(entry)
        .onConflictDoUpdate({
          target: lifelogEntries.id,
          set: {
            title: entry.title,
            markdown: entry.markdown,
            startTime: entry.startTime,
            endTime: entry.endTime,
            startEpochMs: entry.startEpochMs,
            endEpochMs: entry.endEpochMs,
            isStarred: entry.isStarred,
            updatedAt: entry.updatedAt,
            timezone: entry.timezone,
            summaryHash: entry.summaryHash
          }
        })

      const segments = lifelogToSegments(lifelog)
      console.log(`[Sync] Entry ${lifelog.id}: title="${lifelog.title}", contents count=${lifelog.contents?.length || 0}, segments count=${segments.length}`)
      if (lifelog.contents && lifelog.contents.length > 0) {
        console.log('[Sync] Sample content node:', JSON.stringify(lifelog.contents[0], null, 2))
      }
      if (segments.length) {
        await db.delete(lifelogSegments).where(eq(lifelogSegments.entryId, lifelog.id))
        const batches = chunkArray(segments, SEGMENT_BATCH_SIZE)
        for (const batch of batches) {
          await db.insert(lifelogSegments).values(batch)
        }
        console.log(`[Sync] Inserted ${segments.length} segments for entry ${lifelog.id} in ${batches.length} batches (size ${SEGMENT_BATCH_SIZE})`)
      } else {
        console.warn(`[Sync] No segments for entry ${lifelog.id}`)
      }

      processed += 1
      if (!lastUpdatedAt || (entry.updatedAt && entry.updatedAt > lastUpdatedAt)) {
        lastUpdatedAt = entry.updatedAt ?? lastUpdatedAt
      }
    }

    cursor = response.meta.lifelogs?.nextCursor ?? undefined
  } while (cursor)

  if (lastUpdatedAt) {
    await upsertSyncState(db, LAST_UPDATED_KEY, lastUpdatedAt)
  }
  if (attempted) {
    await upsertSyncState(db, LAST_SYNC_KEY, new Date().toISOString())
  }

  return { processed, lastUpdatedAt }
}

export const getLastSyncedAt = async (db: Database) => getSyncStateValue(db, LAST_SYNC_KEY)

const backfillWindow = (since: string) => {
  const start = new Date(since)
  if (!Number.isNaN(start.getTime())) {
    start.setHours(start.getHours() - 6)
    return start.toISOString()
  }
  return undefined
}

const getDefaultStartDate = () => {
  // Default to last 7 days on first sync to avoid excessive API calls
  const start = new Date()
  start.setDate(start.getDate() - 7)
  return start.toISOString()
}

const chunkArray = <T>(values: T[], chunkSize: number): T[][] => {
  const result: T[][] = []
  for (let i = 0; i < values.length; i += chunkSize) {
    result.push(values.slice(i, i + chunkSize))
  }
  return result
}
