///|
/// App Header component
/// Main application header with title and sync button

///|
/// Format timestamp for display
fn format_timestamp(value : String?) -> String {
  match value {
    None => "---"
    Some(v) => {
      if v.length() == 0 {
        "---"
      } else {
        @date.to_locale_time(v)
      }
    }
  }
}

///|
/// Render app header
pub fn render_app_header(container : @dom.Element) -> Unit {
  let state = get_state()

  container.setInnerHTML("")

  let header = header("flex flex-col gap-6", [])

  let row = div("flex flex-col gap-3 md:flex-row md:items-end md:justify-between", [])

  // Left side - title
  let left = div("space-y-2", [])
  let title = h1("text-4xl font-bold tracking-tight text-foreground", "Life Log")
  left.append(title.as_node())

  let subtitle = p(
    "text-sm uppercase tracking-[0.3em] text-muted-foreground/80",
    "Activity Timeline"
  )
  left.append(subtitle.as_node())
  row.append(left.as_node())

  // Right side - sync button and timestamps
  let right = div("flex flex-col items-end gap-2", [])

  let btn_text = if state.syncing { "Requesting..." } else { "Request Sync" }
  let sync_btn = button(
    "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 bg-foreground text-background hover:bg-foreground/90 h-10 px-4 py-2",
    btn_text,
    fn(_event) {
      if not(state.syncing) {
        handle_sync()
      }
    }
  )
  if state.syncing {
    sync_btn.setAttribute("disabled", "true")
  }
  right.append(sync_btn.as_node())

  // Timestamps
  let timestamps = div("flex items-center gap-4 text-xs text-muted-foreground/70", [])

  let sync_time = span("", "Last sync: " + format_timestamp(state.last_synced_at))
  timestamps.append(sync_time.as_node())

  let dot = span("", " - ")
  timestamps.append(dot.as_node())

  let analysis_time = span("", "Last analysis: " + format_timestamp(state.last_analyzed_at))
  timestamps.append(analysis_time.as_node())

  right.append(timestamps.as_node())
  row.append(right.as_node())

  header.append(row.as_node())

  // Separator
  let separator = div("shrink-0 bg-border/60 h-[1px] w-full", [])
  header.append(separator.as_node())

  container.append(header.as_node())
}

///|
/// Handle sync button click
fn handle_sync() -> Unit {
  set_syncing(true)

  @core.run_async(
    async fn() noraise {
      try {
        trigger_sync()
        // Reset offset and reload data
        set_offset(0)
        let response = fetch_timeline(7, 0, true)
        set_timeline(response.timeline)
        set_sync_timestamps(response.last_synced_at, response.last_analyzed_at)
        set_syncing(false)
      } catch {
        e => {
          set_syncing(false)
          set_error(Some("Sync failed"))
          @console.error(@core.any("Sync failed: " + e.to_string()))
        }
      }
    }
  )
}
