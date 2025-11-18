const SCHEMA_STATEMENTS = [
  'PRAGMA foreign_keys = ON;',
  `CREATE TABLE IF NOT EXISTS lifelog_entries (
    id TEXT PRIMARY KEY,
    title TEXT,
    markdown TEXT,
    start_time TEXT,
    end_time TEXT,
    start_epoch_ms INTEGER,
    end_epoch_ms INTEGER,
    is_starred INTEGER DEFAULT 0,
    updated_at TEXT,
    ingested_at TEXT DEFAULT (CURRENT_TIMESTAMP),
    timezone TEXT,
    summary_hash TEXT,
    last_analyzed_at TEXT
  );`,
  `CREATE UNIQUE INDEX IF NOT EXISTS lifelog_entries_updated_idx
    ON lifelog_entries (id, updated_at);`,
  `CREATE TABLE IF NOT EXISTS lifelog_segments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entry_id TEXT NOT NULL,
    node_id TEXT NOT NULL,
    path TEXT,
    node_type TEXT,
    content TEXT,
    start_time TEXT,
    end_time TEXT,
    start_offset_ms INTEGER,
    end_offset_ms INTEGER,
    speaker_name TEXT,
    speaker_identifier TEXT,
    FOREIGN KEY (entry_id) REFERENCES lifelog_entries(id) ON DELETE CASCADE
  );`,
  `CREATE UNIQUE INDEX IF NOT EXISTS lifelog_segments_node_idx
    ON lifelog_segments (node_id);`,
  `CREATE TABLE IF NOT EXISTS lifelog_analyses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entry_id TEXT NOT NULL,
    model TEXT NOT NULL,
    version TEXT DEFAULT 'v1',
    payload_hash TEXT,
    insights_json TEXT NOT NULL,
    created_at TEXT DEFAULT (CURRENT_TIMESTAMP),
    FOREIGN KEY (entry_id) REFERENCES lifelog_entries(id) ON DELETE CASCADE
  );`,
  `CREATE UNIQUE INDEX IF NOT EXISTS lifelog_analysis_entry_idx
    ON lifelog_analyses (entry_id, version);`,
  `CREATE TABLE IF NOT EXISTS sync_state (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TEXT DEFAULT (CURRENT_TIMESTAMP)
  );`,
  `CREATE TABLE IF NOT EXISTS analysis_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entry_id TEXT,
    status TEXT NOT NULL,
    details TEXT,
    created_at TEXT DEFAULT (CURRENT_TIMESTAMP)
  );`
]

let initPromise: Promise<void> | null = null

export const ensureSchema = async (db: D1Database) => {
  if (!initPromise) {
    initPromise = (async () => {
      for (const statement of SCHEMA_STATEMENTS) {
        await db.prepare(statement).run()
      }
    })().catch((error) => {
      initPromise = null
      throw error
    })
  }

  return initPromise
}
