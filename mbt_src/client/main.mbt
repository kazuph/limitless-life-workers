///|
/// Main entry point for Luna UI client
/// Mounts the application and handles routing

///|
/// Mount the application
pub fn mount() -> Unit {
  @console.log(@core.any("Luna UI: Mounting application..."))

  // Get root element
  let root = match get_by_id("root") {
    Some(el) => el
    None => {
      @console.error(@core.any("Root element not found"))
      return
    }
  }

  // Initialize the app layout
  render_app_layout(root)

  // Subscribe to state changes
  subscribe(fn() {
    render_app_layout(root)
  })

  // Initial data load
  load_initial_data()
}

///|
/// Render the main app layout
fn render_app_layout(root : @dom.Element) -> Unit {
  let state = get_state()

  root.setInnerHTML("")
  root.setClassName("min-h-screen")

  let container = div(
    "mx-auto flex w-full max-w-[90rem] flex-col gap-12 px-6 py-12 lg:px-12 xl:max-w-[105rem] 2xl:max-w-[115rem]",
    []
  )

  // Header section
  let header_container = div("", [])
  render_app_header(header_container)
  container.append(header_container.as_node())

  // Error display
  match state.error_message {
    Some(err) => {
      let error_card = div(
        "rounded-lg border bg-card text-card-foreground shadow-sm",
        []
      )
      let error_content = div(
        "py-6 text-center text-red-400",
        []
      )
      set_text(error_content, err)
      error_card.append(error_content.as_node())
      container.append(error_card.as_node())
    }
    None => {
      // Main content row: Timeline (left) + Insights sidebar (right)
      let main_row = div("flex gap-8", [])

      // Timeline section (left, flex-1)
      let timeline_section = section("flex-1 min-w-0 space-y-6", [])

      let timeline_header = div("", [])
      let timeline_title = h2("text-2xl font-bold tracking-tight text-foreground", "Timeline")
      timeline_header.append(timeline_title.as_node())

      let timeline_subtitle = p(
        "mt-1 text-xs uppercase tracking-[0.3em] text-muted-foreground/60",
        "Activity Log"
      )
      timeline_header.append(timeline_subtitle.as_node())
      timeline_section.append(timeline_header.as_node())

      if state.loading && state.timeline.length() == 0 {
        let skeleton = render_skeleton()
        timeline_section.append(skeleton.as_node())
      } else {
        let timeline_container = div("", [])
        render_timeline_board(
          timeline_container,
          state.timeline,
          fn(entry_id) { open_entry_drawer(entry_id) }
        )
        timeline_section.append(timeline_container.as_node())

        // Load more button
        if state.timeline.length() > 0 {
          let load_more_row = div("flex justify-center pt-6", [])
          let load_more_btn = button(
            "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2 min-w-[200px]",
            if state.loading { "Loading..." } else { "Read More" },
            fn(_) { load_more() }
          )
          if state.loading {
            load_more_btn.setAttribute("disabled", "true")
          }
          load_more_row.append(load_more_btn.as_node())
          timeline_section.append(load_more_row.as_node())
        }
      }

      main_row.append(timeline_section.as_node())

      // Right sidebar: Insights (fixed width, sticky)
      let sidebar = aside(
        "hidden lg:block w-80 xl:w-96 flex-shrink-0",
        []
      )
      let sidebar_inner = div("sticky top-8 space-y-6", [])

      // Insights section
      let insights_section = section("space-y-4", [])

      let insights_header = div("", [])
      let insights_title = h2("text-lg font-bold tracking-tight text-foreground", "AI Insights")
      insights_header.append(insights_title.as_node())

      let insights_subtitle = p(
        "mt-1 text-[10px] uppercase tracking-[0.3em] text-muted-foreground/60",
        "Intelligent Suggestions"
      )
      insights_header.append(insights_subtitle.as_node())
      insights_section.append(insights_header.as_node())

      let model_label = span("text-[10px] text-muted-foreground/50", "Workers AI gpt-oss-120b")
      insights_section.append(model_label.as_node())

      let insights_container = div("", [])
      render_insights_sidebar(insights_container, state.timeline)
      insights_section.append(insights_container.as_node())

      sidebar_inner.append(insights_section.as_node())
      sidebar.append(sidebar_inner.as_node())
      main_row.append(sidebar.as_node())

      container.append(main_row.as_node())
    }
  }

  root.append(container.as_node())

  // Render drawer if entry is selected
  match state.selected_entry_id {
    Some(entry_id) => render_entry_drawer(Some(entry_id), close_entry_drawer)
    None => render_entry_drawer(None, close_entry_drawer)
  }
}

///|
/// Render skeleton loading state
fn render_skeleton() -> @dom.Element {
  let skeleton = div(
    "animate-pulse space-y-4 rounded-xl border border-border/40 p-6 text-muted-foreground",
    []
  )

  let line = div("h-6 w-1/3 rounded bg-muted/40", [])
  skeleton.append(line.as_node())

  let box = div("h-[420px] rounded-xl border border-dashed border-muted/40", [])
  skeleton.append(box.as_node())

  skeleton
}

///|
/// Load initial data
fn load_initial_data() -> Unit {
  @core.run_async(
    async fn() noraise {
      try {
        let response = fetch_timeline(7, 0, true)
        set_timeline(response.timeline)
        set_sync_timestamps(response.last_synced_at, response.last_analyzed_at)
        set_loading(false)
      } catch {
        e => {
          set_loading(false)
          set_error(Some("Failed to load timeline data"))
          @console.error(@core.any("Load failed: " + e.to_string()))
        }
      }
    }
  )
}

///|
/// Load more entries
fn load_more() -> Unit {
  let state = get_state()
  let new_offset = state.offset + 7
  set_offset(new_offset)
  set_loading(true)

  @core.run_async(
    async fn() noraise {
      try {
        let response = fetch_timeline(7, new_offset, true)
        append_timeline(response.timeline)
        set_loading(false)
      } catch {
        e => {
          set_loading(false)
          @console.error(@core.any("Load more failed: " + e.to_string()))
        }
      }
    }
  )
}

///|
/// Open entry drawer
fn open_entry_drawer(entry_id : String) -> Unit {
  set_selected_entry(Some(entry_id))
}

///|
/// Close entry drawer
fn close_entry_drawer() -> Unit {
  set_selected_entry(None)
  close_drawer()
}

///|
/// Main function (required for MoonBit JS module)
fn main {
  // Auto-mount when DOM is ready
  let ready_state = @dom.document().ready_state()
  if ready_state == "loading" {
    @dom.document().as_event_target().add_event_listener(
      "DOMContentLoaded",
      fn(_event) { mount() }
    )
  } else {
    mount()
  }
}
