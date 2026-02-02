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
  #|     const mode = c.req.query('mode') || 'hourly_bullets'
  #|
  #|     try {
  #|       const services = await import('../services/services.js')
  #|
  #|       // Calculate time range
  #|       const now = new Date()
  #|       const rangeFrom = new Date(now.getTime() - hours * 60 * 60 * 1000)
  #|       const rangeTo = now
  #|       const rangeFromStr = rangeFrom.toISOString()
  #|       const rangeToStr = rangeTo.toISOString()
  #|
  #|       // Fetch entries from DB (using markdown field since segments may be empty)
  #|       const entriesResult = await db.prepare(`
  #|         SELECT id, title, start_time, end_time, markdown as content
  #|         FROM lifelog_entries
  #|         WHERE start_time >= ? AND start_time <= ?
  #|         ORDER BY start_time DESC
  #|         LIMIT 50
  #|       `).bind(rangeFromStr, rangeToStr).all()
  #|
  #|       // Sanitize function to remove control characters
  #|       const sanitize = (str) => str ? str.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '') : ''
  #|
  #|       const entries = (entriesResult.results || []).map(e => ({
  #|         title: sanitize(e.title) || null,
  #|         startTime: e.start_time || null,
  #|         endTime: e.end_time || null,
  #|         content: sanitize(e.content) || ''
  #|       }))
  #|
  #|       if (entries.length === 0) {
  #|         return c.json({ ok: false, error: 'No entries found in time range' }, 404)
  #|       }
  #|
  #|       // Call Gemini API directly to avoid MoonBit-JS type conversion issues
  #|       const apiKey = c.env.GEMINI_API_KEY || ''
  #|       if (!apiKey) {
  #|         return c.json({ ok: false, error: 'Missing GEMINI_API_KEY' }, 500)
  #|       }
  #|
  #|       const systemPrompt = mode === 'hourly_bullets'
  #|         ? `あなたは簡潔なサマリー専任のアシスタントです。以下の時間範囲の出来事を日本語で3-6行の箇条書きにまとめてください。
  #|出力要件:
  #|- summary フィールドのみに箇条書きで書く（例: "- ミーティングでAの仕様確認"）
  #|- 他の配列フィールド（suggested_schedules, todo_items, insights, shopping_suggestions）は空配列で返す
  #|- JSONのみを返し、コメントやコードフェンスは不要
  #|- 重要度が低い雑談は入れず、行数は最小限に抑える`
  #|         : `あなたは優秀なパーソナルアシスタントです。与えられたライフログを分析し、JSON形式で結果を返してください。`
  #|
  #|       const payload = {
  #|         analysis_period: { from: rangeFromStr, to: rangeToStr },
  #|         entries: entries
  #|       }
  #|
  #|       const schema = {
  #|         type: 'object',
  #|         properties: {
  #|           suggested_schedules: { type: 'array', items: { type: 'object' } },
  #|           todo_items: { type: 'array', items: { type: 'object' } },
  #|           insights: { type: 'array', items: { type: 'object' } },
  #|           shopping_suggestions: { type: 'array', items: { type: 'object' } },
  #|           summary: { type: 'string' }
  #|         },
  #|         required: ['suggested_schedules', 'todo_items', 'insights', 'shopping_suggestions', 'summary']
  #|       }
  #|
  #|       const geminiResponse = await fetch(
  #|         `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
  #|         {
  #|           method: 'POST',
  #|           headers: { 'Content-Type': 'application/json' },
  #|           body: JSON.stringify({
  #|             contents: [{ parts: [{ text: systemPrompt + '\n\nSchema:\n' + JSON.stringify(schema) + '\n\n分析対象期間: ' + rangeFromStr + ' 〜 ' + rangeToStr + '\nライフログデータ:\n' + JSON.stringify(payload) }] }],
  #|             generationConfig: { responseMimeType: 'application/json', temperature: 0.7, maxOutputTokens: 4096 }
  #|           })
  #|         }
  #|       )
  #|
  #|       if (!geminiResponse.ok) {
  #|         const errorText = await geminiResponse.text()
  #|         return c.json({ ok: false, error: 'Gemini API error: ' + errorText }, 500)
  #|       }
  #|
  #|       const geminiResult = await geminiResponse.json()
  #|       const candidates = geminiResult.candidates
  #|       if (!candidates || candidates.length === 0) {
  #|         return c.json({ ok: false, error: 'No candidates in Gemini response' }, 500)
  #|       }
  #|
  #|       let textContent = candidates[0]?.content?.parts?.[0]?.text
  #|       if (!textContent) {
  #|         return c.json({ ok: false, error: 'No text in Gemini response' }, 500)
  #|       }
  #|
  #|       // Sanitize JSON by removing control characters except allowed ones
  #|       textContent = textContent.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')
  #|
  #|       const insights = JSON.parse(textContent)
  #|
  #|       // Check if there's content to post
  #|       const hasContent = insights.summary || (insights.suggested_schedules?.length > 0) ||
  #|                          (insights.todo_items?.length > 0) || (insights.insights?.length > 0) ||
  #|                          (insights.shopping_suggestions?.length > 0)
  #|       if (!hasContent) {
  #|         return c.json({ ok: false, error: 'No insights generated' }, 404)
  #|       }
  #|
  #|       // Support dry-run mode for testing
  #|       const dryRun = c.req.query('dry') === '1'
  #|       if (dryRun) {
  #|         return c.json({ ok: true, insights, posted: false, dryRun: true })
  #|       }
  #|
  #|       // Post to Slack directly to avoid MoonBit type issues
  #|       const slackToken = c.env.SLACK_BOT_TOKEN || ''
  #|       if (!slackToken) {
  #|         return c.json({ ok: false, error: 'Missing SLACK_BOT_TOKEN', insights }, 500)
  #|       }
  #|
  #|       // Format insights for Slack
  #|       const formatInsights = (ins) => {
  #|         const sections = []
  #|         if (ins.summary) sections.push('📝 *サマリー*\n' + ins.summary)
  #|         if (ins.suggested_schedules?.length > 0) {
  #|           sections.push('📅 *追加した方が良さそうな予定*\n' + ins.suggested_schedules.map(s => `• *${s.title}*\n   ${s.description}`).join('\n'))
  #|         }
  #|         if (ins.todo_items?.length > 0) {
  #|           sections.push('✅ *TODOにした方が良さそうなタスク*\n' + ins.todo_items.map(t => `• *${t.title}*\n   ${t.description}`).join('\n'))
  #|         }
  #|         if (ins.insights?.length > 0) {
  #|           sections.push('🧠 *インサイト・学び*\n' + ins.insights.map(i => `💡 *${i.category}*\n   ${i.content}`).join('\n'))
  #|         }
  #|         if (ins.shopping_suggestions?.length > 0) {
  #|           sections.push('🛒 *買い物提案*\n' + ins.shopping_suggestions.map(s => `• *${s.item}*\n   ${s.reason}`).join('\n'))
  #|         }
  #|         return sections.join('\n\n---\n\n')
  #|       }
  #|
  #|       const timestamp = new Date().toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' })
  #|       const header = '@kazuph 🎙️ *Limitless 音声分析レポート*\n_' + timestamp + '_\n\n'
  #|       const text = header + formatInsights(insights)
  #|
  #|       const slackParams = new URLSearchParams()
  #|       slackParams.set('token', slackToken)
  #|       slackParams.set('channel', '#limitless-onsai-insight')
  #|       slackParams.set('username', 'keroyon')
  #|       slackParams.set('icon_url', 'https://emoji.slack-edge.com/T030A5CV2/keroyon/c3aa47f65017d188.png')
  #|       slackParams.set('text', text)
  #|       slackParams.set('link_names', 'true')
  #|
  #|       const slackResponse = await fetch('https://slack.com/api/chat.postMessage', {
  #|         method: 'POST',
  #|         headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  #|         body: slackParams.toString()
  #|       })
  #|
  #|       const slackResult = await slackResponse.json()
  #|       const posted = slackResult.ok === true
  #|
  #|       return c.json({
  #|         ok: posted,
  #|         insights,
  #|         posted,
  #|         slackError: slackResult.ok ? undefined : slackResult.error
  #|       })
  #|     } catch (error) {
  #|       const message = error instanceof Error ? error.message : String(error)
  #|       const stack = error instanceof Error ? error.stack : undefined
  #|       console.error('[slack-insights] Error:', error)
  #|       return c.json({ ok: false, error: message, stack }, 500)
  #|     }
  #|   })
  #|
  #|   // GET /api/debug/gemini-test - Test Gemini API directly
  #|   app.get('/api/debug/gemini-test', async (c) => {
  #|     const hours = parseInt(c.req.query('hours') || '96', 10)
  #|     const steps = { dbConnect: false, fetchEntries: false, entriesFound: 0, geminiCall: false, geminiParse: false }
  #|
  #|     try {
  #|       const db = c.env.LIFELOG_DB
  #|       steps.dbConnect = true
  #|
  #|       const now = new Date()
  #|       const rangeFrom = new Date(now.getTime() - hours * 60 * 60 * 1000)
  #|       const rangeTo = now
  #|       const rangeFromStr = rangeFrom.toISOString()
  #|       const rangeToStr = rangeTo.toISOString()
  #|
  #|       const entriesResult = await db.prepare(`
  #|         SELECT id, title, start_time, end_time, markdown as content
  #|         FROM lifelog_entries
  #|         WHERE start_time >= ? AND start_time <= ?
  #|         ORDER BY start_time DESC
  #|         LIMIT 10
  #|       `).bind(rangeFromStr, rangeToStr).all()
  #|       steps.fetchEntries = true
  #|
  #|       const entries = (entriesResult.results || []).map(e => ({
  #|         title: e.title || null,
  #|         startTime: e.start_time || null,
  #|         endTime: e.end_time || null,
  #|         content: (e.content || '').slice(0, 200)
  #|       }))
  #|       steps.entriesFound = entries.length
  #|
  #|       if (entries.length === 0) {
  #|         return c.json({ ok: true, steps, message: 'No entries in range', range: { from: rangeFromStr, to: rangeToStr } })
  #|       }
  #|
  #|       const apiKey = c.env.GEMINI_API_KEY || ''
  #|       if (!apiKey) {
  #|         return c.json({ ok: false, steps, error: 'Missing GEMINI_API_KEY' })
  #|       }
  #|
  #|       const geminiResponse = await fetch(
  #|         `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
  #|         {
  #|           method: 'POST',
  #|           headers: { 'Content-Type': 'application/json' },
  #|           body: JSON.stringify({
  #|             contents: [{ parts: [{ text: 'Return JSON: {"summary":"test ok"}' }] }],
  #|             generationConfig: { responseMimeType: 'application/json' }
  #|           })
  #|         }
  #|       )
  #|       steps.geminiCall = true
  #|
  #|       if (!geminiResponse.ok) {
  #|         const errorText = await geminiResponse.text()
  #|         return c.json({ ok: false, steps, error: 'Gemini API error', details: errorText })
  #|       }
  #|
  #|       const geminiResult = await geminiResponse.json()
  #|       const textContent = geminiResult.candidates?.[0]?.content?.parts?.[0]?.text
  #|       steps.geminiParse = true
  #|
  #|       return c.json({ ok: true, steps, geminiResult: textContent, entries: entries.slice(0, 3) })
  #|     } catch (error) {
  #|       return c.json({ ok: false, steps, error: String(error), stack: error?.stack })
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
