///|
/// D1 Database schema definitions for Lifelog application
/// SQL statements for table creation and management

// =============================================================================
// Table Names
// =============================================================================

///|
/// Table name for lifelog entries
pub const TABLE_LIFELOG_ENTRIES : String = "lifelog_entries"

///|
/// Table name for lifelog segments
pub const TABLE_LIFELOG_SEGMENTS : String = "lifelog_segments"

///|
/// Table name for lifelog analyses
pub const TABLE_LIFELOG_ANALYSES : String = "lifelog_analyses"

///|
/// Table name for sync state
pub const TABLE_SYNC_STATE : String = "sync_state"

///|
/// Table name for analysis events
pub const TABLE_ANALYSIS_EVENTS : String = "analysis_events"

// =============================================================================
// Create Table Statements
// =============================================================================

///|
/// SQL to create lifelog_entries table
pub const CREATE_LIFELOG_ENTRIES : String =
  #|CREATE TABLE IF NOT EXISTS lifelog_entries (
  #|  id TEXT PRIMARY KEY,
  #|  title TEXT,
  #|  markdown TEXT,
  #|  start_time TEXT,
  #|  end_time TEXT,
  #|  start_epoch_ms INTEGER,
  #|  end_epoch_ms INTEGER,
  #|  is_starred INTEGER DEFAULT 0,
  #|  updated_at TEXT,
  #|  ingested_at TEXT DEFAULT CURRENT_TIMESTAMP,
  #|  timezone TEXT,
  #|  summary_hash TEXT,
  #|  last_analyzed_at TEXT
  #|)

///|
/// SQL to create index on lifelog_entries
pub const CREATE_LIFELOG_ENTRIES_INDEX : String =
  #|CREATE UNIQUE INDEX IF NOT EXISTS lifelog_entries_updated_idx
  #|ON lifelog_entries(id, updated_at)

///|
/// SQL to create lifelog_segments table
pub const CREATE_LIFELOG_SEGMENTS : String =
  #|CREATE TABLE IF NOT EXISTS lifelog_segments (
  #|  id INTEGER PRIMARY KEY AUTOINCREMENT,
  #|  entry_id TEXT NOT NULL REFERENCES lifelog_entries(id) ON DELETE CASCADE,
  #|  node_id TEXT NOT NULL,
  #|  path TEXT,
  #|  node_type TEXT,
  #|  content TEXT,
  #|  start_time TEXT,
  #|  end_time TEXT,
  #|  start_offset_ms INTEGER,
  #|  end_offset_ms INTEGER,
  #|  speaker_name TEXT,
  #|  speaker_identifier TEXT
  #|)

///|
/// SQL to create index on lifelog_segments
pub const CREATE_LIFELOG_SEGMENTS_INDEX : String =
  #|CREATE UNIQUE INDEX IF NOT EXISTS lifelog_segments_node_idx
  #|ON lifelog_segments(node_id)

///|
/// SQL to create lifelog_analyses table
pub const CREATE_LIFELOG_ANALYSES : String =
  #|CREATE TABLE IF NOT EXISTS lifelog_analyses (
  #|  id INTEGER PRIMARY KEY AUTOINCREMENT,
  #|  entry_id TEXT NOT NULL REFERENCES lifelog_entries(id) ON DELETE CASCADE,
  #|  model TEXT NOT NULL,
  #|  version TEXT DEFAULT 'v1',
  #|  payload_hash TEXT,
  #|  insights_json TEXT NOT NULL,
  #|  created_at TEXT DEFAULT CURRENT_TIMESTAMP
  #|)

///|
/// SQL to create index on lifelog_analyses
pub const CREATE_LIFELOG_ANALYSES_INDEX : String =
  #|CREATE UNIQUE INDEX IF NOT EXISTS lifelog_analysis_entry_idx
  #|ON lifelog_analyses(entry_id, version)

///|
/// SQL to create sync_state table
pub const CREATE_SYNC_STATE : String =
  #|CREATE TABLE IF NOT EXISTS sync_state (
  #|  key TEXT PRIMARY KEY,
  #|  value TEXT,
  #|  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  #|)

///|
/// SQL to create analysis_events table
pub const CREATE_ANALYSIS_EVENTS : String =
  #|CREATE TABLE IF NOT EXISTS analysis_events (
  #|  id INTEGER PRIMARY KEY AUTOINCREMENT,
  #|  entry_id TEXT,
  #|  status TEXT NOT NULL,
  #|  details TEXT,
  #|  created_at TEXT DEFAULT CURRENT_TIMESTAMP
  #|)

// =============================================================================
// Drop Table Statements
// =============================================================================

///|
/// SQL to drop lifelog_entries table
pub const DROP_LIFELOG_ENTRIES : String = "DROP TABLE IF EXISTS lifelog_entries"

///|
/// SQL to drop lifelog_segments table
pub const DROP_LIFELOG_SEGMENTS : String = "DROP TABLE IF EXISTS lifelog_segments"

///|
/// SQL to drop lifelog_analyses table
pub const DROP_LIFELOG_ANALYSES : String = "DROP TABLE IF EXISTS lifelog_analyses"

///|
/// SQL to drop sync_state table
pub const DROP_SYNC_STATE : String = "DROP TABLE IF EXISTS sync_state"

///|
/// SQL to drop analysis_events table
pub const DROP_ANALYSIS_EVENTS : String = "DROP TABLE IF EXISTS analysis_events"

// =============================================================================
// Query Templates
// =============================================================================

///|
/// SQL to insert or replace a lifelog entry
pub const UPSERT_LIFELOG_ENTRY : String =
  #|INSERT OR REPLACE INTO lifelog_entries
  #|(id, title, markdown, start_time, end_time, start_epoch_ms, end_epoch_ms,
  #| is_starred, updated_at, ingested_at, timezone, summary_hash, last_analyzed_at)
  #|VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

///|
/// SQL to insert a lifelog segment
pub const INSERT_LIFELOG_SEGMENT : String =
  #|INSERT INTO lifelog_segments
  #|(entry_id, node_id, path, node_type, content, start_time, end_time,
  #| start_offset_ms, end_offset_ms, speaker_name, speaker_identifier)
  #|VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

///|
/// SQL to insert or replace a lifelog segment (by node_id)
pub const UPSERT_LIFELOG_SEGMENT : String =
  #|INSERT OR REPLACE INTO lifelog_segments
  #|(entry_id, node_id, path, node_type, content, start_time, end_time,
  #| start_offset_ms, end_offset_ms, speaker_name, speaker_identifier)
  #|VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

///|
/// SQL to insert or replace a lifelog analysis
pub const UPSERT_LIFELOG_ANALYSIS : String =
  #|INSERT OR REPLACE INTO lifelog_analyses
  #|(entry_id, model, version, payload_hash, insights_json, created_at)
  #|VALUES (?, ?, ?, ?, ?, ?)

///|
/// SQL to update or insert sync state
pub const UPSERT_SYNC_STATE : String =
  #|INSERT OR REPLACE INTO sync_state (key, value, updated_at)
  #|VALUES (?, ?, datetime('now'))

///|
/// SQL to insert an analysis event
pub const INSERT_ANALYSIS_EVENT : String =
  #|INSERT INTO analysis_events (entry_id, status, details, created_at)
  #|VALUES (?, ?, ?, datetime('now'))

///|
/// SQL to select entry by ID
pub const SELECT_ENTRY_BY_ID : String =
  #|SELECT * FROM lifelog_entries WHERE id = ?

///|
/// SQL to select entries by date range
pub const SELECT_ENTRIES_BY_DATE_RANGE : String =
  #|SELECT * FROM lifelog_entries
  #|WHERE start_time >= ? AND start_time < ?
  #|ORDER BY start_time DESC

///|
/// SQL to select entries with limit and offset (for pagination)
pub const SELECT_ENTRIES_PAGINATED : String =
  #|SELECT * FROM lifelog_entries
  #|ORDER BY start_time DESC
  #|LIMIT ? OFFSET ?

///|
/// SQL to select segments by entry ID
pub const SELECT_SEGMENTS_BY_ENTRY_ID : String =
  #|SELECT * FROM lifelog_segments
  #|WHERE entry_id = ?
  #|ORDER BY start_offset_ms ASC

///|
/// SQL to select analysis by entry ID
pub const SELECT_ANALYSIS_BY_ENTRY_ID : String =
  #|SELECT * FROM lifelog_analyses
  #|WHERE entry_id = ?
  #|ORDER BY created_at DESC
  #|LIMIT 1

///|
/// SQL to select analysis by entry ID and version
pub const SELECT_ANALYSIS_BY_ENTRY_AND_VERSION : String =
  #|SELECT * FROM lifelog_analyses
  #|WHERE entry_id = ? AND version = ?

///|
/// SQL to get sync state by key
pub const SELECT_SYNC_STATE : String =
  #|SELECT * FROM sync_state WHERE key = ?

///|
/// SQL to get recent analysis events
pub const SELECT_RECENT_ANALYSIS_EVENTS : String =
  #|SELECT * FROM analysis_events
  #|ORDER BY created_at DESC
  #|LIMIT ?

///|
/// SQL to delete segments by entry ID
pub const DELETE_SEGMENTS_BY_ENTRY_ID : String =
  #|DELETE FROM lifelog_segments WHERE entry_id = ?

///|
/// SQL to delete entry by ID
pub const DELETE_ENTRY_BY_ID : String =
  #|DELETE FROM lifelog_entries WHERE id = ?

///|
/// SQL to count entries
pub const COUNT_ENTRIES : String =
  #|SELECT COUNT(*) as count FROM lifelog_entries

///|
/// SQL to count entries needing analysis
pub const COUNT_ENTRIES_NEEDING_ANALYSIS : String =
  #|SELECT COUNT(*) as count FROM lifelog_entries
  #|WHERE last_analyzed_at IS NULL OR last_analyzed_at < updated_at

// =============================================================================
// Sync State Keys
// =============================================================================

///|
/// Sync state key for last sync timestamp
pub const SYNC_KEY_LAST_SYNCED : String = "last_synced_at"

///|
/// Sync state key for last analyzed entry
pub const SYNC_KEY_LAST_ANALYZED : String = "last_analyzed_at"

///|
/// Sync state key for sync cursor/token
pub const SYNC_KEY_CURSOR : String = "sync_cursor"
