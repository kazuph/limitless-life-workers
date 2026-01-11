///|
/// Day summary service for generating daily tweet-style summaries
/// Groups entries by 3-hour time windows and generates tweets for each window

// ============================================================================
// Constants
// ============================================================================

///|
/// Primary model for Workers AI
let day_model : String = "@cf/openai/gpt-oss-120b"

///|
/// Gemini fallback model
let day_gemini_model : String = "gemini-2.0-flash"

///|
/// Gemini API URL
let day_gemini_url : String = "https://generativelanguage.googleapis.com/v1beta/models"

///|
/// Sync state key prefix for day summaries
let summary_key_prefix : String = "day_summary:"

// ============================================================================
// Types
// ============================================================================

///|
/// Tweet with time
pub struct DayTweet {
  text : String
  time : String
}

///|
/// Day summary result
pub struct DaySummaryResult {
  date : String
  tweets : Array[DayTweet]
  generated_at : String
  source : String // "cached" | "generated" | "unavailable"
  model : String?
}

///|
/// Preferred AI provider
pub enum PreferredProvider {
  OpenAI
  Gemini
}

///|
/// Options for getting day summary
pub struct DaySummaryOptions {
  force : Bool
  preferred_model : PreferredProvider
}

///|
/// Default options
pub fn DaySummaryOptions::default() -> DaySummaryOptions {
  { force: false, preferred_model: PreferredProvider::OpenAI }
}

///|
/// Time window definition
struct TimeWindow {
  start : Int
  end : Int
  label : String
}

///|
/// Entry data for summary generation
struct SummaryEntry {
  id : String
  title : String
  markdown : String?
  start_time : String?
  end_time : String?
  analysis_json : String?
}

///|
/// Stored summary format
struct StoredSummary {
  tweets : Array[DayTweet]
  generated_at : String
  model : String?
}

// ============================================================================
// Time Windows (3-hour intervals)
// ============================================================================

///|
/// Get all time windows
fn get_time_windows() -> Array[TimeWindow] {
  [
    { start: 0, end: 2, label: "0-2" },
    { start: 3, end: 5, label: "3-5" },
    { start: 6, end: 8, label: "6-8" },
    { start: 9, end: 11, label: "9-11" },
    { start: 12, end: 14, label: "12-14" },
    { start: 15, end: 17, label: "15-17" },
    { start: 18, end: 20, label: "18-20" },
    { start: 21, end: 23, label: "21-23" },
  ]
}

///|
/// Get time window label for a given hour
fn get_time_window_label(hour : Int) -> String? {
  let windows = get_time_windows()
  for window in windows {
    if hour >= window.start && hour <= window.end {
      return Some(window.label)
    }
  }
  None
}

///|
/// Get midpoint time for a window label
fn get_window_midpoint_time(window_label : String) -> String {
  let windows = get_time_windows()
  for window in windows {
    if window.label == window_label {
      let mid_hour = (window.start + window.end) / 2
      let hour_str = if mid_hour < 10 {
        "0" + mid_hour.to_string()
      } else {
        mid_hour.to_string()
      }
      return hour_str + ":30"
    }
  }
  "12:00"
}

// ============================================================================
// FFI Bindings
// ============================================================================

///|
/// Get sync state value (direct D1)
extern "js" fn ffi_get_state(db : @core.Any, key : String) -> @js.Promise[String?] =
  #| async (db, key) => {
  #|   const result = await db.prepare(
  #|     'SELECT value FROM sync_state WHERE key = ?'
  #|   ).bind(key).first()
  #|   return result?.value ?? null
  #| }

///|
/// Upsert sync state (direct D1)
extern "js" fn ffi_upsert_state(
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
/// Delete sync state key (direct D1)
extern "js" fn ffi_delete_state(db : @core.Any, key : String) -> @js.Promise[Unit] =
  #| async (db, key) => {
  #|   await db.prepare(
  #|     'DELETE FROM sync_state WHERE key = ?'
  #|   ).bind(key).run()
  #| }

///|
/// Parse date range for JST timezone
extern "js" fn ffi_parse_date_range(date : String) -> @core.Any =
  #| (date) => {
  #|   const [year, month, day] = date.split('-').map(v => Number(v))
  #|   if (!year || !month || !day) return null
  #|   const startUtc = Date.UTC(year, month - 1, day, 0, 0, 0) - 9 * 60 * 60 * 1000
  #|   const endUtc = startUtc + 24 * 60 * 60 * 1000
  #|   return {
  #|     startIso: new Date(startUtc).toISOString(),
  #|     endIso: new Date(endUtc).toISOString()
  #|   }
  #| }

///|
/// Fetch entries for a date range (raw SQL)
extern "js" fn ffi_fetch_entries(
  db : @core.Any,
  start_iso : String,
  end_iso : String
) -> @js.Promise[@core.Any] =
  #| async (db, startIso, endIso) => {
  #|   const result = await db.prepare(`
  #|     SELECT
  #|       e.id, e.title, e.markdown, e.start_time as startTime, e.end_time as endTime,
  #|       a.insights_json as analysisJson
  #|     FROM lifelog_entries e
  #|     LEFT JOIN lifelog_analyses a ON a.entry_id = e.id AND a.version = 'v1'
  #|     WHERE e.start_time >= ? AND e.start_time < ?
  #|     ORDER BY e.start_time DESC
  #|     LIMIT 120
  #|   `).bind(startIso, endIso).all()
  #|   return result.results || []
  #| }

///|
/// Run Workers AI for summary
extern "js" fn ffi_run_summary_ai(
  env : @core.Any,
  model : String,
  prompt : String
) -> @js.Promise[@core.Any] =
  #| async (env, model, prompt) => {
  #|   if (!env.AI) return null
  #|   return await env.AI.run(model, { input: prompt })
  #| }

///|
/// Call Gemini for summary
extern "js" fn ffi_call_gemini_summary(
  api_key : String,
  prompt : String
) -> @js.Promise[@core.Any] =
  #| async (apiKey, prompt) => {
  #|   const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`
  #|   try {
  #|     const response = await fetch(url, {
  #|       method: 'POST',
  #|       headers: { 'Content-Type': 'application/json' },
  #|       body: JSON.stringify({
  #|         contents: [{ parts: [{ text: prompt }] }],
  #|         generationConfig: {
  #|           responseMimeType: 'application/json',
  #|           temperature: 0.4,
  #|           maxOutputTokens: 2048
  #|         }
  #|       })
  #|     })
  #|     if (!response.ok) return null
  #|     const result = await response.json()
  #|     return result?.candidates?.[0]?.content?.parts?.[0]?.text ?? null
  #|   } catch {
  #|     return null
  #|   }
  #| }

///|
/// Get environment variable
extern "js" fn ffi_env_var(env : @core.Any, key : String) -> String? =
  #| (env, key) => env[key] ?? null

///|
/// Check if Workers AI is available
extern "js" fn ffi_has_workers_ai(env : @core.Any) -> Bool =
  #| (env) => Boolean(env.AI)

///|
/// Get current timestamp
extern "js" fn ffi_timestamp() -> String =
  #| () => new Date().toISOString()

///|
/// Parse JSON
extern "js" fn ffi_day_json_parse(text : String) -> @core.Any =
  #| (text) => {
  #|   try { return JSON.parse(text) }
  #|   catch { return null }
  #| }

///|
/// Stringify JSON
extern "js" fn ffi_json_stringify(value : @core.Any) -> String =
  #| (value) => JSON.stringify(value)

///|
/// Get JST hour from ISO string
extern "js" fn ffi_get_jst_hour(iso_string : String) -> Int =
  #| (isoString) => {
  #|   const date = new Date(isoString)
  #|   return (date.getUTCHours() + 9) % 24
  #| }

///|
/// Log message
extern "js" fn ffi_log_msg(message : String) -> Unit =
  #| (message) => console.log(message)

///|
/// Log error
extern "js" fn ffi_log_error(message : String) -> Unit =
  #| (message) => console.error(message)

// ============================================================================
// JSON Schema for Summary
// ============================================================================

///|
/// Build summary JSON schema
fn build_summary_schema() -> @core.Any {
  @core.from_entries(
    [
      ("type", @core.any("object")),
      (
        "properties",
        @core.from_entries(
          [
            (
              "tweets",
              @core.from_entries(
                [
                  ("type", @core.any("array")),
                  (
                    "items",
                    @core.from_entries(
                      [
                        ("type", @core.any("object")),
                        (
                          "properties",
                          @core.from_entries(
                            [
                              (
                                "window",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                              (
                                "text",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                            ],
                          ),
                        ),
                        (
                          "required",
                          {
                            let arr : Array[String] = ["window", "text"]
                            @core.any(arr)
                          },
                        ),
                      ],
                    ),
                  ),
                  ("maxItems", @core.any(8)),
                ],
              ),
            ),
          ],
        ),
      ),
      ("required", {
        let arr : Array[String] = ["tweets"]
        @core.any(arr)
      }),
    ],
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

///|
/// Build summary prompt
fn build_summary_prompt(payload : String, windows : Array[String]) -> String {
  let windows_str = windows.iter().fold(
    init="",
    fn(acc, w) {
      if acc.length() == 0 { w } else { acc + ", " + w }
    },
  )
  let schema = build_summary_schema()
  let schema_text = ffi_json_stringify(schema)

  "You are a diary editor.\nThe following is lifelog summary material for one day. Generate one 'tweet that symbolizes the time period' for each time period.\n\nRules:\n- Each tweet should be approximately 80-200 characters\n- Avoid bullet points or bullet-point-like symbols\n- Keep proper nouns to a minimum and summarize in natural language\n- Generate tweets that reflect the content of each time period\n- Only generate for time periods that have data (following time periods: " +
  windows_str +
  ")\n\nOutput only JSON, strictly following this schema:\n" +
  schema_text +
  "\n\nMaterial:\n" +
  payload
}

///|
/// Extract response payload from AI response
fn extract_summary_response(result : @core.Any) -> String {
  if @core.is_nullish(result) {
    return ""
  }
  let type_of = @core.typeof_(result)
  if type_of == "string" {
    return result.cast()
  }
  let response = result["response"]
  if not(@core.is_nullish(response)) {
    let resp_type = @core.typeof_(response)
    if resp_type == "string" {
      return response.cast()
    }
  }
  let output_text = result["output_text"]
  if not(@core.is_nullish(output_text)) {
    let arr = @core.array_from(output_text)
    let mut text = ""
    for item in arr {
      let item_type = @core.typeof_(item)
      if item_type == "string" {
        let s : String = item.cast()
        text = text + s + "\n"
      }
    }
    if text.length() > 0 {
      return text
    }
  }
  let output = result["output"]
  if not(@core.is_nullish(output)) {
    let arr = @core.array_from(output)
    let mut text = ""
    for item in arr {
      let content = item["content"]
      if not(@core.is_nullish(content)) {
        let content_arr = @core.array_from(content)
        for part in content_arr {
          let part_text = part["text"]
          if not(@core.is_nullish(part_text)) {
            let s : String = part_text.cast()
            text = text + s + "\n"
          }
        }
      }
    }
    if text.length() > 0 {
      return text
    }
  }
  ""
}

///|
/// Parse tweets from AI response
fn parse_tweets(raw : String) -> Array[DayTweet] {
  let result : Array[DayTweet] = []

  fn try_parse(json_str : String) -> Bool {
    let parsed = ffi_day_json_parse(json_str)
    if @core.is_nullish(parsed) {
      return false
    }
    let tweets_json = parsed["tweets"]
    if @core.is_nullish(tweets_json) {
      return false
    }
    let arr = @core.array_from(tweets_json)
    for tweet in arr {
      let text_val = tweet["text"]
      let window_val = tweet["window"]
      if @core.is_nullish(text_val) {
        continue
      }
      let text : String = text_val.cast()
      let window : String = if @core.is_nullish(window_val) {
        "12-14"
      } else {
        window_val.cast()
      }
      let time = get_window_midpoint_time(window)
      result.push({ text, time })
    }
    result.length() > 0
  }

  // Try direct parse first
  if try_parse(raw) {
    return result
  }

  // Try to extract JSON from text
  let chars = raw.to_array()
  let mut start = -1
  let mut end = -1
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '{' && start == -1 {
      start = i
    }
    if chars[i] == '}' {
      end = i
    }
  }

  if start >= 0 && end > start {
    let mut json_str = ""
    for i = start; i <= end; i = i + 1 {
      json_str = json_str + chars[i].to_string()
    }
    ignore(try_parse(json_str))
  }

  result
}

///|
/// Parse entries from database result
fn parse_summary_entries(json : @core.Any) -> Array[SummaryEntry] {
  let result : Array[SummaryEntry] = []
  if @core.is_nullish(json) {
    return result
  }
  let arr = @core.array_from(json)
  for item in arr {
    let id : String = item["id"].cast()
    let title : String = item["title"].cast()
    let markdown : String? = @core.identity_option(item["markdown"])
    let start_time : String? = @core.identity_option(item["startTime"])
    let end_time : String? = @core.identity_option(item["endTime"])
    let analysis_json : String? = @core.identity_option(item["analysisJson"])
    result.push({ id, title, markdown, start_time, end_time, analysis_json })
  }
  result
}

///|
/// Get active time windows from entries
fn get_active_windows(entries : Array[SummaryEntry]) -> Array[String] {
  let windows : Array[String] = []
  let seen : Array[String] = []

  for entry in entries {
    match entry.start_time {
      Some(st) => {
        let jst_hour = ffi_get_jst_hour(st)
        match get_time_window_label(jst_hour) {
          Some(label) => {
            let mut found = false
            for s in seen {
              if s == label {
                found = true
                break
              }
            }
            if not(found) {
              seen.push(label)
              windows.push(label)
            }
          }
          None => ()
        }
      }
      None => ()
    }
  }

  // Sort windows by start time
  let all_windows = get_time_windows()
  let sorted : Array[String] = []
  for w in all_windows {
    for label in windows {
      if w.label == label {
        sorted.push(label)
        break
      }
    }
  }
  sorted
}

///|
/// Build prompt payload from entries
fn build_summary_payload(
  date : String,
  entries : Array[SummaryEntry],
  active_windows : Array[String]
) -> String {
  let items : Array[@core.Any] = []

  for entry in entries {
    let markdown_snippet = match entry.markdown {
      Some(md) =>
        if md.length() > 240 {
          let chars = md.to_array()
          let mut snippet = ""
          for i = 0; i < 240 && i < chars.length(); i = i + 1 {
            snippet = snippet + chars[i].to_string()
          }
          Some(snippet)
        } else {
          Some(md)
        }
      None => None
    }

    let analysis_summary : String? = match entry.analysis_json {
      Some(json) => {
        let parsed = ffi_day_json_parse(json)
        if @core.is_nullish(parsed) {
          None
        } else {
          @core.identity_option(parsed["summary"])
        }
      }
      None => None
    }

    let window : String? = match entry.start_time {
      Some(st) => {
        let jst_hour = ffi_get_jst_hour(st)
        get_time_window_label(jst_hour)
      }
      None => None
    }

    let item = @core.from_entries(
      [
        ("title", @core.any(entry.title)),
        ("startTime", @core.nullable(entry.start_time)),
        ("endTime", @core.nullable(entry.end_time)),
        ("analysisSummary", @core.nullable(analysis_summary)),
        ("markdownSnippet", @core.nullable(markdown_snippet)),
        ("window", @core.nullable(window)),
      ],
    )
    items.push(item)
  }

  let payload = @core.from_entries(
    [
      ("date", @core.any(date)),
      ("items", @core.any(items)),
      ("activeWindows", @core.any(active_windows)),
    ],
  )

  ffi_json_stringify(payload)
}

///|
/// Generate summary with Gemini
async fn generate_with_gemini(
  env : @core.Any,
  payload : String,
  date : String,
  active_windows : Array[String]
) -> DaySummaryResult? {
  let api_key = ffi_env_var(env, "GEMINI_API_KEY")
  match api_key {
    None => None
    Some(key) => {
      let prompt = build_summary_prompt(payload, active_windows)
      let result = ffi_call_gemini_summary(key, prompt).wait()
      if @core.is_nullish(result) {
        return None
      }
      let text : String = result.cast()
      let tweets = parse_tweets(text)
      if tweets.length() == 0 {
        return None
      }
      let now = ffi_timestamp()
      Some(
        {
          date,
          tweets,
          generated_at: now,
          source: "generated",
          model: Some(day_gemini_model),
        },
      )
    }
  }
}

///|
/// Summarize from entries
async fn summarize_from_entries(
  db : @core.Any,
  env : @core.Any,
  date : String,
  preferred_model : PreferredProvider
) -> DaySummaryResult {
  let now = ffi_timestamp()

  // Parse date range
  let range = ffi_parse_date_range(date)
  if @core.is_nullish(range) {
    return {
      date,
      tweets: [],
      generated_at: now,
      source: "unavailable",
      model: None,
    }
  }

  let start_iso : String = range["startIso"].cast()
  let end_iso : String = range["endIso"].cast()

  // Fetch entries
  let entries_json = ffi_fetch_entries(db, start_iso, end_iso).wait()
  let entries = parse_summary_entries(entries_json)

  if entries.length() == 0 {
    return {
      date,
      tweets: [],
      generated_at: now,
      source: "unavailable",
      model: None,
    }
  }

  // Check if Workers AI is available
  if not(ffi_has_workers_ai(env)) {
    return {
      date,
      tweets: [],
      generated_at: now,
      source: "unavailable",
      model: None,
    }
  }

  // Check if Workers AI is disabled
  match ffi_env_var(env, "DISABLE_WORKERS_AI") {
    Some("1") =>
      return {
        date,
        tweets: [],
        generated_at: now,
        source: "unavailable",
        model: None,
      }
    _ => ()
  }

  // Get active windows
  let active_windows = get_active_windows(entries)
  if active_windows.length() == 0 {
    return {
      date,
      tweets: [],
      generated_at: now,
      source: "unavailable",
      model: None,
    }
  }

  // Build payload
  let prompt_payload = build_summary_payload(date, entries, active_windows)
  let allow_gemini_fallback = match preferred_model {
    PreferredProvider::Gemini => false
    PreferredProvider::OpenAI => true
  }

  // Try Gemini first if preferred
  match preferred_model {
    PreferredProvider::Gemini => {
      let gemini_result = generate_with_gemini(
        env,
        prompt_payload,
        date,
        active_windows,
      )
      match gemini_result {
        Some(r) => return r
        None => ()
      }
    }
    _ => ()
  }

  // Try Workers AI
  let prompt = build_summary_prompt(prompt_payload, active_windows)
  let response = ffi_run_summary_ai(env, day_model, prompt).wait()
  let summary_text = extract_summary_response(response)
  let tweets = parse_tweets(summary_text)

  // Fallback to Gemini if no tweets and allowed
  if tweets.length() == 0 && allow_gemini_fallback {
    let gemini_result = generate_with_gemini(
      env,
      prompt_payload,
      date,
      active_windows,
    )
    match gemini_result {
      Some(r) => return r
      None => ()
    }
  }

  {
    date,
    tweets,
    generated_at: now,
    source: if tweets.length() > 0 { "generated" } else { "unavailable" },
    model: if tweets.length() > 0 { Some(day_model) } else { None },
  }
}

///|
/// Parse stored summary from cache
fn parse_stored_summary(json_str : String, date : String) -> DaySummaryResult? {
  let parsed = ffi_day_json_parse(json_str)
  if @core.is_nullish(parsed) {
    return None
  }

  let tweets_json = parsed["tweets"]
  if @core.is_nullish(tweets_json) {
    return None
  }

  let tweets : Array[DayTweet] = []
  let arr = @core.array_from(tweets_json)
  for tweet in arr {
    let text_val = tweet["text"]
    let time_val = tweet["time"]
    if @core.is_nullish(text_val) {
      continue
    }
    let text : String = text_val.cast()
    let time : String = if @core.is_nullish(time_val) {
      "12:00"
    } else {
      time_val.cast()
    }
    tweets.push({ text, time })
  }

  if tweets.length() == 0 {
    return None
  }

  let generated_at : String = if @core.is_nullish(parsed["generatedAt"]) {
    ffi_timestamp()
  } else {
    parsed["generatedAt"].cast()
  }

  let model : String? = @core.identity_option(parsed["model"])

  Some({ date, tweets, generated_at, source: "cached", model })
}

// ============================================================================
// Public API
// ============================================================================

///|
/// Get day summary - returns cached or generates new
pub async fn get_day_summary(
  db : @core.Any,
  env : @core.Any,
  date : String,
  opts : DaySummaryOptions
) -> DaySummaryResult {
  let key = summary_key_prefix + date

  // Force regeneration if requested
  if opts.force {
    ffi_delete_state(db, key).wait()
  }

  // Try to get cached summary
  let cached = ffi_get_state(db, key).wait()
  match cached {
    Some(cached_str) => {
      let parsed = parse_stored_summary(cached_str, date)
      match parsed {
        Some(result) => return result
        None => ()
      }
    }
    None => ()
  }

  // Generate new summary
  let generated = summarize_from_entries(db, env, date, opts.preferred_model)

  // Cache the result
  let stored = @core.from_entries(
    [
      ("tweets", @core.any(generated.tweets)),
      ("generatedAt", @core.any(generated.generated_at)),
      ("model", @core.nullable(generated.model)),
    ],
  )
  let stored_str = ffi_json_stringify(stored)
  ffi_upsert_state(db, key, stored_str).wait()

  generated
}

///|
/// Regenerate day summary (force refresh)
pub async fn regenerate_day_summary(
  db : @core.Any,
  env : @core.Any,
  date : String,
  preferred_model : PreferredProvider
) -> DaySummaryResult {
  get_day_summary(db, env, date, { force: true, preferred_model })
}
