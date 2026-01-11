///|
/// Scheduled handlers for Life Log application
/// Handles cron triggers for sync, analysis, and daily summaries

// ============================================================================
// Constants
// ============================================================================

///|
/// State key for last Gemini posted timestamp
let last_gemini_posted_key : String = "gemini:lastPostedAt"

///|
/// State key for morning summary date
let morning_summary_key : String = "gemini:morningSummaryDate"

///|
/// State key for evening summary date
let evening_summary_key : String = "gemini:eveningSummaryDate"

///|
/// State key for last updated timestamp
let last_updated_at_key : String = "lifelog:lastUpdatedAt"

///|
/// State key for last warning timestamp
let last_sync_warning_key : String = "lifelog:lastWarningAt"

// ============================================================================
// FFI Bindings (All use MoonBit services, no TypeScript imports)
// ============================================================================

///|
/// Get database instance from env
extern "js" fn ffi_get_db(env : @core.Any) -> @core.Any =
  #| (env) => env.LIFELOG_DB

///|
/// Helper to convert CPS-style MoonBit async functions to Promises
extern "js" fn ffi_to_promise() -> @core.Any =
  #| () => (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))

///|
/// Get sync state value using MoonBit services
extern "js" fn ffi_sched_get_state(
  db : @core.Any,
  key : String
) -> @js.Promise[String?] =
  #| async (db, key) => {
  #|   const toPromise = (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))
  #|   const services = await import('../services/services.js')
  #|   return await toPromise(services.get_sync_state_value, db, key)
  #| }

///|
/// Upsert sync state using MoonBit services
extern "js" fn ffi_sched_upsert_state(
  db : @core.Any,
  key : String,
  value : String
) -> @js.Promise[Unit] =
  #| async (db, key, value) => {
  #|   const toPromise = (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))
  #|   const services = await import('../services/services.js')
  #|   await toPromise(services.upsert_sync_state, db, key, value)
  #| }

///|
/// Sync lifelogs using MoonBit services
extern "js" fn ffi_sched_sync(
  db : @core.Any,
  env : @core.Any
) -> @js.Promise[@core.Any] =
  #| async (db, env) => {
  #|   const toPromise = (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))
  #|   const services = await import('../services/services.js')
  #|   return await toPromise(services.sync_lifelogs, db, env, { full_refresh: false })
  #| }

///|
/// Analyze fresh entries using MoonBit services
extern "js" fn ffi_sched_analyze(
  db : @core.Any,
  env : @core.Any,
  limit : Int
) -> @js.Promise[@core.Any] =
  #| async (db, env, limit) => {
  #|   const toPromise = (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))
  #|   const services = await import('../services/services.js')
  #|   return await toPromise(services.analyze_fresh_entries, db, env, {
  #|     entry_ids: [],
  #|     force: false,
  #|     limit
  #|   })
  #| }

///|
/// Analyze with Gemini using MoonBit services
extern "js" fn ffi_sched_gemini_insights(
  db : @core.Any,
  env : @core.Any,
  hours_back : Int,
  mode : String
) -> @js.Promise[@core.Any] =
  #| async (db, env, hoursBack, mode) => {
  #|   const toPromise = (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))
  #|   const services = await import('../services/services.js')
  #|   return await toPromise(services.analyze_insights_with_gemini, db, env, hoursBack, mode)
  #| }

///|
/// Post insights to Slack using MoonBit services
extern "js" fn ffi_sched_post_slack(
  env : @core.Any,
  insights : @core.Any,
  header : String?
) -> @js.Promise[Bool] =
  #| async (env, insights, header) => {
  #|   const toPromise = (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))
  #|   const services = await import('../services/services.js')
  #|   return await toPromise(services.post_insights_to_slack, env, insights, header ?? undefined)
  #| }

///|
/// Post error to Slack using MoonBit services
extern "js" fn ffi_sched_post_error(
  env : @core.Any,
  error_message : String,
  context : String
) -> @js.Promise[Unit] =
  #| async (env, errorMessage, context) => {
  #|   const toPromise = (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))
  #|   const services = await import('../services/services.js')
  #|   await toPromise(services.post_error_to_slack, env, new Error(errorMessage), context)
  #| }

///|
/// Post warning to Slack using MoonBit services
extern "js" fn ffi_sched_post_warning(
  env : @core.Any,
  message : String,
  context : String
) -> @js.Promise[Unit] =
  #| async (env, message, context) => {
  #|   const toPromise = (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))
  #|   const services = await import('../services/services.js')
  #|   await toPromise(services.post_warning_to_slack, env, message, context)
  #| }

///|
/// Get current timestamp ISO string
extern "js" fn ffi_sched_now() -> String =
  #| () => new Date().toISOString()

///|
/// Get JST hour from current time
extern "js" fn ffi_sched_jst_hour() -> Int =
  #| () => {
  #|   const now = new Date()
  #|   return (now.getUTCHours() + 9) % 24
  #| }

///|
/// Get JST date string (YYYY-MM-DD)
extern "js" fn ffi_sched_jst_date() -> String =
  #| () => {
  #|   const now = new Date()
  #|   const jst = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Tokyo' }))
  #|   const y = jst.getFullYear()
  #|   const m = String(jst.getMonth() + 1).padStart(2, '0')
  #|   const d = String(jst.getDate()).padStart(2, '0')
  #|   return `${y}-${m}-${d}`
  #| }

///|
/// Get JST yesterday date string (YYYY-MM-DD)
extern "js" fn ffi_sched_jst_yesterday() -> String =
  #| () => {
  #|   const now = new Date()
  #|   const jst = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Tokyo' }))
  #|   jst.setDate(jst.getDate() - 1)
  #|   const y = jst.getFullYear()
  #|   const m = String(jst.getMonth() + 1).padStart(2, '0')
  #|   const d = String(jst.getDate()).padStart(2, '0')
  #|   return `${y}-${m}-${d}`
  #| }

///|
/// Build JST date for specific hour
extern "js" fn ffi_sched_build_jst_date(
  base_date : String,
  hour : Int,
  minute : Int,
  second : Int
) -> String =
  #| (baseDate, hour, minute, second) => {
  #|   const [year, month, day] = baseDate.split('-').map(Number)
  #|   // Create JST date and convert to UTC
  #|   const jstMs = Date.UTC(year, month - 1, day, hour, minute, second) - 9 * 60 * 60 * 1000
  #|   return new Date(jstMs).toISOString()
  #| }

///|
/// Calculate hours since ISO timestamp
extern "js" fn ffi_sched_hours_since(iso : String?) -> Double? =
  #| (iso) => {
  #|   if (!iso) return null
  #|   const date = new Date(iso)
  #|   if (isNaN(date.getTime())) return null
  #|   return (Date.now() - date.getTime()) / (1000 * 60 * 60)
  #| }

///|
/// Log info message
extern "js" fn ffi_sched_log(message : String) -> Unit =
  #| (message) => console.log(message)

///|
/// Log warning message
extern "js" fn ffi_sched_warn(message : String) -> Unit =
  #| (message) => console.warn(message)

///|
/// Log error message
extern "js" fn ffi_sched_error(message : String) -> Unit =
  #| (message) => console.error(message)

///|
/// Check if sync stats indicate stale data
extern "js" fn ffi_sched_get_processed(stats : @core.Any) -> Int =
  #| (stats) => stats?.processed ?? 0

///|
/// Gemini daily analysis using MoonBit services
extern "js" fn ffi_sched_gemini_daily(
  db : @core.Any,
  env : @core.Any,
  from_iso : String,
  to_iso : String,
  max_entries : Int,
  max_segments : Int
) -> @js.Promise[@core.Any] =
  #| async (db, env, fromIso, toIso, maxEntries, maxSegments) => {
  #|   const toPromise = (fn, ...args) => new Promise((resolve, reject) => fn(...args, resolve, reject))
  #|   const services = await import('../services/services.js')
  #|   // Note: analyze_insights_with_gemini needs to support date range
  #|   // For now, calculate hours back from the range
  #|   const from = new Date(fromIso)
  #|   const to = new Date(toIso)
  #|   const hoursBack = Math.ceil((to.getTime() - from.getTime()) / (1000 * 60 * 60))
  #|   return await toPromise(services.analyze_insights_with_gemini, db, env, hoursBack, 'daily_summary')
  #| }

// ============================================================================
// Helper Functions
// ============================================================================

///|
/// Calculate hours since timestamp
fn hours_since(iso : String?) -> Double? {
  ffi_sched_hours_since(iso)
}

///|
/// Check if stale warning should be sent
async fn maybe_warn_stale_sync(
  db : @core.Any,
  env : @core.Any,
  stats_processed : Int,
  last_updated_before : String?
) -> Unit {
  if stats_processed == 0 {
    return
  }

  let last_updated_after = ffi_sched_get_state(db, last_updated_at_key).wait()

  // Check if we recently warned
  let last_warning_at = ffi_sched_get_state(db, last_sync_warning_key).wait()
  let hours_since_warning = hours_since(last_warning_at)
  match hours_since_warning {
    Some(h) =>
      if h < 3.0 {
        return
      }
    None => ()
  }

  // Check if sync was successful
  match last_updated_after {
    Some(after) =>
      match last_updated_before {
        Some(before) =>
          if after != before {
            return
          }
        None => ()
      }
    None => ()
  }

  let stale_ref = match last_updated_after {
    Some(s) => Some(s)
    None => last_updated_before
  }
  let stale_hours = hours_since(stale_ref)

  // Don't warn for short gaps
  match stale_hours {
    Some(h) =>
      if h < 3.0 {
        return
      }
    None => ()
  }

  let age_text = match stale_ref {
    Some(ref_time) => {
      let hours_str = match stale_hours {
        Some(h) => {
          let h_int = h.to_int()
          h_int.to_string()
        }
        None => "?"
      }
      "Last update: " + hours_str + " hours ago (" + ref_time + ")"
    }
    None => "No successful sync has occurred yet"
  }

  ffi_sched_warn(
    "[Limitless] Stale sync detected, sending Slack warning: " + age_text,
  )

  ffi_sched_post_warning(
    env,
    "Limitless sync is not fetching new data. " + age_text,
    "Limitless Sync",
  ).wait()

  ffi_sched_upsert_state(db, last_sync_warning_key, ffi_sched_now()).wait()
}

///|
/// Post daily summaries at morning (6 AM) and evening (11 PM) JST
async fn maybe_post_daily_summaries(db : @core.Any, env : @core.Any) -> Unit {
  let hour = ffi_sched_jst_hour()
  let today_str = ffi_sched_jst_date()

  // Morning 6 AM: Previous day 00:00-24:00
  if hour == 6 {
    let yesterday_str = ffi_sched_jst_yesterday()
    let last_posted = ffi_sched_get_state(db, morning_summary_key).wait()
    let should_post = match last_posted {
      Some(lp) => lp != yesterday_str
      None => true
    }

    if should_post {
      let range_start = ffi_sched_build_jst_date(yesterday_str, 0, 0, 0)
      let range_end = ffi_sched_build_jst_date(today_str, 0, 0, 0)

      let insights = ffi_sched_gemini_daily(
        db,
        env,
        range_start,
        range_end,
        200,
        400,
      ).wait()

      if not(@core.is_nullish(insights)) {
        let header = "@kazuph 🌅 Previous Day Summary (JST)\n_" + yesterday_str + "_\n\n"
        let posted = ffi_sched_post_slack(env, insights, Some(header)).wait()
        if posted {
          ffi_sched_upsert_state(db, morning_summary_key, yesterday_str).wait()
        }
      }
    }
  }

  // Evening 11 PM: Today 06:00-23:00
  if hour == 23 {
    let last_posted = ffi_sched_get_state(db, evening_summary_key).wait()
    let should_post = match last_posted {
      Some(lp) => lp != today_str
      None => true
    }

    if should_post {
      let range_start = ffi_sched_build_jst_date(today_str, 6, 0, 0)
      let range_end = ffi_sched_build_jst_date(today_str, 23, 59, 59)

      let insights = ffi_sched_gemini_daily(
        db,
        env,
        range_start,
        range_end,
        200,
        400,
      ).wait()

      if not(@core.is_nullish(insights)) {
        let header = "@kazuph 🌙 Today's Summary (JST)\n_" +
          today_str +
          " 06:00-23:00_\n\n"
        let posted = ffi_sched_post_slack(env, insights, Some(header)).wait()
        if posted {
          ffi_sched_upsert_state(db, evening_summary_key, today_str).wait()
        }
      }
    }
  }
}

// ============================================================================
// Public API
// ============================================================================

///|
/// Main scheduled handler - called by Cloudflare Workers cron trigger
pub async fn handle_scheduled(env : @core.Any, _ctx : @core.Any) -> Unit {
  let db = ffi_get_db(env)
  let last_updated_before = ffi_sched_get_state(db, last_updated_at_key).wait()
  let mut sync_processed = 0

  // 1. Sync lifelogs from Limitless API
  let sync_result = try {
    let stats = ffi_sched_sync(db, env).wait()
    sync_processed = ffi_sched_get_processed(stats)
    ffi_sched_log("[Scheduled] Sync completed: " + sync_processed.to_string() + " processed")
  } catch {
    e => {
      ffi_sched_error("[Scheduled] Sync failed: " + e.to_string())
      ffi_sched_post_error(env, e.to_string(), "Limitless Sync").wait()
    }
  }
  ignore(sync_result)

  // Check for stale sync
  maybe_warn_stale_sync(db, env, sync_processed, last_updated_before)

  // 2. Analyze fresh entries with Workers AI
  let analyze_result = try {
    let _ = ffi_sched_analyze(db, env, 3).wait()
    ffi_sched_log("[Scheduled] Analysis completed")
  } catch {
    e => {
      ffi_sched_error("[Scheduled] Analysis failed: " + e.to_string())
      ffi_sched_post_error(env, e.to_string(), "Workers AI Analysis").wait()
    }
  }
  ignore(analyze_result)

  // 3. Gemini insights and Slack posting
  let insights_result = try {
    let last_posted_at = ffi_sched_get_state(db, last_gemini_posted_key).wait()
    let hours_since_last = match hours_since(last_posted_at) {
      Some(h) => {
        let h_int = h.to_int()
        if h_int < 1 { 1 } else if h_int > 24 { 24 } else { h_int }
      }
      None => 1
    }

    let insights = ffi_sched_gemini_insights(
      db,
      env,
      hours_since_last,
      "hourly_bullets",
    ).wait()

    if not(@core.is_nullish(insights)) {
      let posted = ffi_sched_post_slack(env, insights, None).wait()
      if posted {
        ffi_sched_upsert_state(db, last_gemini_posted_key, ffi_sched_now()).wait()
        ffi_sched_log("[Scheduled] Insights posted to Slack")
      }
    }
  } catch {
    e => {
      ffi_sched_error("[Scheduled] Gemini insights failed: " + e.to_string())
      ffi_sched_post_error(env, e.to_string(), "Gemini Analysis/Slack Post").wait()
    }
  }
  ignore(insights_result)

  // 4. Daily summaries at morning/evening
  let daily_result = try {
    maybe_post_daily_summaries(db, env)
  } catch {
    e => {
      ffi_sched_error("[Scheduled] Daily summary failed: " + e.to_string())
      ffi_sched_post_error(env, e.to_string(), "Daily Gemini Summary").wait()
    }
  }
  ignore(daily_result)
}

///|
/// Create scheduled handler for export
extern "js" fn ffi_create_scheduled_handler() -> @core.Any =
  #| () => {
  #|   return async (event, env, ctx) => {
  #|     const server = await import('./server.js')
  #|     await server.handle_scheduled(env, ctx)
  #|   }
  #| }

///|
/// Get the scheduled handler function
pub fn get_scheduled_handler() -> @core.Any {
  ffi_create_scheduled_handler()
}
