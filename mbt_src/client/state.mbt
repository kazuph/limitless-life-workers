///|
/// Simple state management for Luna UI components
/// Provides reactive state with subscribers

///|
/// Global application state
pub struct AppState {
  mut timeline : Array[TimelineEntry]
  mut loading : Bool
  mut syncing : Bool
  mut offset : Int
  mut error_message : String?
  mut selected_entry_id : String?
  mut last_synced_at : String?
  mut last_analyzed_at : String?
  day_summaries : @core.Any  // Map<String, DaySummary>
}

///|
/// Create initial app state
pub fn create_app_state() -> AppState {
  {
    timeline: [],
    loading: true,
    syncing: false,
    offset: 0,
    error_message: None,
    selected_entry_id: None,
    last_synced_at: None,
    last_analyzed_at: None,
    day_summaries: @core.new_object(),
  }
}

///|
/// Global state instance
let state : AppState = create_app_state()

///|
/// Subscribers list
let subscribers : Array[() -> Unit] = []

///|
/// Subscribe to state changes
pub fn subscribe(callback : () -> Unit) -> Unit {
  subscribers.push(callback)
}

///|
/// Notify all subscribers
fn notify() -> Unit {
  for callback in subscribers {
    callback()
  }
}

///|
/// Get current state
pub fn get_state() -> AppState {
  state
}

///|
/// Set timeline entries
pub fn set_timeline(entries : Array[TimelineEntry]) -> Unit {
  state.timeline = entries
  notify()
}

///|
/// Append timeline entries
pub fn append_timeline(entries : Array[TimelineEntry]) -> Unit {
  for entry in entries {
    state.timeline.push(entry)
  }
  notify()
}

///|
/// Set loading state
pub fn set_loading(loading : Bool) -> Unit {
  state.loading = loading
  notify()
}

///|
/// Set syncing state
pub fn set_syncing(syncing : Bool) -> Unit {
  state.syncing = syncing
  notify()
}

///|
/// Set offset
pub fn set_offset(offset : Int) -> Unit {
  state.offset = offset
  notify()
}

///|
/// Set error message
pub fn set_error(message : String?) -> Unit {
  state.error_message = message
  notify()
}

///|
/// Set selected entry ID
pub fn set_selected_entry(entry_id : String?) -> Unit {
  state.selected_entry_id = entry_id
  notify()
}

///|
/// Set sync timestamps
pub fn set_sync_timestamps(synced_at : String?, analyzed_at : String?) -> Unit {
  state.last_synced_at = synced_at
  state.last_analyzed_at = analyzed_at
  notify()
}

///|
/// Set day summary
pub fn set_day_summary(date : String, summary : DaySummary) -> Unit {
  state.day_summaries._set(date, @core.any(summary)) |> ignore
  notify()
}

///|
/// Get day summary
pub fn get_day_summary(date : String) -> DaySummary? {
  let val = state.day_summaries._get(date)
  if @core.is_nullish(val) {
    None
  } else {
    // Convert from Any to DaySummary
    let date_val : String = val["date"].cast()
    let tweets : Array[Tweet] = []
    let tweets_json = val["tweets"]
    if not(@core.is_nullish(tweets_json)) {
      let tw_arr = @core.array_from(tweets_json)
      for tw in tw_arr {
        let text : String = tw["text"].cast()
        let time : String? = @core.identity_option(tw["time"])
        tweets.push({ text, time })
      }
    }
    Some({ date: date_val, tweets })
  }
}
