///|
/// Analysis service for processing lifelogs with AI models
/// Uses Workers AI (@cf/openai/gpt-oss-120b) with Gemini fallback

// ============================================================================
// Constants
// ============================================================================

///|
/// Primary model for Workers AI
let analysis_ai_model : String = "@cf/openai/gpt-oss-120b"

///|
/// Gemini fallback model for analysis
let analysis_gemini_model : String = "gemini-2.0-flash"

///|
/// Analysis version for tracking
let analysis_version : String = "v1"

///|
/// State key for last analyzed timestamp
let last_analyzed_key : String = "lifelog:lastAnalyzedAt"

///|
/// System prompt for analysis
let analysis_system_prompt : String = "You are a productivity coach. Read the given lifelog and create a summary and action suggestions in Japanese that are easy to understand even in monochrome display. The mood field must always be output in the format 'emoji text' (e.g.: happy and positive, tired, motivated)."

// ============================================================================
// Types
// ============================================================================

///|
/// Analysis result JSON structure
pub struct AnalysisJSON {
  summary : String
  mood : String
  tags : Array[String]
  time_blocks : Array[TimeBlock]
  action_items : Array[AnalysisActionItem]
  suggestions : Array[AnalysisSuggestion]
}

///|
/// Time block in analysis
pub struct TimeBlock {
  start_time : String?
  end_time : String?
  label : String
  details : String?
}

///|
/// Action item in analysis
pub struct AnalysisActionItem {
  title : String
  suggested_integration : String?
  due : String?
}

///|
/// Suggestion in analysis
pub struct AnalysisSuggestion {
  target : String
  rationale : String
}

///|
/// Options for analysis
pub struct AnalyzeOptions {
  limit : Int
  entry_ids : Array[String]
  force : Bool
}

///|
/// Default analysis options
pub fn AnalyzeOptions::default() -> AnalyzeOptions {
  { limit: 2, entry_ids: [], force: false }
}

///|
/// Entry candidate for analysis
struct EntryCandidate {
  id : String
  title : String
  markdown : String?
  start_time : String?
  end_time : String?
  summary_hash : String?
}

///|
/// Segment data for analysis
struct SegmentData {
  content : String?
  start_time : String?
  end_time : String?
  speaker_name : String?
  node_type : String?
}

// ============================================================================
// FFI Bindings
// ============================================================================

///|
/// Get sync state value (direct D1 call)
extern "js" fn ffi_analysis_get_state(
  db : @core.Any,
  key : String
) -> @js.Promise[String?] =
  #| async (db, key) => {
  #|   const result = await db.prepare(
  #|     'SELECT value FROM sync_state WHERE key = ?'
  #|   ).bind(key).first()
  #|   return result?.value ?? null
  #| }

///|
/// Upsert sync state (direct D1 call)
extern "js" fn ffi_analysis_upsert_state(
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
/// Fetch entries that need analysis (direct D1 SQL)
extern "js" fn ffi_fetch_candidates(
  db : @core.Any,
  entry_ids : Array[String],
  force : Bool,
  limit : Int
) -> @js.Promise[@core.Any] =
  #| async (db, entryIds, force, limit) => {
  #|   const scopedIds = entryIds.filter(id => Boolean(id?.trim()))
  #|   let sql, params
  #|
  #|   if (scopedIds.length > 0) {
  #|     const placeholders = scopedIds.map(() => '?').join(',')
  #|     if (force) {
  #|       sql = `
  #|         SELECT e.id, e.title, e.markdown, e.start_time as startTime,
  #|                e.end_time as endTime, e.summary_hash as summaryHash
  #|         FROM lifelog_entries e
  #|         WHERE e.id IN (${placeholders})
  #|         ORDER BY e.start_time DESC
  #|         LIMIT ?
  #|       `
  #|       params = [...scopedIds, scopedIds.length]
  #|     } else {
  #|       sql = `
  #|         SELECT e.id, e.title, e.markdown, e.start_time as startTime,
  #|                e.end_time as endTime, e.summary_hash as summaryHash
  #|         FROM lifelog_entries e
  #|         LEFT JOIN lifelog_analyses a ON a.entry_id = e.id AND a.version = 'v1'
  #|         WHERE e.id IN (${placeholders})
  #|           AND (a.id IS NULL OR a.payload_hash != e.summary_hash)
  #|         ORDER BY e.start_time DESC
  #|         LIMIT ?
  #|       `
  #|       params = [...scopedIds, scopedIds.length]
  #|     }
  #|   } else {
  #|     sql = `
  #|       SELECT e.id, e.title, e.markdown, e.start_time as startTime,
  #|              e.end_time as endTime, e.summary_hash as summaryHash
  #|       FROM lifelog_entries e
  #|       LEFT JOIN lifelog_analyses a ON a.entry_id = e.id AND a.version = 'v1'
  #|       WHERE a.id IS NULL OR a.payload_hash != e.summary_hash
  #|       ORDER BY e.start_time DESC
  #|       LIMIT ?
  #|     `
  #|     params = [limit]
  #|   }
  #|
  #|   const result = await db.prepare(sql).bind(...params).all()
  #|   return result.results || []
  #| }

///|
/// Fetch segments for an entry (direct D1 SQL)
extern "js" fn ffi_fetch_segments(
  db : @core.Any,
  entry_id : String
) -> @js.Promise[@core.Any] =
  #| async (db, entryId) => {
  #|   const result = await db.prepare(`
  #|     SELECT content, start_time as startTime, end_time as endTime,
  #|            speaker_name as speakerName, node_type as nodeType
  #|     FROM lifelog_segments
  #|     WHERE entry_id = ?
  #|     LIMIT 120
  #|   `).bind(entryId).all()
  #|   return result.results || []
  #| }

///|
/// Run Workers AI model
extern "js" fn ffi_run_ai(
  env : @core.Any,
  model : String,
  input : String,
  schema : @core.Any
) -> @js.Promise[@core.Any] =
  #| async (env, model, input, schema) => {
  #|   if (!env.AI) return null
  #|   return await env.AI.run(model, {
  #|     input,
  #|     response_format: {
  #|       type: 'json_schema',
  #|       json_schema: {
  #|         name: 'lifelog_analysis',
  #|         schema
  #|       }
  #|     }
  #|   })
  #| }

///|
/// Call Gemini API
extern "js" fn ffi_call_gemini(
  api_key : String,
  prompt : String
) -> @js.Promise[@core.Any] =
  #| async (apiKey, prompt) => {
  #|   const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`
  #|   const response = await fetch(url, {
  #|     method: 'POST',
  #|     headers: { 'Content-Type': 'application/json' },
  #|     body: JSON.stringify({
  #|       contents: [{ parts: [{ text: prompt }] }],
  #|       generationConfig: {
  #|         responseMimeType: 'application/json',
  #|         temperature: 0.4,
  #|         maxOutputTokens: 4096
  #|       }
  #|     })
  #|   })
  #|   if (!response.ok) return null
  #|   const result = await response.json()
  #|   return result?.candidates?.[0]?.content?.parts?.[0]?.text ?? null
  #| }

///|
/// Insert or update analysis (direct D1 SQL)
extern "js" fn ffi_upsert_analysis(
  db : @core.Any,
  entry_id : String,
  model : String,
  version : String,
  payload_hash : String?,
  insights_json : String
) -> @js.Promise[Unit] =
  #| async (db, entryId, model, version, payloadHash, insightsJson) => {
  #|   const now = new Date().toISOString()
  #|
  #|   // Upsert analysis
  #|   await db.prepare(`
  #|     INSERT INTO lifelog_analyses (entry_id, model, version, payload_hash, insights_json, created_at)
  #|     VALUES (?, ?, ?, ?, ?, ?)
  #|     ON CONFLICT(entry_id, version) DO UPDATE SET
  #|       model = excluded.model,
  #|       payload_hash = excluded.payload_hash,
  #|       insights_json = excluded.insights_json,
  #|       created_at = excluded.created_at
  #|   `).bind(entryId, model, version, payloadHash ?? null, insightsJson, now).run()
  #|
  #|   // Update entry's last_analyzed_at
  #|   await db.prepare(`
  #|     UPDATE lifelog_entries SET last_analyzed_at = ? WHERE id = ?
  #|   `).bind(now, entryId).run()
  #| }

///|
/// Log analysis event (direct D1 SQL)
extern "js" fn ffi_log_analysis_event(
  db : @core.Any,
  entry_id : String,
  status : String,
  details : String
) -> @js.Promise[Unit] =
  #| async (db, entryId, status, details) => {
  #|   const now = new Date().toISOString()
  #|   await db.prepare(`
  #|     INSERT INTO analysis_logs (entry_id, status, details, created_at)
  #|     VALUES (?, ?, ?, ?)
  #|   `).bind(entryId, status, details, now).run()
  #| }

///|
/// Get environment variable
extern "js" fn ffi_get_env_var(env : @core.Any, key : String) -> String? =
  #| (env, key) => env[key] ?? null

///|
/// Check if Workers AI is available
extern "js" fn ffi_has_ai(env : @core.Any) -> Bool =
  #| (env) => Boolean(env.AI)

///|
/// Stringify JSON
extern "js" fn ffi_stringify(value : @core.Any) -> String =
  #| (value) => JSON.stringify(value)

///|
/// Parse JSON
extern "js" fn ffi_parse_json(text : String) -> @core.Any =
  #| (text) => {
  #|   try {
  #|     return JSON.parse(text)
  #|   } catch {
  #|     return null
  #|   }
  #| }

///|
/// Sleep for milliseconds
extern "js" fn ffi_sleep(ms : Int) -> @js.Promise[Unit] =
  #| (ms) => new Promise(resolve => setTimeout(resolve, ms))

///|
/// Log info
extern "js" fn ffi_info(message : String) -> Unit =
  #| (message) => console.info(message)

///|
/// Log error
extern "js" fn ffi_error(message : String) -> Unit =
  #| (message) => console.error(message)

///|
/// Log warning
extern "js" fn ffi_warning(message : String) -> Unit =
  #| (message) => console.warn(message)

///|
/// Get current timestamp
extern "js" fn ffi_now() -> String =
  #| () => new Date().toISOString()

// ============================================================================
// JSON Schema Definition
// ============================================================================

///|
/// Build JSON schema for analysis response
fn build_json_schema() -> @core.Any {
  @core.from_entries(
    [
      ("type", @core.any("object")),
      (
        "properties",
        @core.from_entries(
          [
            ("summary", @core.from_entries([("type", @core.any("string"))])),
            ("mood", @core.from_entries([("type", @core.any("string"))])),
            (
              "tags",
              @core.from_entries(
                [
                  ("type", @core.any("array")),
                  ("items", @core.from_entries([("type", @core.any("string"))])),
                ],
              ),
            ),
            (
              "time_blocks",
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
                                "startTime",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                              (
                                "endTime",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                              (
                                "label",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                              (
                                "details",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                            ],
                          ),
                        ),
                        (
                          "required",
                          {
                            let arr : Array[String] = ["label"]
                            @core.any(arr)
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            (
              "action_items",
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
                                "title",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                              (
                                "suggested_integration",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                              (
                                "due",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                            ],
                          ),
                        ),
                        (
                          "required",
                          {
                            let arr : Array[String] = ["title"]
                            @core.any(arr)
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            (
              "suggestions",
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
                                "target",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                              (
                                "rationale",
                                @core.from_entries([("type", @core.any("string"))]),
                              ),
                            ],
                          ),
                        ),
                        (
                          "required",
                          {
                            let arr : Array[String] = ["target", "rationale"]
                            @core.any(arr)
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      (
        "required",
        {
          let arr : Array[String] = [
            "summary", "mood", "tags", "time_blocks", "action_items", "suggestions",
          ]
          @core.any(arr)
        },
      ),
    ],
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

///|
/// Build analysis prompt
fn build_analysis_prompt(payload : String) -> String {
  let schema = build_json_schema()
  let schema_text = ffi_stringify(schema)
  analysis_system_prompt +
  "\nReturn ONLY valid JSON that matches the provided schema. Do not include commentary or code fences.\n\nSchema:\n" +
  schema_text +
  "\n\nAnalyze the following lifelog JSON and respond strictly with the requested schema:\n" +
  payload
}

///|
/// Build repair prompt for malformed JSON
fn build_repair_prompt(schema : @core.Any, attempt : String) -> String {
  "You fix malformed JSON by returning a corrected JSON document matching the provided schema. Return JSON only without commentary.\nSchema:\n" +
  ffi_stringify(schema) +
  "\n\nAttempt:\n" +
  attempt
}

///|
/// Extract response payload from AI response
fn extract_response_payload(result : @core.Any) -> String {
  if @core.is_nullish(result) {
    return "{}"
  }

  // Check if it's a string
  let type_of = @core.typeof_(result)
  if type_of == "string" {
    return result.cast()
  }

  // Check for response property
  let response = result["response"]
  if not(@core.is_nullish(response)) {
    let resp_type = @core.typeof_(response)
    if resp_type == "string" {
      return response.cast()
    }
  }

  // Check for output_text array
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

  // Check for output array with content
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

  "{}"
}

///|
/// Try to parse analysis JSON with repair logic
fn try_parse_analysis_json(raw : String) -> @core.Any {
  // First try direct parse
  let parsed = ffi_parse_json(raw)
  if not(@core.is_nullish(parsed)) {
    return parsed
  }

  // Try to extract JSON from text
  let trimmed = raw
  let mut start = -1
  let mut end = -1
  let chars = trimmed.to_array()
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '{' && start == -1 {
      start = i
    }
    if chars[i] == '}' {
      end = i
    }
  }

  if start == -1 || end <= start {
    return @core.null()
  }

  // Extract JSON substring
  let mut json_str = ""
  for i = start; i <= end; i = i + 1 {
    json_str = json_str + chars[i].to_string()
  }

  ffi_parse_json(json_str)
}

///|
/// Parse candidates from database result
fn parse_candidates(json : @core.Any) -> Array[EntryCandidate] {
  let result : Array[EntryCandidate] = []
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
    let summary_hash : String? = @core.identity_option(item["summaryHash"])
    result.push({ id, title, markdown, start_time, end_time, summary_hash })
  }
  result
}

///|
/// Parse segments from database result
fn parse_segments(json : @core.Any) -> Array[SegmentData] {
  let result : Array[SegmentData] = []
  if @core.is_nullish(json) {
    return result
  }
  let arr = @core.array_from(json)
  for item in arr {
    let content : String? = @core.identity_option(item["content"])
    let start_time : String? = @core.identity_option(item["startTime"])
    let end_time : String? = @core.identity_option(item["endTime"])
    let speaker_name : String? = @core.identity_option(item["speakerName"])
    let node_type : String? = @core.identity_option(item["nodeType"])
    result.push({ content, start_time, end_time, speaker_name, node_type })
  }
  result
}

///|
/// Build prompt payload from entry and segments
fn build_prompt_payload(
  entry : EntryCandidate,
  segments : Array[SegmentData]
) -> String {
  let meta = @core.from_entries(
    [
      ("id", @core.any(entry.id)),
      ("title", @core.any(entry.title)),
      ("startTime", @core.nullable(entry.start_time)),
      ("endTime", @core.nullable(entry.end_time)),
    ],
  )

  let segments_json : Array[@core.Any] = []
  for seg in segments {
    let seg_obj = @core.from_entries(
      [
        ("content", @core.nullable(seg.content)),
        ("startTime", @core.nullable(seg.start_time)),
        ("endTime", @core.nullable(seg.end_time)),
        ("speakerName", @core.nullable(seg.speaker_name)),
        ("nodeType", @core.nullable(seg.node_type)),
      ],
    )
    segments_json.push(seg_obj)
  }

  let payload = @core.from_entries(
    [
      ("meta", meta),
      ("markdown", @core.nullable(entry.markdown)),
      ("segments", @core.any(segments_json)),
    ],
  )

  ffi_stringify(payload)
}

// ============================================================================
// Public API
// ============================================================================

///|
/// Analyze fresh entries that haven't been processed yet
/// Uses Workers AI with Gemini fallback on rate limits
pub async fn analyze_fresh_entries(
  db : @core.Any,
  env : @core.Any,
  opts : AnalyzeOptions
) -> Array[String] raise {
  let analyzed_ids : Array[String] = []

  // Check if Workers AI is available
  if not(ffi_has_ai(env)) {
    ffi_warning("Workers AI binding is not configured")
    return analyzed_ids
  }

  // Check if Workers AI is disabled
  match ffi_get_env_var(env, "DISABLE_WORKERS_AI") {
    Some("1") => {
      ffi_info("Workers AI disabled via DISABLE_WORKERS_AI flag; skipping analysis.")
      return analyzed_ids
    }
    _ => ()
  }

  // Fetch candidates
  let candidates_json = ffi_fetch_candidates(
    db,
    opts.entry_ids,
    opts.force,
    opts.limit,
  ).wait()
  let candidates = parse_candidates(candidates_json)

  if candidates.length() == 0 {
    return analyzed_ids
  }

  let schema = build_json_schema()
  let gemini_api_key = ffi_get_env_var(env, "GEMINI_API_KEY")

  for i = 0; i < candidates.length(); i = i + 1 {
    let entry = candidates[i]

    // Add delay between requests (except first)
    if i > 0 {
      ffi_sleep(5000).wait()
    }

    // Fetch segments
    let segments_json = ffi_fetch_segments(db, entry.id).wait()
    let segments = parse_segments(segments_json)

    // Build prompt
    let prompt_payload = build_prompt_payload(entry, segments)
    let prompt = build_analysis_prompt(prompt_payload)

    let mut parsed : @core.Any = @core.null()
    let mut model_used = analysis_ai_model

    // Try Workers AI first
    let response = ffi_run_ai(env, analysis_ai_model, prompt, schema).wait()
    let serialized = extract_response_payload(response)
    parsed = try_parse_analysis_json(serialized)

    // If parsing failed, try repair
    if @core.is_nullish(parsed) {
      let repair_prompt = build_repair_prompt(schema, serialized)
      let repair_response = ffi_run_ai(env, analysis_ai_model, repair_prompt, schema).wait()
      let repair_serialized = extract_response_payload(repair_response)
      parsed = try_parse_analysis_json(repair_serialized)
    }

    // Fallback to Gemini if still failed
    if @core.is_nullish(parsed) {
      match gemini_api_key {
        Some(key) => {
          let gemini_prompt = build_analysis_prompt(prompt_payload)
          let gemini_result = ffi_call_gemini(key, gemini_prompt).wait()
          if not(@core.is_nullish(gemini_result)) {
            let gemini_text : String = gemini_result.cast()
            parsed = try_parse_analysis_json(gemini_text)
            if not(@core.is_nullish(parsed)) {
              model_used = analysis_gemini_model
            }
          }
        }
        None => ()
      }
    }

    // Store analysis result
    if not(@core.is_nullish(parsed)) {
      let insights_json = ffi_stringify(parsed)
      ffi_upsert_analysis(
        db,
        entry.id,
        model_used,
        analysis_version,
        entry.summary_hash,
        insights_json,
      ).wait()
      ffi_log_analysis_event(
        db,
        entry.id,
        "success",
        "Analysis stored (" + model_used + ")",
      ).wait()
      analyzed_ids.push(entry.id)
    } else {
      ffi_log_analysis_event(
        db,
        entry.id,
        "error",
        "Failed to parse analysis response",
      ).wait()
      ffi_error("Analysis failed for entry: " + entry.id)
    }
  }

  // Update last analyzed timestamp
  if analyzed_ids.length() > 0 {
    let now = ffi_now()
    ffi_analysis_upsert_state(db, last_analyzed_key, now).wait()
  }

  analyzed_ids
}

///|
/// Get last analyzed timestamp
pub async fn get_last_analyzed_at(db : @core.Any) -> String? {
  ffi_analysis_get_state(db, last_analyzed_key).wait()
}
