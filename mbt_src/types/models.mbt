///|
/// MoonBit type definitions for Lifelog application
/// Based on src/db/schema.ts and API response types

// =============================================================================
// Database Entity Types (matching D1 schema)
// =============================================================================

///|
/// Lifelog entry representing a single recorded session
pub(all) struct LifelogEntry {
  id : String
  title : String?
  markdown : String?
  start_time : String?
  end_time : String?
  start_epoch_ms : Int?
  end_epoch_ms : Int?
  is_starred : Bool
  updated_at : String?
  ingested_at : String?
  timezone : String?
  summary_hash : String?
  last_analyzed_at : String?
}

///|
/// Create a new LifelogEntry with required fields
pub fn LifelogEntry::new(id : String) -> LifelogEntry {
  {
    id,
    title: None,
    markdown: None,
    start_time: None,
    end_time: None,
    start_epoch_ms: None,
    end_epoch_ms: None,
    is_starred: false,
    updated_at: None,
    ingested_at: None,
    timezone: None,
    summary_hash: None,
    last_analyzed_at: None,
  }
}

///|
/// Lifelog segment within an entry (e.g., transcript chunk, note)
pub(all) struct LifelogSegment {
  id : Int?
  entry_id : String
  node_id : String
  path : String?
  node_type : String?
  content : String?
  start_time : String?
  end_time : String?
  start_offset_ms : Int?
  end_offset_ms : Int?
  speaker_name : String?
  speaker_identifier : String?
}

///|
/// Create a new LifelogSegment with required fields
pub fn LifelogSegment::new(entry_id : String, node_id : String) -> LifelogSegment {
  {
    id: None,
    entry_id,
    node_id,
    path: None,
    node_type: None,
    content: None,
    start_time: None,
    end_time: None,
    start_offset_ms: None,
    end_offset_ms: None,
    speaker_name: None,
    speaker_identifier: None,
  }
}

///|
/// AI-generated analysis for an entry
pub(all) struct LifelogAnalysis {
  id : Int?
  entry_id : String
  model : String
  version : String
  payload_hash : String?
  insights_json : String
  created_at : String?
}

///|
/// Create a new LifelogAnalysis with required fields
pub fn LifelogAnalysis::new(
  entry_id : String,
  model : String,
  insights_json : String
) -> LifelogAnalysis {
  {
    id: None,
    entry_id,
    model,
    version: "v1",
    payload_hash: None,
    insights_json,
    created_at: None,
  }
}

///|
/// Sync state key-value pair for tracking sync progress
pub(all) struct SyncState {
  key : String
  value : String?
  updated_at : String?
}

///|
/// Create a new SyncState
pub fn SyncState::new(key : String) -> SyncState {
  { key, value: None, updated_at: None }
}

///|
/// Analysis event for tracking analysis pipeline
pub(all) struct AnalysisEvent {
  id : Int?
  entry_id : String?
  status : String
  details : String?
  created_at : String?
}

///|
/// Create a new AnalysisEvent
pub fn AnalysisEvent::new(status : String) -> AnalysisEvent {
  { id: None, entry_id: None, status, details: None, created_at: None }
}

// =============================================================================
// API Response Types
// =============================================================================

///|
/// Timeline entry for API responses (enriched view)
pub(all) struct TimelineEntry {
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
/// Timeline segment for API responses
pub(all) struct TimelineSegment {
  id : String
  content : String?
  start_time : String?
  end_time : String?
  node_type : String?
  speaker_name : String?
}

///|
/// Analysis data structure
pub(all) struct Analysis {
  summary : String?
  mood : String?
  tags : Array[String]
  action_items : Array[ActionItem]
  suggestions : Array[Suggestion]
}

///|
/// Create an empty Analysis
pub fn Analysis::empty() -> Analysis {
  { summary: None, mood: None, tags: [], action_items: [], suggestions: [] }
}

///|
/// Action item from analysis
pub(all) struct ActionItem {
  title : String
  suggested_integration : String?
}

///|
/// Suggestion from analysis
pub(all) struct Suggestion {
  target : String
  rationale : String
}

///|
/// Day summary with tweets
pub(all) struct DaySummary {
  date : String
  tweets : Array[Tweet]
}

///|
/// Tweet in day summary
pub(all) struct Tweet {
  text : String
  time : String?
}

///|
/// Timeline API response
pub(all) struct TimelineResponse {
  timeline : Array[TimelineEntry]
  last_synced_at : String?
  last_analyzed_at : String?
}

// =============================================================================
// Gemini Insights Types
// =============================================================================

///|
/// Gemini insights for an entry
pub(all) struct GeminiInsights {
  summary : String?
  mood : String?
  tags : Array[String]
  action_items : Array[GeminiActionItem]
  suggestions : Array[GeminiSuggestion]
  key_topics : Array[String]
  sentiment_score : Double?
}

///|
/// Create empty GeminiInsights
pub fn GeminiInsights::empty() -> GeminiInsights {
  {
    summary: None,
    mood: None,
    tags: [],
    action_items: [],
    suggestions: [],
    key_topics: [],
    sentiment_score: None,
  }
}

///|
/// Gemini action item
pub(all) struct GeminiActionItem {
  title : String
  priority : String?
  due_date : String?
  suggested_integration : String?
}

///|
/// Gemini suggestion
pub(all) struct GeminiSuggestion {
  target : String
  rationale : String
  action_type : String?
}

// =============================================================================
// Sync Types
// =============================================================================

///|
/// Sync status enum
pub enum SyncStatus {
  Idle
  Syncing
  Success
  Error(String)
}

///|
/// Convert SyncStatus to string
pub fn SyncStatus::to_string(self : SyncStatus) -> String {
  match self {
    Idle => "idle"
    Syncing => "syncing"
    Success => "success"
    Error(msg) => "error: " + msg
  }
}

///|
/// Sync result from API
pub(all) struct SyncResult {
  success : Bool
  entries_synced : Int
  last_synced_at : String?
  error : String?
}

// =============================================================================
// Query Parameters
// =============================================================================

///|
/// Parameters for timeline query
pub(all) struct TimelineQueryParams {
  days : Int
  offset : Int
  detail : Bool
}

///|
/// Create default TimelineQueryParams
pub fn TimelineQueryParams::default() -> TimelineQueryParams {
  { days: 7, offset: 0, detail: false }
}

///|
/// Parameters for date range query
pub(all) struct DateRangeParams {
  start_date : String
  end_date : String
}

// =============================================================================
// Utility Functions
// =============================================================================

///|
/// Check if a LifelogEntry has analysis
pub fn LifelogEntry::has_analysis(self : LifelogEntry) -> Bool {
  self.last_analyzed_at is Some(_)
}

///|
/// Check if a LifelogEntry is complete (has both start and end time)
pub fn LifelogEntry::is_complete(self : LifelogEntry) -> Bool {
  self.start_time is Some(_) && self.end_time is Some(_)
}

///|
/// Get duration in milliseconds if available
pub fn LifelogEntry::duration_ms(self : LifelogEntry) -> Int? {
  match (self.start_epoch_ms, self.end_epoch_ms) {
    (Some(start), Some(end)) => Some(end - start)
    _ => None
  }
}
