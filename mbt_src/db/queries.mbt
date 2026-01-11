///|
/// D1 Database query functions for Lifelog application
/// Uses mizchi/cloudflare for D1 bindings

// =============================================================================
// Database Initialization
// =============================================================================

///|
/// Initialize all database tables
pub async fn init_database(db : @cloudflare.D1Database) -> Unit raise {
  // Create tables
  let _ = db.prepare(CREATE_LIFELOG_ENTRIES).run()
  let _ = db.prepare(CREATE_LIFELOG_SEGMENTS).run()
  let _ = db.prepare(CREATE_LIFELOG_ANALYSES).run()
  let _ = db.prepare(CREATE_SYNC_STATE).run()
  let _ = db.prepare(CREATE_ANALYSIS_EVENTS).run()

  // Create indexes
  let _ = db.prepare(CREATE_LIFELOG_ENTRIES_INDEX).run()
  let _ = db.prepare(CREATE_LIFELOG_SEGMENTS_INDEX).run()
  let _ = db.prepare(CREATE_LIFELOG_ANALYSES_INDEX).run()
}

// =============================================================================
// LifelogEntry CRUD
// =============================================================================

///|
/// Insert or update a lifelog entry
pub async fn upsert_entry(
  db : @cloudflare.D1Database,
  entry : @types.LifelogEntry
) -> @cloudflare.D1Result raise {
  db
    .prepare(UPSERT_LIFELOG_ENTRY)
    .bind([
      @core.any(entry.id),
      @core.any(entry.title.unwrap_or("")),
      @core.any(entry.markdown.unwrap_or("")),
      @core.any(entry.start_time.unwrap_or("")),
      @core.any(entry.end_time.unwrap_or("")),
      @core.any(entry.start_epoch_ms.unwrap_or(0)),
      @core.any(entry.end_epoch_ms.unwrap_or(0)),
      @core.any(if entry.is_starred { 1 } else { 0 }),
      @core.any(entry.updated_at.unwrap_or("")),
      @core.any(entry.ingested_at.unwrap_or("")),
      @core.any(entry.timezone.unwrap_or("")),
      @core.any(entry.summary_hash.unwrap_or("")),
      @core.any(entry.last_analyzed_at.unwrap_or("")),
    ])
    .run()
}

///|
/// Get entry by ID
pub async fn get_entry_by_id(
  db : @cloudflare.D1Database,
  id : String
) -> @types.LifelogEntry? raise {
  let row = db.prepare(SELECT_ENTRY_BY_ID).bind1(@core.any(id)).first()
  match row {
    Some(r) => Some(parse_entry_row(r))
    None => None
  }
}

///|
/// Get entries by date range
pub async fn get_entries_by_date_range(
  db : @cloudflare.D1Database,
  start_date : String,
  end_date : String
) -> Array[@types.LifelogEntry] raise {
  let result = db
    .prepare(SELECT_ENTRIES_BY_DATE_RANGE)
    .bind2(@core.any(start_date), @core.any(end_date))
    .all()
  let entries : Array[@types.LifelogEntry] = []
  if result.success() {
    let rows = result.get_results()
    for row in rows {
      entries.push(parse_entry_row(row))
    }
  }
  entries
}

///|
/// Get entries with pagination
pub async fn get_entries_paginated(
  db : @cloudflare.D1Database,
  limit : Int,
  offset : Int
) -> Array[@types.LifelogEntry] raise {
  let result = db
    .prepare(SELECT_ENTRIES_PAGINATED)
    .bind2(@core.any(limit), @core.any(offset))
    .all()
  let entries : Array[@types.LifelogEntry] = []
  if result.success() {
    let rows = result.get_results()
    for row in rows {
      entries.push(parse_entry_row(row))
    }
  }
  entries
}

///|
/// Delete entry by ID
pub async fn delete_entry(
  db : @cloudflare.D1Database,
  id : String
) -> @cloudflare.D1Result raise {
  db.prepare(DELETE_ENTRY_BY_ID).bind1(@core.any(id)).run()
}

///|
/// Count total entries
pub async fn count_entries(db : @cloudflare.D1Database) -> Int raise {
  let count = db.prepare(COUNT_ENTRIES).first_col("count")
  match count {
    Some(c) => c.cast()
    None => 0
  }
}

// =============================================================================
// LifelogSegment CRUD
// =============================================================================

///|
/// Insert a segment
pub async fn insert_segment(
  db : @cloudflare.D1Database,
  segment : @types.LifelogSegment
) -> @cloudflare.D1Result raise {
  db
    .prepare(INSERT_LIFELOG_SEGMENT)
    .bind([
      @core.any(segment.entry_id),
      @core.any(segment.node_id),
      @core.any(segment.path.unwrap_or("")),
      @core.any(segment.node_type.unwrap_or("")),
      @core.any(segment.content.unwrap_or("")),
      @core.any(segment.start_time.unwrap_or("")),
      @core.any(segment.end_time.unwrap_or("")),
      @core.any(segment.start_offset_ms.unwrap_or(0)),
      @core.any(segment.end_offset_ms.unwrap_or(0)),
      @core.any(segment.speaker_name.unwrap_or("")),
      @core.any(segment.speaker_identifier.unwrap_or("")),
    ])
    .run()
}

///|
/// Upsert a segment (by node_id)
pub async fn upsert_segment(
  db : @cloudflare.D1Database,
  segment : @types.LifelogSegment
) -> @cloudflare.D1Result raise {
  db
    .prepare(UPSERT_LIFELOG_SEGMENT)
    .bind([
      @core.any(segment.entry_id),
      @core.any(segment.node_id),
      @core.any(segment.path.unwrap_or("")),
      @core.any(segment.node_type.unwrap_or("")),
      @core.any(segment.content.unwrap_or("")),
      @core.any(segment.start_time.unwrap_or("")),
      @core.any(segment.end_time.unwrap_or("")),
      @core.any(segment.start_offset_ms.unwrap_or(0)),
      @core.any(segment.end_offset_ms.unwrap_or(0)),
      @core.any(segment.speaker_name.unwrap_or("")),
      @core.any(segment.speaker_identifier.unwrap_or("")),
    ])
    .run()
}

///|
/// Get segments by entry ID
pub async fn get_segments_by_entry_id(
  db : @cloudflare.D1Database,
  entry_id : String
) -> Array[@types.LifelogSegment] raise {
  let result = db
    .prepare(SELECT_SEGMENTS_BY_ENTRY_ID)
    .bind1(@core.any(entry_id))
    .all()
  let segments : Array[@types.LifelogSegment] = []
  if result.success() {
    let rows = result.get_results()
    for row in rows {
      segments.push(parse_segment_row(row))
    }
  }
  segments
}

///|
/// Delete segments by entry ID
pub async fn delete_segments_by_entry_id(
  db : @cloudflare.D1Database,
  entry_id : String
) -> @cloudflare.D1Result raise {
  db.prepare(DELETE_SEGMENTS_BY_ENTRY_ID).bind1(@core.any(entry_id)).run()
}

// =============================================================================
// LifelogAnalysis CRUD
// =============================================================================

///|
/// Upsert an analysis
pub async fn upsert_analysis(
  db : @cloudflare.D1Database,
  analysis : @types.LifelogAnalysis
) -> @cloudflare.D1Result raise {
  db
    .prepare(UPSERT_LIFELOG_ANALYSIS)
    .bind([
      @core.any(analysis.entry_id),
      @core.any(analysis.model),
      @core.any(analysis.version),
      @core.any(analysis.payload_hash.unwrap_or("")),
      @core.any(analysis.insights_json),
      @core.any(analysis.created_at.unwrap_or("")),
    ])
    .run()
}

///|
/// Get latest analysis by entry ID
pub async fn get_analysis_by_entry_id(
  db : @cloudflare.D1Database,
  entry_id : String
) -> @types.LifelogAnalysis? raise {
  let row = db
    .prepare(SELECT_ANALYSIS_BY_ENTRY_ID)
    .bind1(@core.any(entry_id))
    .first()
  match row {
    Some(r) => Some(parse_analysis_row(r))
    None => None
  }
}

///|
/// Get analysis by entry ID and version
pub async fn get_analysis_by_entry_and_version(
  db : @cloudflare.D1Database,
  entry_id : String,
  version : String
) -> @types.LifelogAnalysis? raise {
  let row = db
    .prepare(SELECT_ANALYSIS_BY_ENTRY_AND_VERSION)
    .bind2(@core.any(entry_id), @core.any(version))
    .first()
  match row {
    Some(r) => Some(parse_analysis_row(r))
    None => None
  }
}

// =============================================================================
// SyncState CRUD
// =============================================================================

///|
/// Get sync state by key
pub async fn get_sync_state(
  db : @cloudflare.D1Database,
  key : String
) -> @types.SyncState? raise {
  let row = db.prepare(SELECT_SYNC_STATE).bind1(@core.any(key)).first()
  match row {
    Some(r) => Some(parse_sync_state_row(r))
    None => None
  }
}

///|
/// Set sync state
pub async fn set_sync_state(
  db : @cloudflare.D1Database,
  key : String,
  value : String
) -> @cloudflare.D1Result raise {
  db.prepare(UPSERT_SYNC_STATE).bind2(@core.any(key), @core.any(value)).run()
}

///|
/// Get last synced timestamp
pub async fn get_last_synced_at(db : @cloudflare.D1Database) -> String? raise {
  let state = get_sync_state(db, SYNC_KEY_LAST_SYNCED)
  match state {
    Some(s) => s.value
    None => None
  }
}

///|
/// Set last synced timestamp
pub async fn set_last_synced_at(
  db : @cloudflare.D1Database,
  timestamp : String
) -> Unit raise {
  let _ = set_sync_state(db, SYNC_KEY_LAST_SYNCED, timestamp)
}

///|
/// Get last analyzed timestamp
pub async fn get_last_analyzed_at(db : @cloudflare.D1Database) -> String? raise {
  let state = get_sync_state(db, SYNC_KEY_LAST_ANALYZED)
  match state {
    Some(s) => s.value
    None => None
  }
}

///|
/// Set last analyzed timestamp
pub async fn set_last_analyzed_at(
  db : @cloudflare.D1Database,
  timestamp : String
) -> Unit raise {
  let _ = set_sync_state(db, SYNC_KEY_LAST_ANALYZED, timestamp)
}

// =============================================================================
// AnalysisEvent CRUD
// =============================================================================

///|
/// Insert an analysis event
pub async fn insert_analysis_event(
  db : @cloudflare.D1Database,
  event : @types.AnalysisEvent
) -> @cloudflare.D1Result raise {
  db
    .prepare(INSERT_ANALYSIS_EVENT)
    .bind3(
      @core.any(event.entry_id.unwrap_or("")),
      @core.any(event.status),
      @core.any(event.details.unwrap_or("")),
    )
    .run()
}

///|
/// Get recent analysis events
pub async fn get_recent_analysis_events(
  db : @cloudflare.D1Database,
  limit : Int
) -> Array[@types.AnalysisEvent] raise {
  let result = db
    .prepare(SELECT_RECENT_ANALYSIS_EVENTS)
    .bind1(@core.any(limit))
    .all()
  let events : Array[@types.AnalysisEvent] = []
  if result.success() {
    let rows = result.get_results()
    for row in rows {
      events.push(parse_analysis_event_row(row))
    }
  }
  events
}

// =============================================================================
// Batch Operations
// =============================================================================

///|
/// Batch insert segments for an entry
pub async fn batch_insert_segments(
  db : @cloudflare.D1Database,
  segments : Array[@types.LifelogSegment]
) -> Array[@cloudflare.D1Result] raise {
  let statements : Array[@cloudflare.D1PreparedStatement] = []
  for segment in segments {
    let stmt = db
      .prepare(INSERT_LIFELOG_SEGMENT)
      .bind([
        @core.any(segment.entry_id),
        @core.any(segment.node_id),
        @core.any(segment.path.unwrap_or("")),
        @core.any(segment.node_type.unwrap_or("")),
        @core.any(segment.content.unwrap_or("")),
        @core.any(segment.start_time.unwrap_or("")),
        @core.any(segment.end_time.unwrap_or("")),
        @core.any(segment.start_offset_ms.unwrap_or(0)),
        @core.any(segment.end_offset_ms.unwrap_or(0)),
        @core.any(segment.speaker_name.unwrap_or("")),
        @core.any(segment.speaker_identifier.unwrap_or("")),
      ])
    statements.push(stmt)
  }
  db.batch(statements)
}

///|
/// Update entry with analysis timestamp
pub async fn mark_entry_analyzed(
  db : @cloudflare.D1Database,
  entry_id : String,
  timestamp : String
) -> @cloudflare.D1Result raise {
  db
    .prepare(
      "UPDATE lifelog_entries SET last_analyzed_at = ? WHERE id = ?",
    )
    .bind2(@core.any(timestamp), @core.any(entry_id))
    .run()
}

// =============================================================================
// Row Parsers
// =============================================================================

///|
/// Parse a D1 row to LifelogEntry
fn parse_entry_row(row : @core.Any) -> @types.LifelogEntry {
  {
    id: row["id"].cast(),
    title: get_optional_string(row, "title"),
    markdown: get_optional_string(row, "markdown"),
    start_time: get_optional_string(row, "start_time"),
    end_time: get_optional_string(row, "end_time"),
    start_epoch_ms: get_optional_int(row, "start_epoch_ms"),
    end_epoch_ms: get_optional_int(row, "end_epoch_ms"),
    is_starred: get_bool(row, "is_starred"),
    updated_at: get_optional_string(row, "updated_at"),
    ingested_at: get_optional_string(row, "ingested_at"),
    timezone: get_optional_string(row, "timezone"),
    summary_hash: get_optional_string(row, "summary_hash"),
    last_analyzed_at: get_optional_string(row, "last_analyzed_at"),
  }
}

///|
/// Parse a D1 row to LifelogSegment
fn parse_segment_row(row : @core.Any) -> @types.LifelogSegment {
  {
    id: get_optional_int(row, "id"),
    entry_id: row["entry_id"].cast(),
    node_id: row["node_id"].cast(),
    path: get_optional_string(row, "path"),
    node_type: get_optional_string(row, "node_type"),
    content: get_optional_string(row, "content"),
    start_time: get_optional_string(row, "start_time"),
    end_time: get_optional_string(row, "end_time"),
    start_offset_ms: get_optional_int(row, "start_offset_ms"),
    end_offset_ms: get_optional_int(row, "end_offset_ms"),
    speaker_name: get_optional_string(row, "speaker_name"),
    speaker_identifier: get_optional_string(row, "speaker_identifier"),
  }
}

///|
/// Parse a D1 row to LifelogAnalysis
fn parse_analysis_row(row : @core.Any) -> @types.LifelogAnalysis {
  {
    id: get_optional_int(row, "id"),
    entry_id: row["entry_id"].cast(),
    model: row["model"].cast(),
    version: get_string_or_default(row, "version", "v1"),
    payload_hash: get_optional_string(row, "payload_hash"),
    insights_json: row["insights_json"].cast(),
    created_at: get_optional_string(row, "created_at"),
  }
}

///|
/// Parse a D1 row to SyncState
fn parse_sync_state_row(row : @core.Any) -> @types.SyncState {
  {
    key: row["key"].cast(),
    value: get_optional_string(row, "value"),
    updated_at: get_optional_string(row, "updated_at"),
  }
}

///|
/// Parse a D1 row to AnalysisEvent
fn parse_analysis_event_row(row : @core.Any) -> @types.AnalysisEvent {
  {
    id: get_optional_int(row, "id"),
    entry_id: get_optional_string(row, "entry_id"),
    status: row["status"].cast(),
    details: get_optional_string(row, "details"),
    created_at: get_optional_string(row, "created_at"),
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Get optional string from row
fn get_optional_string(row : @core.Any, key : String) -> String? {
  let v = row[key]
  if @core.is_nullish(v) {
    None
  } else {
    Some(v.cast())
  }
}

///|
/// Get optional int from row
fn get_optional_int(row : @core.Any, key : String) -> Int? {
  let v = row[key]
  if @core.is_nullish(v) {
    None
  } else {
    Some(v.cast())
  }
}

///|
/// Get bool from row (SQLite stores as 0/1)
fn get_bool(row : @core.Any, key : String) -> Bool {
  let v = row[key]
  if @core.is_nullish(v) {
    false
  } else {
    let n : Int = v.cast()
    n != 0
  }
}

///|
/// Get string with default value
fn get_string_or_default(row : @core.Any, key : String, default : String) -> String {
  let v = row[key]
  if @core.is_nullish(v) {
    default
  } else {
    v.cast()
  }
}
