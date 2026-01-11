///|
/// Timeline service for Life Log application
/// Provides timeline snapshot and entry detail functions

// ============================================================================
// FFI Bindings for D1 access
// ============================================================================

///|
/// Execute timeline snapshot query via D1
extern "js" fn ffi_get_timeline_snapshot(
  db : @core.Any,
  days : Int,
  offset : Int,
  detail : Bool,
  analysis_limit : Int
) -> @js.Promise[@core.Any] =
  #| async (db, days, offset, detail, analysisLimit) => {
  #|   const now = new Date()
  #|   const startDate = new Date(now.getTime() - (days + offset) * 24 * 60 * 60 * 1000)
  #|   const endDate = new Date(now.getTime() - offset * 24 * 60 * 60 * 1000)
  #|   const startStr = startDate.toISOString()
  #|   const endStr = endDate.toISOString()
  #|
  #|   // Get entries in date range
  #|   const entriesResult = await db.prepare(`
  #|     SELECT
  #|       e.id, e.title, e.markdown, e.start_time, e.end_time,
  #|       e.start_epoch_ms, e.end_epoch_ms, e.is_starred,
  #|       e.updated_at, e.ingested_at, e.timezone,
  #|       e.summary_hash, e.last_analyzed_at
  #|     FROM lifelog_entries e
  #|     WHERE e.start_time >= ? AND e.start_time <= ?
  #|     ORDER BY e.start_time DESC
  #|   `).bind(startStr, endStr).all()
  #|
  #|   const entries = entriesResult.results || []
  #|   const timeline = []
  #|
  #|   // Get analyses for entries (limited)
  #|   const analysisMap = new Map()
  #|   if (analysisLimit > 0) {
  #|     const entryIds = entries.slice(0, analysisLimit).map(e => e.id)
  #|     if (entryIds.length > 0) {
  #|       const placeholders = entryIds.map(() => '?').join(',')
  #|       const analysesResult = await db.prepare(`
  #|         SELECT entry_id, insights_json
  #|         FROM lifelog_analyses
  #|         WHERE entry_id IN (${placeholders})
  #|       `).bind(...entryIds).all()
  #|
  #|       for (const row of (analysesResult.results || [])) {
  #|         try {
  #|           analysisMap.set(row.entry_id, JSON.parse(row.insights_json))
  #|         } catch (e) {
  #|           console.warn('Failed to parse analysis JSON:', e)
  #|         }
  #|       }
  #|     }
  #|   }
  #|
  #|   // Build timeline entries
  #|   for (const entry of entries) {
  #|     const segments = []
  #|
  #|     if (detail) {
  #|       // Get segments for this entry
  #|       const segmentsResult = await db.prepare(`
  #|         SELECT
  #|           node_id, content, start_time, end_time,
  #|           node_type, speaker_name
  #|         FROM lifelog_segments
  #|         WHERE entry_id = ?
  #|         ORDER BY start_time ASC
  #|       `).bind(entry.id).all()
  #|
  #|       for (const seg of (segmentsResult.results || [])) {
  #|         segments.push({
  #|           id: seg.node_id,
  #|           content: seg.content,
  #|           start_time: seg.start_time,
  #|           end_time: seg.end_time,
  #|           node_type: seg.node_type,
  #|           speaker_name: seg.speaker_name
  #|         })
  #|       }
  #|     }
  #|
  #|     // Calculate duration
  #|     let durationMinutes = null
  #|     if (entry.start_epoch_ms && entry.end_epoch_ms) {
  #|       durationMinutes = Math.round((entry.end_epoch_ms - entry.start_epoch_ms) / 60000)
  #|     }
  #|
  #|     // Format date label
  #|     const startDate = new Date(entry.start_time)
  #|     const dateLabel = startDate.toISOString().split('T')[0]
  #|
  #|     timeline.push({
  #|       id: entry.id,
  #|       title: entry.title || 'Untitled',
  #|       start_time: entry.start_time,
  #|       end_time: entry.end_time,
  #|       date_label: dateLabel,
  #|       duration_minutes: durationMinutes,
  #|       segments,
  #|       analysis: analysisMap.get(entry.id) || null
  #|     })
  #|   }
  #|
  #|   return timeline
  #| }

///|
/// Get single entry detail
extern "js" fn ffi_get_timeline_entry_detail(
  db : @core.Any,
  entry_id : String
) -> @js.Promise[@core.Any] =
  #| async (db, entryId) => {
  #|   // Get entry
  #|   const entryResult = await db.prepare(`
  #|     SELECT
  #|       id, title, markdown, start_time, end_time,
  #|       start_epoch_ms, end_epoch_ms, is_starred,
  #|       updated_at, ingested_at, timezone,
  #|       summary_hash, last_analyzed_at
  #|     FROM lifelog_entries
  #|     WHERE id = ?
  #|   `).bind(entryId).first()
  #|
  #|   if (!entryResult) return null
  #|
  #|   // Get segments
  #|   const segmentsResult = await db.prepare(`
  #|     SELECT
  #|       node_id, content, start_time, end_time,
  #|       node_type, speaker_name, speaker_identifier
  #|     FROM lifelog_segments
  #|     WHERE entry_id = ?
  #|     ORDER BY start_time ASC
  #|   `).bind(entryId).all()
  #|
  #|   const segments = (segmentsResult.results || []).map(seg => ({
  #|     id: seg.node_id,
  #|     content: seg.content,
  #|     start_time: seg.start_time,
  #|     end_time: seg.end_time,
  #|     node_type: seg.node_type,
  #|     speaker_name: seg.speaker_name
  #|   }))
  #|
  #|   // Get analysis
  #|   const analysisResult = await db.prepare(`
  #|     SELECT insights_json
  #|     FROM lifelog_analyses
  #|     WHERE entry_id = ?
  #|     ORDER BY created_at DESC
  #|     LIMIT 1
  #|   `).bind(entryId).first()
  #|
  #|   let analysis = null
  #|   if (analysisResult?.insights_json) {
  #|     try {
  #|       analysis = JSON.parse(analysisResult.insights_json)
  #|     } catch (e) {
  #|       console.warn('Failed to parse analysis JSON:', e)
  #|     }
  #|   }
  #|
  #|   // Calculate duration
  #|   let durationMinutes = null
  #|   if (entryResult.start_epoch_ms && entryResult.end_epoch_ms) {
  #|     durationMinutes = Math.round((entryResult.end_epoch_ms - entryResult.start_epoch_ms) / 60000)
  #|   }
  #|
  #|   // Format date label
  #|   const startDate = new Date(entryResult.start_time)
  #|   const dateLabel = startDate.toISOString().split('T')[0]
  #|
  #|   return {
  #|     id: entryResult.id,
  #|     title: entryResult.title || 'Untitled',
  #|     markdown: entryResult.markdown,
  #|     start_time: entryResult.start_time,
  #|     end_time: entryResult.end_time,
  #|     date_label: dateLabel,
  #|     duration_minutes: durationMinutes,
  #|     is_starred: entryResult.is_starred === 1,
  #|     segments,
  #|     analysis
  #|   }
  #| }

// ============================================================================
// Public API
// ============================================================================

///|
/// Get timeline snapshot for display
pub async fn get_timeline_snapshot(
  db : @core.Any,
  days : Int,
  offset : Int,
  detail : Bool,
  analysis_limit : Int
) -> @core.Any {
  ffi_get_timeline_snapshot(db, days, offset, detail, analysis_limit).wait()
}

///|
/// Get single entry detail
pub async fn get_timeline_entry_detail(
  db : @core.Any,
  entry_id : String
) -> @core.Any {
  ffi_get_timeline_entry_detail(db, entry_id).wait()
}

///|
/// Get integration suggestions (static list)
pub fn get_integration_suggestions() -> @core.Any {
  ffi_get_integrations()
}

///|
/// Static integration suggestions
extern "js" fn ffi_get_integrations() -> @core.Any =
  #| () => [
  #|   { id: 'linear', name: 'Linear', icon: '📋' },
  #|   { id: 'notion', name: 'Notion', icon: '📝' },
  #|   { id: 'slack', name: 'Slack', icon: '💬' },
  #|   { id: 'github', name: 'GitHub', icon: '🐙' },
  #|   { id: 'calendar', name: 'Calendar', icon: '📅' }
  #| ]
