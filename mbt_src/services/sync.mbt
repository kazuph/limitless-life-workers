///|
/// Sync service for fetching lifelogs from Limitless API and storing to D1
/// Uses extern "js" FFI for Workers AI binding access

// ============================================================================
// Constants
// ============================================================================

///|
/// State key for last updated timestamp
let last_updated_key : String = "lifelog:lastUpdatedAt"

///|
/// State key for last start time (used for API start parameter)
let last_start_time_key : String = "lifelog:lastStartTime"

///|
/// State key for last sync timestamp
let last_sync_key : String = "lifelog:lastSyncedAt"

///|
/// D1 allows up to 100 bound parameters per statement.
/// Each segment insert binds 11 params, so batch at most 9 rows (9 * 11 = 99).
let segment_batch_size : Int = 9

// ============================================================================
// Types
// ============================================================================

///|
/// Sync statistics returned from sync operation
pub struct SyncStats {
  processed : Int
  last_updated_at : String?
}

///|
/// Lifelog entry from Limitless API
pub struct Lifelog {
  id : String
  title : String
  markdown : String?
  start_time : String
  end_time : String
  start_epoch_ms : Int64?
  end_epoch_ms : Int64?
  is_starred : Bool
  updated_at : String?
  timezone : String?
  contents : Array[LifelogContent]
}

///|
/// Content node from Lifelog
pub struct LifelogContent {
  content_type : String
  content : String?
  start_time : String?
  end_time : String?
  start_offset_ms : Int?
  end_offset_ms : Int?
  children : Array[LifelogContent]
  speaker_name : String?
  speaker_identifier : String?
}

///|
/// Entry for database storage
pub struct LifelogEntry {
  id : String
  title : String
  markdown : String?
  start_time : String
  end_time : String
  start_epoch_ms : Int64?
  end_epoch_ms : Int64?
  is_starred : Bool
  updated_at : String?
  timezone : String?
  summary_hash : String?
}

///|
/// Segment for database storage
pub struct LifelogSegment {
  id : String
  entry_id : String
  content : String?
  start_time : String?
  end_time : String?
  start_offset_ms : Int?
  end_offset_ms : Int?
  node_type : String?
  speaker_name : String?
  speaker_identifier : String?
  parent_segment_id : String?
}

///|
/// Fetch options for Limitless API
pub struct FetchLifelogsOptions {
  cursor : String?
  start : String?
  end : String?
  limit : Int?
  timezone : String?
}

///|
/// Response from Limitless API
pub struct LimitlessResponse {
  lifelogs : Array[Lifelog]
  next_cursor : String?
}

// ============================================================================
// FFI Bindings for JavaScript interop
// ============================================================================

///|
/// Get sync state value from database (direct D1 call)
/// Returns empty string if value is null/undefined (to avoid MoonBit FFI issues)
extern "js" fn ffi_get_sync_state_value(
  db : @core.Any,
  key : String
) -> @js.Promise[String] =
  #| async (db, key) => {
  #|   const result = await db.prepare(
  #|     'SELECT value FROM sync_state WHERE key = ?'
  #|   ).bind(key).first()
  #|   return result?.value || ''
  #| }

///|
/// Upsert sync state value to database
extern "js" fn ffi_sync_upsert_state(
  db : @core.Any,
  key : String,
  value : String
) -> @js.Promise[Unit] =
  #| async (db, key, value) => {
  #|   await db.prepare(`
  #|     INSERT INTO sync_state (key, value, updated_at)
  #|     VALUES (?, ?, datetime('now'))
  #|     ON CONFLICT(key) DO UPDATE SET
  #|       value = excluded.value,
  #|       updated_at = datetime('now')
  #|   `).bind(key, value).run()
  #| }

///|
/// Fetch lifelogs from Limitless API (direct HTTP)
extern "js" fn ffi_fetch_lifelogs(
  env : @core.Any,
  cursor : String?,
  start : String?,
  limit : Int
) -> @js.Promise[@core.Any] =
  #| async (env, cursor, start, limit) => {
  #|   const apiKey = env.LIMITLESS_API_KEY
  #|   if (!apiKey) throw new Error('LIMITLESS_API_KEY not set')
  #|
  #|   const params = new URLSearchParams()
  #|   params.set('limit', String(limit))
  #|   params.set('direction', 'desc')
  #|   params.set('include_markdown', 'true')
  #|   params.set('include_headings', 'true')
  #|   if (cursor) params.set('cursor', cursor)
  #|   if (start) params.set('start', start)
  #|
  #|   const url = `https://api.limitless.ai/v1/lifelogs?${params.toString()}`
  #|   const res = await fetch(url, {
  #|     headers: {
  #|       'X-API-Key': apiKey,
  #|       'Accept': 'application/json'
  #|     }
  #|   })
  #|
  #|   if (!res.ok) {
  #|     throw new Error(`Limitless API error: ${res.status}`)
  #|   }
  #|
  #|   return await res.json()
  #| }

///|
/// Insert or update lifelog entry (raw SQL)
/// Note: D1 doesn't support undefined, so we convert to null
extern "js" fn ffi_upsert_entry(
  db : @core.Any,
  entry : @core.Any
) -> @js.Promise[Unit] =
  #| async (db, entry) => {
  #|   const n = (v) => v === undefined ? null : v;
  #|   await db.prepare(`
  #|     INSERT INTO lifelog_entries (
  #|       id, title, markdown, start_time, end_time,
  #|       start_epoch_ms, end_epoch_ms, is_starred,
  #|       updated_at, ingested_at, timezone, summary_hash
  #|     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), ?, ?)
  #|     ON CONFLICT(id) DO UPDATE SET
  #|       title = excluded.title,
  #|       markdown = excluded.markdown,
  #|       start_time = excluded.start_time,
  #|       end_time = excluded.end_time,
  #|       start_epoch_ms = excluded.start_epoch_ms,
  #|       end_epoch_ms = excluded.end_epoch_ms,
  #|       is_starred = excluded.is_starred,
  #|       updated_at = excluded.updated_at,
  #|       timezone = excluded.timezone,
  #|       summary_hash = excluded.summary_hash
  #|   `).bind(
  #|     n(entry.id), n(entry.title), n(entry.markdown),
  #|     n(entry.startTime), n(entry.endTime),
  #|     n(entry.startEpochMs), n(entry.endEpochMs), entry.isStarred ? 1 : 0,
  #|     n(entry.updatedAt), n(entry.timezone), n(entry.summaryHash)
  #|   ).run()
  #| }

///|
/// Delete segments for an entry (raw SQL)
extern "js" fn ffi_delete_segments(
  db : @core.Any,
  entry_id : String
) -> @js.Promise[Unit] =
  #| async (db, entryId) => {
  #|   await db.prepare(
  #|     'DELETE FROM lifelog_segments WHERE entry_id = ?'
  #|   ).bind(entryId).run()
  #| }

///|
/// Insert segments in batch (raw SQL)
/// Note: D1 doesn't support undefined, so we convert to null
extern "js" fn ffi_insert_segments(
  db : @core.Any,
  segments : @core.Any
) -> @js.Promise[Unit] =
  #| async (db, segments) => {
  #|   const n = (v) => v === undefined ? null : v;
  #|   for (const seg of segments) {
  #|     await db.prepare(`
  #|       INSERT INTO lifelog_segments (
  #|         entry_id, node_id, path, node_type, content,
  #|         start_time, end_time, start_offset_ms, end_offset_ms,
  #|         speaker_name, speaker_identifier
  #|       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  #|     `).bind(
  #|       n(seg.entryId), n(seg.nodeId), n(seg.path), n(seg.nodeType), n(seg.content),
  #|       n(seg.startTime), n(seg.endTime), n(seg.startOffsetMs), n(seg.endOffsetMs),
  #|       n(seg.speakerName), n(seg.speakerIdentifier)
  #|     ).run()
  #|   }
  #| }

///|
/// Compute SHA1 hash for content (Web Crypto API)
extern "js" fn ffi_to_sha1(content : String) -> @js.Promise[String] =
  #| async (content) => {
  #|   const encoder = new TextEncoder()
  #|   const data = encoder.encode(content)
  #|   const hashBuffer = await crypto.subtle.digest('SHA-1', data)
  #|   const hashArray = Array.from(new Uint8Array(hashBuffer))
  #|   return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
  #| }

///|
/// Get current ISO timestamp
extern "js" fn ffi_now_iso() -> String =
  #| () => new Date().toISOString()

///|
/// Subtract hours from ISO timestamp and return new ISO string
extern "js" fn ffi_subtract_hours(iso : String, hours : Int) -> String =
  #| (iso, hours) => {
  #|   const date = new Date(iso)
  #|   date.setTime(date.getTime() - hours * 60 * 60 * 1000)
  #|   return date.toISOString()
  #| }

///|
/// Get ISO timestamp for N days ago
extern "js" fn ffi_days_ago(days : Int) -> String =
  #| (days) => {
  #|   const date = new Date()
  #|   date.setTime(date.getTime() - days * 24 * 60 * 60 * 1000)
  #|   return date.toISOString()
  #| }

///|
/// Get environment variable
extern "js" fn ffi_get_env(env : @core.Any, key : String) -> String? =
  #| (env, key) => env[key] ?? null

///|
/// Log message to console
extern "js" fn ffi_log(message : String) -> Unit =
  #| (message) => console.log(message)

///|
/// Log warning to console
extern "js" fn ffi_warn(message : String) -> Unit =
  #| (message) => console.warn(message)

// ============================================================================
// Helper Functions
// ============================================================================

///|
/// Chunk array into batches
fn chunk_array[T](values : Array[T], chunk_size : Int) -> Array[Array[T]] {
  let result : Array[Array[T]] = []
  let mut i = 0
  while i < values.length() {
    let batch : Array[T] = []
    let end = if i + chunk_size < values.length() {
      i + chunk_size
    } else {
      values.length()
    }
    for j = i; j < end; j = j + 1 {
      batch.push(values[j])
    }
    result.push(batch)
    i = i + chunk_size
  }
  result
}

///|
/// Apply backfill window (6 hours before to catch any missed data)
fn backfill_window(since : String) -> String? {
  Some(ffi_subtract_hours(since, 6))
}

///|
/// Get default start date (7 days ago)
fn get_default_start_date() -> String {
  ffi_days_ago(7)
}

///|
/// Parse lifelogs from API response
fn parse_lifelogs(json : @core.Any) -> Array[Lifelog] {
  let result : Array[Lifelog] = []
  let data = json["data"]
  if @core.is_nullish(data) {
    return result
  }
  let lifelogs_json = data["lifelogs"]
  if @core.is_nullish(lifelogs_json) {
    return result
  }
  let arr = @core.array_from(lifelogs_json)
  for item in arr {
    let lifelog = parse_lifelog(item)
    result.push(lifelog)
  }
  result
}

///|
/// Parse single lifelog from JSON
fn parse_lifelog(json : @core.Any) -> Lifelog {
  let id : String = json["id"].cast()
  let title : String = json["title"].cast()
  let markdown : String? = @core.identity_option(json["markdown"])
  let start_time : String = json["startTime"].cast()
  let end_time : String = json["endTime"].cast()
  let start_epoch_ms : Int64? = @core.identity_option(json["startEpochMs"])
  let end_epoch_ms : Int64? = @core.identity_option(json["endEpochMs"])
  let is_starred : Bool = if @core.is_nullish(json["isStarred"]) {
    false
  } else {
    json["isStarred"].cast()
  }
  let updated_at : String? = @core.identity_option(json["updatedAt"])
  let timezone : String? = @core.identity_option(json["timezone"])

  let contents : Array[LifelogContent] = []
  let contents_json = json["contents"]
  if not(@core.is_nullish(contents_json)) {
    let arr = @core.array_from(contents_json)
    for item in arr {
      contents.push(parse_content(item))
    }
  }

  {
    id,
    title,
    markdown,
    start_time,
    end_time,
    start_epoch_ms,
    end_epoch_ms,
    is_starred,
    updated_at,
    timezone,
    contents,
  }
}

///|
/// Parse content node
fn parse_content(json : @core.Any) -> LifelogContent {
  let content_type : String = if @core.is_nullish(json["type"]) {
    "unknown"
  } else {
    json["type"].cast()
  }
  let content : String? = @core.identity_option(json["content"])
  let start_time : String? = @core.identity_option(json["startTime"])
  let end_time : String? = @core.identity_option(json["endTime"])
  let start_offset_ms : Int? = @core.identity_option(json["startOffsetMs"])
  let end_offset_ms : Int? = @core.identity_option(json["endOffsetMs"])
  let speaker_name : String? = @core.identity_option(json["speakerName"])
  let speaker_identifier : String? = @core.identity_option(
    json["speakerIdentifier"],
  )

  let children : Array[LifelogContent] = []
  let children_json = json["children"]
  if not(@core.is_nullish(children_json)) {
    let arr = @core.array_from(children_json)
    for item in arr {
      children.push(parse_content(item))
    }
  }

  {
    content_type,
    content,
    start_time,
    end_time,
    start_offset_ms,
    end_offset_ms,
    children,
    speaker_name,
    speaker_identifier,
  }
}

///|
/// Get next cursor from response
fn get_next_cursor(json : @core.Any) -> String? {
  let meta = json["meta"]
  if @core.is_nullish(meta) {
    return None
  }
  let lifelogs = meta["lifelogs"]
  if @core.is_nullish(lifelogs) {
    return None
  }
  @core.identity_option(lifelogs["nextCursor"])
}

///|
/// Convert lifelog to entry for database
fn lifelog_to_entry(lifelog : Lifelog) -> @core.Any {
  @core.from_entries(
    [
      ("id", @core.any(lifelog.id)),
      ("title", @core.any(lifelog.title)),
      ("markdown", @core.nullable(lifelog.markdown)),
      ("startTime", @core.any(lifelog.start_time)),
      ("endTime", @core.any(lifelog.end_time)),
      ("startEpochMs", @core.nullable(lifelog.start_epoch_ms)),
      ("endEpochMs", @core.nullable(lifelog.end_epoch_ms)),
      ("isStarred", @core.any(lifelog.is_starred)),
      ("updatedAt", @core.nullable(lifelog.updated_at)),
      ("timezone", @core.nullable(lifelog.timezone)),
    ],
  )
}

///|
/// Generate hash seed from lifelog
fn lifelog_hash_seed(lifelog : Lifelog) -> String {
  let mut seed = lifelog.title + "|" + lifelog.start_time + "|" + lifelog.end_time
  match lifelog.markdown {
    Some(md) => seed = seed + "|" + md
    None => ()
  }
  seed
}

///|
/// Flatten contents to segments
fn lifelog_to_segments(
  lifelog : Lifelog,
  parent_id : String?
) -> Array[@core.Any] {
  let segments : Array[@core.Any] = []
  let mut idx = 0

  fn process_contents(
    contents : Array[LifelogContent],
    parent : String?,
    parent_path : String
  ) -> Unit {
    let mut child_idx = 0
    for content in contents {
      let segment_id = lifelog.id + "-" + idx.to_string()
      let current_path = if parent_path == "" {
        child_idx.to_string()
      } else {
        parent_path + "/" + child_idx.to_string()
      }
      idx = idx + 1
      child_idx = child_idx + 1

      let segment = @core.from_entries(
        [
          ("id", @core.any(segment_id)),
          ("entryId", @core.any(lifelog.id)),
          ("nodeId", @core.any(segment_id)),
          ("path", @core.any(current_path)),
          ("content", @core.nullable(content.content)),
          ("startTime", @core.nullable(content.start_time)),
          ("endTime", @core.nullable(content.end_time)),
          ("startOffsetMs", @core.nullable(content.start_offset_ms)),
          ("endOffsetMs", @core.nullable(content.end_offset_ms)),
          ("nodeType", @core.any(content.content_type)),
          ("speakerName", @core.nullable(content.speaker_name)),
          ("speakerIdentifier", @core.nullable(content.speaker_identifier)),
          ("parentSegmentId", @core.nullable(parent)),
        ],
      )
      segments.push(segment)

      if content.children.length() > 0 {
        process_contents(content.children, Some(segment_id), current_path)
      }
    }
  }

  process_contents(lifelog.contents, parent_id, "")
  segments
}

// ============================================================================
// Public API
// ============================================================================

///|
/// Sync options
pub struct SyncOptions {
  full_refresh : Bool
}

///|
/// Default sync options
pub fn SyncOptions::default() -> SyncOptions {
  { full_refresh: false }
}

///|
/// Sync lifelogs from Limitless API to database
/// Fetches new entries, computes hashes, and stores in D1 with batched segment insertion
pub async fn sync_lifelogs(
  db : @core.Any,
  env : @core.Any,
  opts : SyncOptions
) -> SyncStats raise {
  let api_key = ffi_get_env(env, "LIMITLESS_API_KEY")
  let disable_sync = ffi_get_env(env, "DISABLE_LIMITLESS_SYNC")

  // Check if sync is disabled
  match disable_sync {
    Some("1") => {
      ffi_log("Limitless sync disabled via DISABLE_LIMITLESS_SYNC flag; skipping fetch.")
      return { processed: 0, last_updated_at: None }
    }
    _ => ()
  }

  // Check API key
  match api_key {
    None => {
      ffi_warn("Missing LIMITLESS_API_KEY; skipping Limitless sync.")
      return { processed: 0, last_updated_at: None }
    }
    Some("skip") => {
      ffi_log("Limitless sync disabled via DISABLE_LIMITLESS_SYNC flag; skipping fetch.")
      return { processed: 0, last_updated_at: None }
    }
    _ => ()
  }

  let mut cursor : String? = None
  let mut processed = 0
  let mut last_updated_at : String? = None
  let mut last_start_time : String? = None
  let mut attempted = false

  // Get stored since value based on start_time (not updated_at)
  // This is the correct approach as Limitless API's start parameter filters by start_time
  // FFI returns empty string instead of null to avoid MoonBit FFI issues
  let stored_since_raw = ffi_get_sync_state_value(db, last_start_time_key).wait()

  // Normalize stored_since: treat empty strings and null-like values as None
  let stored_since : String? = if stored_since_raw.length() > 0 &&
    stored_since_raw != "null" &&
    stored_since_raw != "undefined" {
    Some(stored_since_raw)
  } else {
    None
  }

  // Debug log
  match stored_since {
    Some(s) => ffi_log("[Sync] stored_since = " + s)
    None => ffi_log("[Sync] stored_since = None, using default (7 days ago)")
  }

  // Determine starting point for sync
  let since : String? = if opts.full_refresh {
    None
  } else {
    match stored_since {
      Some(s) => backfill_window(s)
      None => Some(get_default_start_date())
    }
  }

  // Log the sync range for debugging
  match since {
    Some(s) => ffi_log("[Sync] Fetching lifelogs with start >= " + s)
    None => ffi_log("[Sync] Fetching all lifelogs (no start filter)")
  }

  // Pagination loop
  let mut has_more = true
  while has_more {
    attempted = true
    let response = ffi_fetch_lifelogs(env, cursor, since, 100).wait()
    let lifelogs = parse_lifelogs(response)

    for lifelog in lifelogs {
      // Convert to entry and compute hash
      let entry = lifelog_to_entry(lifelog)
      let hash_seed = lifelog_hash_seed(lifelog)
      let summary_hash = ffi_to_sha1(hash_seed).wait()
      entry["summaryHash"] = @core.any(summary_hash)

      // Upsert entry
      ffi_upsert_entry(db, entry).wait()

      // Process segments
      let segments = lifelog_to_segments(lifelog, None)
      let msg = "[Sync] Entry " +
        lifelog.id +
        ": title=\"" +
        lifelog.title +
        "\", contents count=" +
        lifelog.contents.length().to_string() +
        ", segments count=" +
        segments.length().to_string()
      ffi_log(msg)

      if segments.length() > 0 {
        // Delete existing segments
        ffi_delete_segments(db, lifelog.id).wait()

        // Insert in batches
        let batches = chunk_array(segments, segment_batch_size)
        for batch in batches {
          let batch_any : @core.Any = @core.identity(batch)
          ffi_insert_segments(db, batch_any).wait()
        }
        let batch_msg = "[Sync] Inserted " +
          segments.length().to_string() +
          " segments for entry " +
          lifelog.id +
          " in " +
          batches.length().to_string() +
          " batches (size " +
          segment_batch_size.to_string() +
          ")"
        ffi_log(batch_msg)
      } else {
        ffi_warn("[Sync] No segments for entry " + lifelog.id)
      }

      processed = processed + 1

      // Track latest updated_at
      match lifelog.updated_at {
        Some(updated) =>
          match last_updated_at {
            None => last_updated_at = Some(updated)
            Some(current) =>
              if updated > current {
                last_updated_at = Some(updated)
              }
          }
        None => ()
      }

      // Track latest start_time (this is what Limitless API filters by)
      match last_start_time {
        None => last_start_time = Some(lifelog.start_time)
        Some(current) =>
          if lifelog.start_time > current {
            last_start_time = Some(lifelog.start_time)
          }
      }
    }

    cursor = get_next_cursor(response)
    match cursor {
      None => has_more = false
      Some(_) => ()
    }
  }

  // Update state
  match last_updated_at {
    Some(updated) => ffi_sync_upsert_state(db, last_updated_key, updated).wait()
    None => ()
  }

  // Update last_start_time (this is the key fix - use start_time for API filtering)
  match last_start_time {
    Some(start) => {
      ffi_sync_upsert_state(db, last_start_time_key, start).wait()
      ffi_log("[Sync] Updated lastStartTime to " + start)
    }
    None => ()
  }

  if attempted {
    let now = ffi_now_iso()
    ffi_sync_upsert_state(db, last_sync_key, now).wait()
  }

  { processed, last_updated_at }
}

///|
/// Get last synced timestamp
pub async fn get_last_synced_at(db : @core.Any) -> String? {
  let result = ffi_get_sync_state_value(db, last_sync_key).wait()
  if result.length() > 0 {
    Some(result)
  } else {
    None
  }
}
