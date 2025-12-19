import { eq } from 'drizzle-orm'
import type { Database } from '../db/client'
import { syncState } from '../db/schema'

export const getSyncStateValue = async (db: Database, key: string) => {
  const rows = await db.select().from(syncState).where(eq(syncState.key, key)).limit(1)
  return rows[0]?.value ?? null
}

export const upsertSyncState = async (db: Database, key: string, value: string) => {
  await db
    .insert(syncState)
    .values({ key, value })
    .onConflictDoUpdate({
      target: syncState.key,
      set: {
        value,
        updatedAt: new Date().toISOString()
      }
    })
}

export const deleteSyncStateKey = async (db: Database, key: string) => {
  await db.delete(syncState).where(eq(syncState.key, key))
}
