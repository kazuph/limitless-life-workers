///|
/// Slack API client module
/// Posts messages to Slack channels

///|
/// Slack API URL
let slack_api_url : String = "https://slack.com/api/chat.postMessage"

///|
/// Default channel
let default_channel : String = "#limitless-onsai-insight"

///|
/// Default bot username
let bot_username : String = "keroyon"

///|
/// Default bot icon URL
let bot_icon_url : String = "https://emoji.slack-edge.com/T030A5CV2/keroyon/c3aa47f65017d188.png"

///|
/// FFI for creating URLSearchParams
extern "js" fn ffi_new_url_search_params() -> @url.URLSearchParams =
  #| () => new URLSearchParams()

///|
/// URL encode a string
fn url_encode(s : String) -> String {
  let mut result = ""
  for c in s {
    if (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '-' ||
      c == '_' ||
      c == '.' ||
      c == '~' {
      result = result + c.to_string()
    } else if c == ' ' {
      result = result + "+"
    } else {
      // Simple percent encoding for common characters
      let code = c.to_int()
      result = result +
        "%" +
        to_hex((code / 16) % 16) +
        to_hex(code % 16)
    }
  }
  result
}

///|
fn to_hex(n : Int) -> String {
  match n {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "A"
    11 => "B"
    12 => "C"
    13 => "D"
    14 => "E"
    15 => "F"
    _ => "0"
  }
}

///|
/// Post a message to Slack
pub async fn post_to_slack(
  token : String,
  channel : String?,
  text : String
) -> Bool {
  if token == "" {
    @console.warn(@core.any("Missing SLACK_BOT_TOKEN; skipping Slack post."))
    return false
  }

  let ch = match channel {
    Some(c) => c
    None => default_channel
  }

  // Build form data using FFI
  let params = ffi_new_url_search_params()
  params.set("token", token)
  params.set("channel", ch)
  params.set("username", bot_username)
  params.set("icon_url", bot_icon_url)
  params.set("text", text)
  params.set("link_names", "true")

  let response = @http.fetch(
    slack_api_url,
    method_="POST",
    headers={ "Content-Type": "application/x-www-form-urlencoded" },
    body=@core.any(params.to_string()),
  )

  if not(response.ok) {
    @console.error(@core.any("Slack API error: " + response.status.to_string()))
    return false
  }

  let result = response.json()

  let ok = result["ok"]
  if @core.is_nullish(ok) || not(ok.cast()) {
    let error_msg = result["error"]
    let error_str : String = if @core.is_nullish(error_msg) {
      "unknown error"
    } else {
      error_msg.cast()
    }
    @console.error(@core.any("Slack post failed: " + error_str))
    return false
  }

  true
}

///|
/// Get priority emoji
fn get_priority_emoji(priority : Priority) -> String {
  match priority {
    High => "\u{1F534}" // Red circle
    Medium => "\u{1F7E1}" // Yellow circle
    Low => "\u{1F7E2}" // Green circle
  }
}

///|
/// Get urgency emoji
fn get_urgency_emoji(urgency : Urgency) -> String {
  match urgency {
    Immediate => "\u{1F6A8}" // Rotating light
    Soon => "\u{23F0}" // Alarm clock
    Later => "\u{1F4CC}" // Pushpin
  }
}

///|
/// Format insights for Slack
pub fn format_insights_for_slack(insights : GeminiInsights) -> String {
  let sections : Array[String] = []

  // Summary
  if insights.summary != "" {
    sections.push("\u{1F4DD} *\u30b5\u30de\u30ea\u30fc*\n" + insights.summary)
  }

  // Suggested schedules
  if insights.suggested_schedules.length() > 0 {
    let mut schedules = ""
    for s in insights.suggested_schedules {
      let priority = get_priority_emoji(s.priority)
      let date = match s.suggested_date {
        Some(d) => " (" + d + ")"
        None => ""
      }
      schedules = schedules +
        priority +
        " *" +
        s.title +
        "*" +
        date +
        "\n   " +
        s.description +
        "\n"
    }
    sections.push(
      "\u{1F4C5} *\u8ffd\u52a0\u3057\u305f\u65b9\u304c\u826f\u3055\u305d\u3046\u306a\u4e88\u5b9a*\n" +
      schedules,
    )
  }

  // TODO items
  if insights.todo_items.length() > 0 {
    let mut todos = ""
    for t in insights.todo_items {
      let priority = get_priority_emoji(t.priority)
      let due = match t.due_date {
        Some(d) => " (\u671f\u9650: " + d + ")"
        None => ""
      }
      todos = todos +
        priority +
        " *" +
        t.title +
        "*" +
        due +
        "\n   " +
        t.description +
        "\n"
    }
    sections.push(
      "\u2705 *TODO\u306b\u3057\u305f\u65b9\u304c\u826f\u3055\u305d\u3046\u306a\u30bf\u30b9\u30af*\n" +
      todos,
    )
  }

  // Insights
  if insights.insights.length() > 0 {
    let mut insight_list = ""
    for i in insights.insights {
      let context = match i.source_context {
        Some(c) => " _\uff08" + c + "\uff09_"
        None => ""
      }
      insight_list = insight_list +
        "\u{1F4A1} *" +
        i.category +
        "*\n   " +
        i.content +
        context +
        "\n"
    }
    sections.push(
      "\u{1F9E0} *\u30a4\u30f3\u30b5\u30a4\u30c8\u30fb\u5b66\u3073*\n" +
      insight_list,
    )
  }

  // Shopping suggestions
  if insights.shopping_suggestions.length() > 0 {
    let mut shopping = ""
    for s in insights.shopping_suggestions {
      let urgency = get_urgency_emoji(s.urgency)
      shopping = shopping +
        urgency +
        " *" +
        s.item +
        "*\n   " +
        s.reason +
        "\n"
    }
    sections.push(
      "\u{1F6D2} *\u8cb7\u3044\u7269\u63d0\u6848*\n" + shopping,
    )
  }

  // Join sections with divider
  let mut result = ""
  for i, section in sections {
    if i > 0 {
      result = result + "\n\n---\n\n"
    }
    result = result + section
  }
  result
}

///|
/// Post insights to Slack
pub async fn post_insights_to_slack(
  token : String,
  channel : String?,
  insights : GeminiInsights,
  header_override : String?
) -> Bool {
  // Check if there's content to post
  if not(insights.has_content()) {
    @console.info(@core.any("No insights to post to Slack"))
    return false
  }

  let text = format_insights_for_slack(insights)
  let header = match header_override {
    Some(h) => h
    None => "@kazuph \u{1F399}\uFE0F *Limitless \u97f3\u58f0\u5206\u6790\u30ec\u30dd\u30fc\u30c8*\n_" +
      get_current_time_jst() +
      "_\n\n"
  }

  post_to_slack(token, channel, header + text)
}

///|
/// Post error to Slack
pub async fn post_error_to_slack(
  token : String,
  channel : String?,
  error_message : String,
  context : String?
) -> Bool {
  let timestamp = get_current_time_jst()

  let mut text = "\u{1F6A8} *Cron\u51e6\u7406\u30a8\u30e9\u30fc*\n_" + timestamp +
    "_\n\n"

  match context {
    Some(ctx) => text = text + "*\u51e6\u7406:* " + ctx + "\n"
    None => ()
  }

  text = text + "*\u30a8\u30e9\u30fc:* `" + error_message + "`"

  post_to_slack(token, channel, text)
}

///|
/// Post warning to Slack
pub async fn post_warning_to_slack(
  token : String,
  channel : String?,
  message : String,
  context : String?
) -> Bool {
  let timestamp = get_current_time_jst()
  let header = "\u26A0\uFE0F *\u540c\u671f\u89b3\u6e2c*\n_" + timestamp + "_\n\n"
  let body = match context {
    Some(ctx) => "*\u51e6\u7406:* " + ctx + "\n"
    None => ""
  }
  post_to_slack(token, channel, header + body + message)
}

///|
/// Get current time in JST format
extern "js" fn ffi_get_current_time_jst() -> String =
  #| () => new Date().toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' })

///|
fn get_current_time_jst() -> String {
  ffi_get_current_time_jst()
}
