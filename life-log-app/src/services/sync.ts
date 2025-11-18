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
  const since = opts.fullRefresh ? null : await getSyncStateValue(db, LAST_UPDATED_KEY)

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
        for (const segment of segments) {
          await db.insert(lifelogSegments).values(segment)
        }
        console.log(`[Sync] Inserted ${segments.length} segments for entry ${lifelog.id}`)
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

const chunkArray = <T>(values: T[], chunkSize: number): T[][] => {
  const result: T[][] = []
  for (let i = 0; i < values.length; i += chunkSize) {
    result.push(values.slice(i, i + chunkSize))
  }
  return result
}
