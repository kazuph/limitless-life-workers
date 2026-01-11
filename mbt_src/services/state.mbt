///|
/// Sync state management for Life Log application
/// Provides key-value state storage using D1

// ============================================================================
// FFI Bindings for D1 state access
// ============================================================================

///|
/// Get sync state value by key
extern "js" fn ffi_get_sync_state(db : @core.Any, key : String) -> @js.Promise[String?] =
  #| async (db, key) => {
  #|   const result = await db.prepare(
  #|     'SELECT value FROM sync_state WHERE key = ?'
  #|   ).bind(key).first()
  #|   return result?.value ?? null
  #| }

///|
/// Upsert sync state value
extern "js" fn ffi_upsert_sync_state(
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
/// Delete sync state value
extern "js" fn ffi_delete_sync_state(db : @core.Any, key : String) -> @js.Promise[Unit] =
  #| async (db, key) => {
  #|   await db.prepare(
  #|     'DELETE FROM sync_state WHERE key = ?'
  #|   ).bind(key).run()
  #| }

///|
/// Get all sync state values
extern "js" fn ffi_get_all_sync_states(db : @core.Any) -> @js.Promise[@core.Any] =
  #| async (db) => {
  #|   const result = await db.prepare(
  #|     'SELECT key, value, updated_at FROM sync_state'
  #|   ).all()
  #|   const states = {}
  #|   for (const row of (result.results || [])) {
  #|     states[row.key] = { value: row.value, updated_at: row.updated_at }
  #|   }
  #|   return states
  #| }

// ============================================================================
// Public API
// ============================================================================

///|
/// Get sync state value by key
pub async fn get_sync_state_value(db : @core.Any, key : String) -> String? {
  ffi_get_sync_state(db, key).wait()
}

///|
/// Upsert sync state value
pub async fn upsert_sync_state(
  db : @core.Any,
  key : String,
  value : String
) -> Unit {
  ffi_upsert_sync_state(db, key, value).wait()
}

///|
/// Delete sync state value
pub async fn delete_sync_state(db : @core.Any, key : String) -> Unit {
  ffi_delete_sync_state(db, key).wait()
}

///|
/// Get all sync state values
pub async fn get_all_sync_states(db : @core.Any) -> @core.Any {
  ffi_get_all_sync_states(db).wait()
}
