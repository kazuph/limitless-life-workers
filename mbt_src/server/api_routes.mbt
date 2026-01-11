///|
/// API routes for Life Log application
/// Provides REST API endpoints compatible with Hono

// ============================================================================
// Schema Initialization (singleton pattern managed in global scope)
// ============================================================================

///|
/// Internal FFI for schema initialization
extern "js" fn ffi_ensure_schema_impl(db : @core.Any) -> @core.Any =
  #| async (db) => {
  #|   // Singleton check using global variable
  #|   if (!globalThis.__LIFELOG_SCHEMA_INIT__) {
  #|     globalThis.__LIFELOG_SCHEMA_INIT__ = (async () => {
  #|       const statements = [
  #|         'PRAGMA foreign_keys = ON',
  #|         `CREATE TABLE IF NOT EXISTS lifelog_entries (
  #|           id TEXT PRIMARY KEY,
  #|           title TEXT,
  #|           markdown TEXT,
  #|           start_time TEXT,
  #|           end_time TEXT,
  #|           start_epoch_ms INTEGER,
  #|           end_epoch_ms INTEGER,
  #|           is_starred INTEGER DEFAULT 0,
  #|           updated_at TEXT,
  #|           ingested_at TEXT DEFAULT CURRENT_TIMESTAMP,
  #|           timezone TEXT,
  #|           summary_hash TEXT,
  #|           last_analyzed_at TEXT
  #|         )`,
  #|         `CREATE UNIQUE INDEX IF NOT EXISTS lifelog_entries_updated_idx
  #|           ON lifelog_entries (id, updated_at)`,
  #|         `CREATE TABLE IF NOT EXISTS lifelog_segments (
  #|           id INTEGER PRIMARY KEY AUTOINCREMENT,
  #|           entry_id TEXT NOT NULL,
  #|           node_id TEXT NOT NULL,
  #|           path TEXT,
  #|           node_type TEXT,
  #|           content TEXT,
  #|           start_time TEXT,
  #|           end_time TEXT,
  #|           start_offset_ms INTEGER,
  #|           end_offset_ms INTEGER,
  #|           speaker_name TEXT,
  #|           speaker_identifier TEXT,
  #|           FOREIGN KEY (entry_id) REFERENCES lifelog_entries(id) ON DELETE CASCADE
  #|         )`,
  #|         `CREATE UNIQUE INDEX IF NOT EXISTS lifelog_segments_node_idx
  #|           ON lifelog_segments (node_id)`,
  #|         `CREATE TABLE IF NOT EXISTS lifelog_analyses (
  #|           id INTEGER PRIMARY KEY AUTOINCREMENT,
  #|           entry_id TEXT NOT NULL,
  #|           model TEXT NOT NULL,
  #|           version TEXT DEFAULT 'v1',
  #|           payload_hash TEXT,
  #|           insights_json TEXT NOT NULL,
  #|           created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  #|           FOREIGN KEY (entry_id) REFERENCES lifelog_entries(id) ON DELETE CASCADE
  #|         )`,
  #|         `CREATE UNIQUE INDEX IF NOT EXISTS lifelog_analysis_entry_idx
  #|           ON lifelog_analyses (entry_id, version)`,
  #|         `CREATE TABLE IF NOT EXISTS sync_state (
  #|           key TEXT PRIMARY KEY,
  #|           value TEXT,
  #|           updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  #|         )`,
  #|         `CREATE TABLE IF NOT EXISTS analysis_events (
  #|           id INTEGER PRIMARY KEY AUTOINCREMENT,
  #|           entry_id TEXT,
  #|           status TEXT NOT NULL,
  #|           details TEXT,
  #|           created_at TEXT DEFAULT CURRENT_TIMESTAMP
  #|         )`
  #|       ]
  #|       for (const sql of statements) {
  #|         await db.prepare(sql).run()
  #|       }
  #|     })().catch(err => { globalThis.__LIFELOG_SCHEMA_INIT__ = null; throw err })
  #|   }
  #|   return globalThis.__LIFELOG_SCHEMA_INIT__
  #| }

///|
/// Ensure database schema is initialized (exported wrapper)
pub fn ensure_schema(db : @core.Any) -> @core.Any {
  ffi_ensure_schema_impl(db)
}

// ============================================================================
// FFI Bindings for Hono app integration
// ============================================================================

///|
/// Register API routes on Hono app
extern "js" fn ffi_register_api_routes(app : @router.App) -> Unit =
  #| (app) => {
  #|   // Helper to convert CPS-style MoonBit async functions to Promises
  #|   const toPromise = (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))
  #|
  #|   // GET /api/health - Health check endpoint
  #|   app.get('/api/health', async (c) => {
  #|     const db = c.env.LIFELOG_DB
  #|     const services = await import('../services/services.js')
  #|     const [lastSyncedAt, lastAnalyzedAt] = await Promise.all([
  #|       toPromise(services.get_last_synced_at, db),
  #|       toPromise(services.get_last_analyzed_at, db)
  #|     ])
  #|     return c.json({
  #|       ok: true,
  #|       lastSyncedAt,
  #|       lastAnalyzedAt
  #|     })
  #|   })
  #|
  #|   // GET /api/lifelogs - Get timeline entries
  #|   app.get('/api/lifelogs', async (c) => {
  #|     const db = c.env.LIFELOG_DB
  #|     const days = parseInt(c.req.query('days') || '7', 10)
  #|     const offset = parseInt(c.req.query('offset') || '0', 10)
  #|     const detail = c.req.query('detail') === '1'
  #|
  #|     const services = await import('../services/services.js')
  #|
  #|     const [timelineEntries, lastSyncedAt, lastAnalyzedAt] = await Promise.all([
  #|       toPromise(services.get_timeline_snapshot, db, days, offset, detail, 4),
  #|       toPromise(services.get_last_synced_at, db),
  #|       toPromise(services.get_last_analyzed_at, db)
  #|     ])
  #|
  #|     return c.json({
  #|       timeline: timelineEntries,
  #|       lastSyncedAt,
  #|       lastAnalyzedAt,
  #|       integrations: services.get_integration_suggestions()
  #|     })
  #|   })
  #|
  #|   // GET /api/lifelogs/:entryId - Get single entry detail
  #|   app.get('/api/lifelogs/:entryId', async (c) => {
  #|     const db = c.env.LIFELOG_DB
  #|     const entryId = c.req.param('entryId')
  #|     if (!entryId) {
  #|       return c.json({ ok: false, error: 'Missing entryId' }, 400)
  #|     }
  #|
  #|     const services = await import('../services/services.js')
  #|     const entry = await toPromise(services.get_timeline_entry_detail, db, entryId)
  #|     if (!entry) {
  #|       return c.json({ ok: false, error: 'Entry not found' }, 404)
  #|     }
  #|
  #|     return c.json(entry)
  #|   })
  #|
  #|   // GET /api/day-summary - Get day summary
  #|   app.get('/api/day-summary', async (c) => {
  #|     const db = c.env.LIFELOG_DB
  #|     const date = c.req.query('date')
  #|     if (!date) {
  #|       return c.json({ ok: false, error: 'Missing date' }, 400)
  #|     }
  #|
  #|     const services = await import('../services/services.js')
  #|     const summary = await toPromise(services.get_day_summary, db, c.env, date)
  #|     return c.json(summary)
  #|   })
  #|
  #|   // POST /api/day-summary/regenerate - Regenerate day summary
  #|   app.post('/api/day-summary/regenerate', async (c) => {
  #|     const db = c.env.LIFELOG_DB
  #|     const date = c.req.query('date')
  #|     if (!date) {
  #|       return c.json({ ok: false, error: 'Missing date' }, 400)
  #|     }
  #|
  #|     const provider = c.req.query('provider')
  #|     const preferredModel = provider === 'gemini' ? 'gemini' : provider === 'openai' ? 'openai' : undefined
  #|     const services = await import('../services/services.js')
  #|     const summary = await toPromise(services.regenerate_day_summary, db, c.env, date, preferredModel)
  #|     return c.json(summary)
  #|   })
  #|
  #|   // POST /api/sync - Sync lifelogs from Limitless API
  #|   app.post('/api/sync', async (c) => {
  #|     const db = c.env.LIFELOG_DB
  #|     const services = await import('../services/services.js')
  #|     const fullRefresh = c.req.query('full') === '1'
  #|     const stats = await toPromise(services.sync_lifelogs, db, c.env, { full_refresh: fullRefresh })
  #|     return c.json({ ok: true, stats })
  #|   })
  #|
  #|   // POST /api/analyze/:entryId - Analyze a specific entry
  #|   app.post('/api/analyze/:entryId', async (c) => {
  #|     const db = c.env.LIFELOG_DB
  #|     const entryId = c.req.param('entryId')
  #|
  #|     if (!entryId) {
  #|       return c.json({ ok: false, error: 'Missing entryId' }, 400)
  #|     }
  #|
  #|     const services = await import('../services/services.js')
  #|     const analyzedIds = await toPromise(services.analyze_fresh_entries, db, c.env, {
  #|       entry_ids: [entryId],
  #|       force: true,
  #|       limit: 1
  #|     })
  #|     const ok = analyzedIds.includes(entryId)
  #|     const status = ok ? 200 : 404
  #|
  #|     return c.json({ ok, analyzedIds }, status)
  #|   })
  #|
  #|   // POST /api/slack-insights - Post insights to Slack
  #|   app.post('/api/slack-insights', async (c) => {
  #|     const db = c.env.LIFELOG_DB
  #|     const hours = parseInt(c.req.query('hours') || '24', 10)
  #|
  #|     try {
  #|       const services = await import('../services/services.js')
  #|
  #|       const insights = await toPromise(services.analyze_insights_with_gemini, db, c.env, hours, 'hourly_bullets')
  #|       if (!insights) {
  #|         return c.json({ ok: false, error: 'No insights generated' }, 404)
  #|       }
  #|
  #|       const posted = await toPromise(services.post_insights_to_slack, c.env, insights)
  #|       return c.json({
  #|         ok: posted,
  #|         insights,
  #|         posted
  #|       })
  #|     } catch (error) {
  #|       const message = error instanceof Error ? error.message : 'Unknown error'
  #|       return c.json({ ok: false, error: message }, 500)
  #|     }
  #|   })
  #|
  #|   // GET /api/debug/entries - Debug endpoint for entries
  #|   app.get('/api/debug/entries', async (c) => {
  #|     const db = c.env.LIFELOG_DB
  #|     const result = await db.prepare(`
  #|       SELECT id, title, start_time, end_time, date(start_time) as date_label
  #|       FROM lifelog_entries
  #|       ORDER BY start_time DESC
  #|       LIMIT 100
  #|     `).all()
  #|
  #|     const entries = result.results || []
  #|     const dateGroups = {}
  #|     for (const entry of entries) {
  #|       const date = entry.date_label || 'unknown'
  #|       dateGroups[date] = (dateGroups[date] || 0) + 1
  #|     }
  #|
  #|     return c.json({
  #|       totalEntries: entries.length,
  #|       dateGroups,
  #|       recentEntries: entries.slice(0, 10).map(e => ({
  #|         id: e.id,
  #|         title: e.title,
  #|         startTime: e.start_time,
  #|         dateLabel: e.date_label
  #|       }))
  #|     })
  #|   })
  #|
  #|   // GET /api/debug/segments/:entryId - Debug endpoint for segments
  #|   app.get('/api/debug/segments/:entryId', async (c) => {
  #|     const db = c.env.LIFELOG_DB
  #|     const entryId = c.req.param('entryId')
  #|
  #|     const result = await db.prepare(`
  #|       SELECT * FROM lifelog_segments WHERE entry_id = ?
  #|     `).bind(entryId).all()
  #|
  #|     const segments = result.results || []
  #|     return c.json({
  #|       entryId,
  #|       segmentCount: segments.length,
  #|       segments: segments.map(seg => ({
  #|         id: seg.node_id,
  #|         nodeType: seg.node_type,
  #|         contentLength: seg.content?.length || 0,
  #|         contentPreview: seg.content?.slice(0, 100) || null,
  #|         startTime: seg.start_time,
  #|         endTime: seg.end_time,
  #|         speakerName: seg.speaker_name
  #|       }))
  #|     })
  #|   })
  #| }

// ============================================================================
// Public API
// ============================================================================

///|
/// Register all API routes on the Hono app
pub fn register_api_routes(app : @router.App) -> Unit {
  ffi_register_api_routes(app)
}
