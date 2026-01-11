///|
/// API client module for fetching data from the server
/// Uses mizchi/js/web/http for HTTP requests

///|
/// Timeline entry type (matches server response)
pub struct TimelineEntry {
  id : String
  title : String
  start_time : String
  end_time : String
  date_label : String?
  duration_minutes : Int?
  segments : Array[TimelineSegment]
  analysis : Analysis?
}

///|
/// Timeline segment type
pub struct TimelineSegment {
  id : String
  content : String?
  start_time : String?
  end_time : String?
  node_type : String?
  speaker_name : String?
}

///|
/// Analysis type
pub struct Analysis {
  summary : String?
  mood : String?
  tags : Array[String]
  action_items : Array[ActionItem]
  suggestions : Array[Suggestion]
}

///|
/// Action item type
pub struct ActionItem {
  title : String
  suggested_integration : String?
}

///|
/// Suggestion type
pub struct Suggestion {
  target : String
  rationale : String
}

///|
/// Day summary type
pub struct DaySummary {
  date : String
  tweets : Array[Tweet]
}

///|
/// Tweet type
pub struct Tweet {
  text : String
  time : String?
}

///|
/// Timeline response type
pub struct TimelineResponse {
  timeline : Array[TimelineEntry]
  last_synced_at : String?
  last_analyzed_at : String?
}

///|
/// Parse JSON to TimelineEntry array
fn parse_timeline_entries(json : @core.Any) -> Array[TimelineEntry] {
  let entries : Array[TimelineEntry] = []
  let arr = @core.array_from(json)
  for item in arr {
    let entry = parse_timeline_entry(item)
    entries.push(entry)
  }
  entries
}

///|
/// Parse single timeline entry
fn parse_timeline_entry(json : @core.Any) -> TimelineEntry {
  let id : String = json["id"].cast()
  let title : String = json["title"].cast()
  let start_time : String = json["start_time"].cast()
  let end_time : String = json["end_time"].cast()
  let date_label : String? = @core.identity_option(json["date_label"])
  let duration_minutes : Int? = @core.identity_option(json["duration_minutes"])

  // Parse segments
  let segments : Array[TimelineSegment] = []
  let segments_json = json["segments"]
  if not(@core.is_nullish(segments_json)) {
    let seg_arr = @core.array_from(segments_json)
    for seg in seg_arr {
      segments.push(parse_segment(seg))
    }
  }

  // Parse analysis
  let analysis : Analysis? = if @core.is_nullish(json["analysis"]) {
    None
  } else {
    Some(parse_analysis(json["analysis"]))
  }

  { id, title, start_time, end_time, date_label, duration_minutes, segments, analysis }
}

///|
/// Parse segment
fn parse_segment(json : @core.Any) -> TimelineSegment {
  let id : String = json["id"].cast()
  let content : String? = @core.identity_option(json["content"])
  let start_time : String? = @core.identity_option(json["start_time"])
  let end_time : String? = @core.identity_option(json["end_time"])
  let node_type : String? = @core.identity_option(json["node_type"])
  let speaker_name : String? = @core.identity_option(json["speaker_name"])
  { id, content, start_time, end_time, node_type, speaker_name }
}

///|
/// Parse analysis
fn parse_analysis(json : @core.Any) -> Analysis {
  let summary : String? = @core.identity_option(json["summary"])
  let mood : String? = @core.identity_option(json["mood"])

  let tags : Array[String] = []
  let tags_json = json["tags"]
  if not(@core.is_nullish(tags_json)) {
    let tag_arr = @core.array_from(tags_json)
    for tag in tag_arr {
      tags.push(tag.cast())
    }
  }

  let action_items : Array[ActionItem] = []
  let ai_json = json["action_items"]
  if not(@core.is_nullish(ai_json)) {
    let ai_arr = @core.array_from(ai_json)
    for ai in ai_arr {
      let title : String = ai["title"].cast()
      let suggested_integration : String? = @core.identity_option(ai["suggested_integration"])
      action_items.push({ title, suggested_integration })
    }
  }

  let suggestions : Array[Suggestion] = []
  let sugg_json = json["suggestions"]
  if not(@core.is_nullish(sugg_json)) {
    let sugg_arr = @core.array_from(sugg_json)
    for sugg in sugg_arr {
      let target : String = sugg["target"].cast()
      let rationale : String = sugg["rationale"].cast()
      suggestions.push({ target, rationale })
    }
  }

  { summary, mood, tags, action_items, suggestions }
}

///|
/// Parse day summary
fn parse_day_summary(json : @core.Any) -> DaySummary {
  let date : String = json["date"].cast()
  let tweets : Array[Tweet] = []
  let tweets_json = json["tweets"]
  if not(@core.is_nullish(tweets_json)) {
    let tw_arr = @core.array_from(tweets_json)
    for tw in tw_arr {
      let text : String = tw["text"].cast()
      let time : String? = @core.identity_option(tw["time"])
      tweets.push({ text, time })
    }
  }
  { date, tweets }
}

///|
/// Fetch timeline data
pub async fn fetch_timeline(
  days : Int,
  offset : Int,
  detail : Bool
) -> TimelineResponse raise {
  let url = "/api/lifelogs?days=" +
    days.to_string() +
    "&offset=" +
    offset.to_string()
  let url = if detail { url + "&detail=1" } else { url }

  let response = @http.fetch(url, method_="GET")
  if not(response.ok) {
    fail("Failed to fetch timeline: " + response.statusText)
  }

  let json = response.json()
  let timeline = parse_timeline_entries(json["timeline"])
  let last_synced_at : String? = @core.identity_option(json["lastSyncedAt"])
  let last_analyzed_at : String? = @core.identity_option(
    json["lastAnalyzedAt"],
  )

  { timeline, last_synced_at, last_analyzed_at }
}

///|
/// Fetch day summary
pub async fn fetch_day_summary(date : String) -> DaySummary raise {
  let url = "/api/day-summary?date=" + date
  let response = @http.fetch(url, method_="GET")
  if not(response.ok) {
    fail("Failed to fetch day summary: " + response.statusText)
  }

  let json = response.json()
  parse_day_summary(json)
}

///|
/// Fetch timeline entry detail
pub async fn fetch_entry_detail(entry_id : String) -> TimelineEntry raise {
  let url = "/api/lifelogs/" + entry_id
  let response = @http.fetch(url, method_="GET")
  if not(response.ok) {
    fail("Failed to fetch entry detail: " + response.statusText)
  }

  let json = response.json()
  parse_timeline_entry(json)
}

///|
/// Trigger sync
pub async fn trigger_sync() -> Unit raise {
  let response = @http.fetch("/api/sync", method_="POST")
  if not(response.ok) {
    fail("Failed to trigger sync: " + response.statusText)
  }
}

///|
/// Trigger analysis for an entry
pub async fn trigger_analysis(entry_id : String) -> Unit raise {
  let url = "/api/analyze/" + entry_id
  let response = @http.fetch(url, method_="POST")
  if not(response.ok) {
    fail("Failed to trigger analysis: " + response.statusText)
  }
}

///|
/// Regenerate day summary
pub async fn regenerate_day_summary(
  date : String,
  provider : String
) -> DaySummary raise {
  let url = "/api/day-summary/regenerate?date=" + date + "&provider=" + provider
  let response = @http.fetch(url, method_="POST")
  if not(response.ok) {
    fail("Failed to regenerate day summary: " + response.statusText)
  }

  let json = response.json()
  parse_day_summary(json)
}
