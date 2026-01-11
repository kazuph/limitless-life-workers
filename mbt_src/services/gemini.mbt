///|
/// Gemini Insights API client module
/// Calls Gemini 2.0 Flash API for insights analysis (distinct from analysis.mbt)

///|
/// Gemini API configuration for insights
let insights_gemini_model : String = "gemini-2.0-flash"

///|
let insights_gemini_api_url : String = "https://generativelanguage.googleapis.com/v1beta/models"

///|
/// Priority level for items
pub enum Priority {
  High
  Medium
  Low
}

///|
/// Convert priority to string
pub fn Priority::to_string(self : Priority) -> String {
  match self {
    High => "high"
    Medium => "medium"
    Low => "low"
  }
}

///|
/// Parse priority from string
pub fn Priority::from_string(s : String) -> Priority {
  match s {
    "high" => High
    "medium" => Medium
    _ => Low
  }
}

///|
/// Urgency level for shopping items
pub enum Urgency {
  Immediate
  Soon
  Later
}

///|
/// Convert urgency to string
pub fn Urgency::to_string(self : Urgency) -> String {
  match self {
    Immediate => "immediate"
    Soon => "soon"
    Later => "later"
  }
}

///|
/// Parse urgency from string
pub fn Urgency::from_string(s : String) -> Urgency {
  match s {
    "immediate" => Immediate
    "soon" => Soon
    _ => Later
  }
}

///|
/// Suggested schedule item
pub struct SuggestedSchedule {
  title : String
  description : String
  suggested_date : String?
  priority : Priority
}

///|
/// TODO item
pub struct TodoItem {
  title : String
  description : String
  due_date : String?
  priority : Priority
}

///|
/// Insight item
pub struct Insight {
  category : String
  content : String
  source_context : String?
}

///|
/// Shopping suggestion item
pub struct ShoppingSuggestion {
  item : String
  reason : String
  urgency : Urgency
}

///|
/// Gemini insights response
pub struct GeminiInsights {
  suggested_schedules : Array[SuggestedSchedule]
  todo_items : Array[TodoItem]
  insights : Array[Insight]
  shopping_suggestions : Array[ShoppingSuggestion]
  summary : String
}

///|
/// Options for Gemini insights analysis
pub struct GeminiInsightsOptions {
  hours_back : Int
  from : String?
  to : String?
  max_entries : Int
  mode : String // "full" or "hourly_bullets"
}

///|
/// Default options
pub fn GeminiInsightsOptions::default() -> GeminiInsightsOptions {
  {
    hours_back: 1,
    from: None,
    to: None,
    max_entries: 50,
    mode: "full",
  }
}

///|
/// System prompt for insights analysis
let insights_system_prompt : String =
  #|あなたは優秀なパーソナルアシスタントです。与えられたライフログ（会話データ）を分析し、以下の4つの観点で有用な情報を抽出してください。
  #|
  #|分析対象：
  #|1. **追加した方が良さそうな予定（suggested_schedules）**: 会話中で言及された予定、約束、イベントなど
  #|2. **TODOにした方が良さそうなタスク（todo_items）**: やるべきこと、宿題、調べ物、連絡事項など
  #|3. **インサイト・学び（insights）**: 会話から得られた気づき、新しい知識、重要な発見
  #|4. **買い物提案（shopping_suggestions）**: 必要そうなもの、欲しいと言っていたもの、消耗品の補充など
  #|
  #|重要な注意事項：
  #|- 日本語で出力してください
  #|- 具体的で実行可能な形で提案してください
  #|- 会話の文脈を考慮して、本当に重要なものだけを抽出してください
  #|- 各項目は最大5個までにしてください
  #|- 該当するものがない場合は空配列で返してください

///|
/// System prompt for hourly bullets mode
let insights_hourly_bullets_prompt : String =
  #|あなたは簡潔なサマリー専任のアシスタントです。以下の時間範囲の出来事を日本語で3-6行の箇条書きにまとめてください。
  #|
  #|出力要件:
  #|- summary フィールドのみに箇条書きで書く（例: "- ミーティングでAの仕様確認"）
  #|- 他の配列フィールド（suggested_schedules, todo_items, insights, shopping_suggestions）は内容がなければ空配列のまま返す
  #|- JSONのみを返し、コメントやコードフェンスは不要
  #|- 重要度が低い雑談は入れず、行数は最小限に抑える

///|
/// JSON Schema for response validation
let insights_json_schema : String =
  #|{
  #|  "type": "object",
  #|  "properties": {
  #|    "suggested_schedules": {
  #|      "type": "array",
  #|      "items": {
  #|        "type": "object",
  #|        "properties": {
  #|          "title": { "type": "string" },
  #|          "description": { "type": "string" },
  #|          "suggested_date": { "type": "string" },
  #|          "priority": { "type": "string", "enum": ["high", "medium", "low"] }
  #|        },
  #|        "required": ["title", "description", "priority"]
  #|      }
  #|    },
  #|    "todo_items": {
  #|      "type": "array",
  #|      "items": {
  #|        "type": "object",
  #|        "properties": {
  #|          "title": { "type": "string" },
  #|          "description": { "type": "string" },
  #|          "due_date": { "type": "string" },
  #|          "priority": { "type": "string", "enum": ["high", "medium", "low"] }
  #|        },
  #|        "required": ["title", "description", "priority"]
  #|      }
  #|    },
  #|    "insights": {
  #|      "type": "array",
  #|      "items": {
  #|        "type": "object",
  #|        "properties": {
  #|          "category": { "type": "string" },
  #|          "content": { "type": "string" },
  #|          "source_context": { "type": "string" }
  #|        },
  #|        "required": ["category", "content"]
  #|      }
  #|    },
  #|    "shopping_suggestions": {
  #|      "type": "array",
  #|      "items": {
  #|        "type": "object",
  #|        "properties": {
  #|          "item": { "type": "string" },
  #|          "reason": { "type": "string" },
  #|          "urgency": { "type": "string", "enum": ["immediate", "soon", "later"] }
  #|        },
  #|        "required": ["item", "reason", "urgency"]
  #|      }
  #|    },
  #|    "summary": { "type": "string" }
  #|  },
  #|  "required": ["suggested_schedules", "todo_items", "insights", "shopping_suggestions", "summary"]
  #|}

///|
/// Entry data for insights analysis
pub struct InsightsEntry {
  title : String?
  start_time : String?
  end_time : String?
  content : String
}

///|
/// Parse suggested schedule from JSON
fn parse_suggested_schedule(json : @core.Any) -> SuggestedSchedule {
  let title : String = if @core.is_nullish(json["title"]) {
    ""
  } else {
    json["title"].cast()
  }
  let description : String = if @core.is_nullish(json["description"]) {
    ""
  } else {
    json["description"].cast()
  }
  let suggested_date : String? = @core.identity_option(json["suggested_date"])
  let priority_str : String = if @core.is_nullish(json["priority"]) {
    "low"
  } else {
    json["priority"].cast()
  }
  { title, description, suggested_date, priority: Priority::from_string(priority_str) }
}

///|
/// Parse todo item from JSON
fn parse_todo_item(json : @core.Any) -> TodoItem {
  let title : String = if @core.is_nullish(json["title"]) {
    ""
  } else {
    json["title"].cast()
  }
  let description : String = if @core.is_nullish(json["description"]) {
    ""
  } else {
    json["description"].cast()
  }
  let due_date : String? = @core.identity_option(json["due_date"])
  let priority_str : String = if @core.is_nullish(json["priority"]) {
    "low"
  } else {
    json["priority"].cast()
  }
  { title, description, due_date, priority: Priority::from_string(priority_str) }
}

///|
/// Parse insight from JSON
fn parse_insight(json : @core.Any) -> Insight {
  let category : String = if @core.is_nullish(json["category"]) {
    ""
  } else {
    json["category"].cast()
  }
  let content : String = if @core.is_nullish(json["content"]) {
    ""
  } else {
    json["content"].cast()
  }
  let source_context : String? = @core.identity_option(json["source_context"])
  { category, content, source_context }
}

///|
/// Parse shopping suggestion from JSON
fn parse_shopping_suggestion(json : @core.Any) -> ShoppingSuggestion {
  let item : String = if @core.is_nullish(json["item"]) {
    ""
  } else {
    json["item"].cast()
  }
  let reason : String = if @core.is_nullish(json["reason"]) {
    ""
  } else {
    json["reason"].cast()
  }
  let urgency_str : String = if @core.is_nullish(json["urgency"]) {
    "later"
  } else {
    json["urgency"].cast()
  }
  { item, reason, urgency: Urgency::from_string(urgency_str) }
}

///|
/// Parse Gemini insights response
fn parse_gemini_insights(json : @core.Any) -> GeminiInsights {
  // Parse suggested_schedules
  let suggested_schedules : Array[SuggestedSchedule] = []
  let schedules_json = json["suggested_schedules"]
  if not(@core.is_nullish(schedules_json)) {
    let arr = @core.array_from(schedules_json)
    for item in arr {
      suggested_schedules.push(parse_suggested_schedule(item))
    }
  }

  // Parse todo_items
  let todo_items : Array[TodoItem] = []
  let todos_json = json["todo_items"]
  if not(@core.is_nullish(todos_json)) {
    let arr = @core.array_from(todos_json)
    for item in arr {
      todo_items.push(parse_todo_item(item))
    }
  }

  // Parse insights
  let insights : Array[Insight] = []
  let insights_json = json["insights"]
  if not(@core.is_nullish(insights_json)) {
    let arr = @core.array_from(insights_json)
    for item in arr {
      insights.push(parse_insight(item))
    }
  }

  // Parse shopping_suggestions
  let shopping_suggestions : Array[ShoppingSuggestion] = []
  let shopping_json = json["shopping_suggestions"]
  if not(@core.is_nullish(shopping_json)) {
    let arr = @core.array_from(shopping_json)
    for item in arr {
      shopping_suggestions.push(parse_shopping_suggestion(item))
    }
  }

  // Parse summary
  let summary : String = if @core.is_nullish(json["summary"]) {
    ""
  } else {
    json["summary"].cast()
  }

  { suggested_schedules, todo_items, insights, shopping_suggestions, summary }
}

///|
/// Build prompt for Gemini API
fn build_insights_prompt(
  entries : Array[InsightsEntry],
  options : GeminiInsightsOptions,
  range_from : String,
  range_to : String
) -> String {
  // Build entries payload
  let mut entries_json = "["
  for i, entry in entries {
    if i > 0 {
      entries_json = entries_json + ","
    }
    entries_json = entries_json + "{"
    entries_json = entries_json +
      "\"title\":" +
      (match entry.title {
        Some(t) => "\"" + t + "\""
        None => "null"
      })
    entries_json = entries_json +
      ",\"startTime\":" +
      (match entry.start_time {
        Some(t) => "\"" + t + "\""
        None => "null"
      })
    entries_json = entries_json +
      ",\"endTime\":" +
      (match entry.end_time {
        Some(t) => "\"" + t + "\""
        None => "null"
      })
    entries_json = entries_json + ",\"content\":\"" + escape_insights_json(entry.content) +
      "\""
    entries_json = entries_json + "}"
  }
  entries_json = entries_json + "]"

  let payload = "{\"analysis_period\":{\"from\":\"" +
    range_from +
    "\",\"to\":\"" +
    range_to +
    "\"},\"entries\":" +
    entries_json +
    "}"

  let base_prompt = if options.mode == "hourly_bullets" {
    insights_hourly_bullets_prompt
  } else {
    insights_system_prompt +
    "\n\n以下のライフログを分析して、JSON形式で結果を返してください。JSONのみを返してください（コメントやコードフェンスは不要）。"
  }

  base_prompt +
  "\n\nSchema:\n" +
  insights_json_schema +
  "\n\n分析対象期間: " +
  range_from +
  " 〜 " +
  range_to +
  "\nライフログデータ:\n" +
  payload
}

///|
/// Escape special characters for JSON
fn escape_insights_json(s : String) -> String {
  let mut result = ""
  for c in s {
    if c == '"' {
      result = result + "\\\""
    } else if c == '\\' {
      result = result + "\\\\"
    } else if c == '\n' {
      result = result + "\\n"
    } else if c == '\r' {
      result = result + "\\r"
    } else if c == '\t' {
      result = result + "\\t"
    } else {
      result = result + c.to_string()
    }
  }
  result
}

///|
/// FFI for JSON.parse
extern "js" fn ffi_json_parse(text : String) -> @core.Any =
  #| (text) => JSON.parse(text)

///|
/// Analyze entries with Gemini API for insights
pub async fn analyze_insights_with_gemini(
  api_key : String,
  entries : Array[InsightsEntry],
  options : GeminiInsightsOptions,
  range_from : String,
  range_to : String
) -> GeminiInsights? raise {
  if api_key == "" {
    @console.warn(@core.any("Missing GEMINI_API_KEY; skipping Gemini insights analysis."))
    return None
  }

  if entries.length() == 0 {
    @console.info(@core.any("No recent entries found for Gemini insights analysis"))
    return None
  }

  let prompt = build_insights_prompt(entries, options, range_from, range_to)

  // Build request body
  let request_body = @core.new_object()

  // contents array
  let contents = @core.new_array()
  let content_obj = @core.new_object()
  let parts = @core.new_array()
  let part_obj = @core.new_object()
  part_obj._set("text", @core.any(prompt))
  parts._call("push", [@core.identity(part_obj)]) |> ignore
  content_obj._set("parts", parts)
  contents._call("push", [@core.identity(content_obj)]) |> ignore
  request_body._set("contents", contents)

  // generationConfig
  let gen_config = @core.new_object()
  gen_config._set("responseMimeType", @core.any("application/json"))
  gen_config._set("temperature", @core.any(0.7))
  gen_config._set("maxOutputTokens", @core.any(4096))
  request_body._set("generationConfig", gen_config)

  let url = insights_gemini_api_url + "/" + insights_gemini_model + ":generateContent?key=" + api_key

  let response = @http.fetch(
    url,
    method_="POST",
    headers={ "Content-Type": "application/json" },
    body=request_body,
  )

  if not(response.ok) {
    let error_text = response.text()
    @console.error(@core.any("Gemini API error: " + response.status.to_string() + " " + error_text))
    return None
  }

  let result = response.json()

  // Extract text from response
  let candidates = result["candidates"]
  if @core.is_nullish(candidates) {
    @console.error(@core.any("No candidates in Gemini response"))
    return None
  }

  let candidates_arr = @core.array_from(candidates)
  if candidates_arr.length() == 0 {
    @console.error(@core.any("Empty candidates array in Gemini response"))
    return None
  }

  let first_candidate = candidates_arr[0]
  let content = first_candidate["content"]
  if @core.is_nullish(content) {
    @console.error(@core.any("No content in first candidate"))
    return None
  }

  let response_parts = content["parts"]
  if @core.is_nullish(response_parts) {
    @console.error(@core.any("No parts in content"))
    return None
  }

  let parts_arr = @core.array_from(response_parts)
  if parts_arr.length() == 0 {
    @console.error(@core.any("Empty parts array"))
    return None
  }

  let text = parts_arr[0]["text"]
  if @core.is_nullish(text) {
    @console.error(@core.any("No text in first part"))
    return None
  }

  // Parse JSON response using FFI
  let text_str : String = text.cast()
  let insights_json = ffi_json_parse(text_str)
  Some(parse_gemini_insights(insights_json))
}

///|
/// Check if insights have content
pub fn GeminiInsights::has_content(self : GeminiInsights) -> Bool {
  (self.summary != "" && self.summary.length() > 0) ||
  self.suggested_schedules.length() > 0 ||
  self.todo_items.length() > 0 ||
  self.insights.length() > 0 ||
  self.shopping_suggestions.length() > 0
}

///|
/// Empty insights
pub fn GeminiInsights::empty() -> GeminiInsights {
  {
    suggested_schedules: [],
    todo_items: [],
    insights: [],
    shopping_suggestions: [],
    summary: "",
  }
}
