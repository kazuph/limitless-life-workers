import { desc, eq } from 'drizzle-orm'
import type { Database } from '../db/client'
import { analysisEvents } from '../db/schema'

export const logAnalysisEvent = async (
  db: Database,
  event: { entryId?: string | null; status: 'success' | 'error'; details?: string }
) => {
  await db.insert(analysisEvents).values({
    entryId: event.entryId ?? null,
    status: event.status,
    details: event.details ?? null
  })
}

export const getAnalysisEvents = async (db: Database, limit = 10) => {
  return db
    .select()
    .from(analysisEvents)
    .orderBy(desc(analysisEvents.createdAt))
    .limit(limit)
}
