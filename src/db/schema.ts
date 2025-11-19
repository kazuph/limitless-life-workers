import { sql } from 'drizzle-orm'
import { integer, sqliteTable, text, uniqueIndex } from 'drizzle-orm/sqlite-core'

export const lifelogEntries = sqliteTable(
  'lifelog_entries',
  {
    id: text('id').primaryKey(),
    title: text('title'),
    markdown: text('markdown'),
    startTime: text('start_time'),
    endTime: text('end_time'),
    startEpochMs: integer('start_epoch_ms'),
    endEpochMs: integer('end_epoch_ms'),
    isStarred: integer('is_starred', { mode: 'boolean' }).default(false),
    updatedAt: text('updated_at'),
    ingestedAt: text('ingested_at').default(sql`CURRENT_TIMESTAMP`),
    timezone: text('timezone'),
    summaryHash: text('summary_hash'),
    lastAnalyzedAt: text('last_analyzed_at')
  },
  (table) => ({
    updatedIdx: uniqueIndex('lifelog_entries_updated_idx').on(table.id, table.updatedAt)
  })
)

export const lifelogSegments = sqliteTable(
  'lifelog_segments',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    entryId: text('entry_id')
      .references(() => lifelogEntries.id, { onDelete: 'cascade' })
      .notNull(),
    nodeId: text('node_id').notNull(),
    path: text('path'),
    nodeType: text('node_type'),
    content: text('content'),
    startTime: text('start_time'),
    endTime: text('end_time'),
    startOffsetMs: integer('start_offset_ms'),
    endOffsetMs: integer('end_offset_ms'),
    speakerName: text('speaker_name'),
    speakerIdentifier: text('speaker_identifier')
  },
  (table) => ({
    nodeIdx: uniqueIndex('lifelog_segments_node_idx').on(table.nodeId)
  })
)

export const lifelogAnalyses = sqliteTable(
  'lifelog_analyses',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    entryId: text('entry_id')
      .references(() => lifelogEntries.id, { onDelete: 'cascade' })
      .notNull(),
    model: text('model').notNull(),
    version: text('version').default('v1'),
    payloadHash: text('payload_hash'),
    insightsJson: text('insights_json').notNull(),
    createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`)
  },
  (table) => ({
    entryIdx: uniqueIndex('lifelog_analysis_entry_idx').on(table.entryId, table.version)
  })
)

export const syncState = sqliteTable('sync_state', {
  key: text('key').primaryKey(),
  value: text('value'),
  updatedAt: text('updated_at').default(sql`CURRENT_TIMESTAMP`)
})

export const analysisEvents = sqliteTable('analysis_events', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  entryId: text('entry_id'),
  status: text('status').notNull(),
  details: text('details'),
  createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`)
})

export type LifelogEntry = typeof lifelogEntries.$inferSelect
export type NewLifelogEntry = typeof lifelogEntries.$inferInsert
export type LifelogSegment = typeof lifelogSegments.$inferSelect
export type NewLifelogSegment = typeof lifelogSegments.$inferInsert
export type LifelogAnalysis = typeof lifelogAnalyses.$inferSelect
export type NewLifelogAnalysis = typeof lifelogAnalyses.$inferInsert
export type AnalysisEvent = typeof analysisEvents.$inferSelect
