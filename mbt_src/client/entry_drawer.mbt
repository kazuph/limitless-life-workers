///|
/// Entry Details Drawer component
/// Shows detailed information about a selected timeline entry

///|
/// Drawer state
struct DrawerState {
  mut entry : TimelineEntry?
  mut loading : Bool
  mut error : String?
}

///|
/// Global drawer state
let drawer_state : DrawerState = { entry: None, loading: false, error: None }

///|
/// Render entry drawer
pub fn render_entry_drawer(entry_id : String?, on_close : () -> Unit) -> Unit {
  // Get or create drawer container
  let drawer_container = match get_by_id("entry-drawer") {
    Some(el) => el
    None => {
      let container = div("fixed right-0 top-0 h-full z-[9999]", [])
      container.setId("entry-drawer")
      match @dom.document().body() {
        Some(body) => body.as_element().append(container.as_node())
        None => ()
      }
      container
    }
  }

  match entry_id {
    None => {
      drawer_container.setInnerHTML("")
      drawer_state.entry = None
    }
    Some(id) => {
      // Show loading state
      drawer_state.loading = true
      drawer_state.error = None
      render_drawer_content(drawer_container, on_close)

      // Fetch entry details
      @core.run_async(
        async fn() noraise {
          try {
            let entry = fetch_entry_detail(id)
            drawer_state.entry = Some(entry)
            drawer_state.loading = false
            render_drawer_content(drawer_container, on_close)
          } catch {
            e => {
              drawer_state.loading = false
              drawer_state.error = Some("Failed to load entry details")
              @console.error(@core.any("Fetch entry failed: " + e.to_string()))
              render_drawer_content(drawer_container, on_close)
            }
          }
        }
      )
    }
  }
}

///|
/// Render drawer content
fn render_drawer_content(container : @dom.Element, on_close : () -> Unit) -> Unit {
  container.setInnerHTML("")

  let drawer = div(
    "h-full w-full max-w-[540px] border-l border-border/60 bg-background shadow-2xl",
    []
  )

  // Header
  let header = div(
    "flex items-center justify-between border-b border-border/40 px-6 py-4",
    []
  )

  let header_left = div("space-y-1", [])
  let label = p("text-xs uppercase tracking-[0.3em] text-muted-foreground/70", "Entry Details")
  header_left.append(label.as_node())

  let title_text = match drawer_state.entry {
    Some(e) => e.title
    None => "Loading..."
  }
  let title = @dom.document().create_element("h3")
  title.setClassName("text-lg font-semibold text-foreground")
  set_text(title, title_text)
  header_left.append(title.as_node())
  header.append(header_left.as_node())

  let close_btn = button(
    "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground h-9 px-3",
    "Close",
    fn(_) { on_close() }
  )
  header.append(close_btn.as_node())
  drawer.append(header.as_node())

  // Content
  let content = div("h-[calc(100%-64px)] overflow-y-auto px-6 py-5 space-y-6", [])

  if drawer_state.loading {
    let loading_msg = div(
      "rounded-md border border-border/40 bg-muted/30 px-4 py-3 text-sm text-muted-foreground",
      []
    )
    set_text(loading_msg, "Loading details...")
    content.append(loading_msg.as_node())
  } else {
    match drawer_state.error {
      Some(err) => {
        let error_msg = div(
          "rounded-md border border-border/40 bg-red-500/10 px-4 py-3 text-sm text-red-400",
          []
        )
        set_text(error_msg, err)
        content.append(error_msg.as_node())
      }
      None => {
        match drawer_state.entry {
          Some(entry) => {
            render_entry_details(content, entry)
          }
          None => ()
        }
      }
    }
  }

  drawer.append(content.as_node())
  container.append(drawer.as_node())
}

///|
/// Render entry details
fn render_entry_details(container : @dom.Element, entry : TimelineEntry) -> Unit {
  // AI Summary section
  let summary_section = div("space-y-2", [])
  let summary_label = p(
    "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
    "AI Summary"
  )
  summary_section.append(summary_label.as_node())

  let summary_text = match entry.analysis {
    Some(a) => {
      match a.summary {
        Some(s) => s
        None => "AI Summary not generated yet."
      }
    }
    None => "AI Summary not generated yet."
  }
  let summary_p = p(
    "text-sm leading-relaxed text-foreground/90 whitespace-pre-wrap",
    summary_text
  )
  summary_section.append(summary_p.as_node())

  // Regenerate button
  let btn_row = div("flex justify-end", [])
  let regen_btn = create_analysis_button(entry.id)
  btn_row.append(regen_btn.as_node())
  summary_section.append(btn_row.as_node())
  container.append(summary_section.as_node())

  // Action items section
  match entry.analysis {
    Some(a) => {
      if a.action_items.length() > 0 {
        let ai_section = div("space-y-2", [])
        let ai_label = p(
          "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
          "Action Items"
        )
        ai_section.append(ai_label.as_node())

        let ai_list = ul("space-y-2 text-sm text-foreground/90", [])
        for item in a.action_items {
          let li_el = li("rounded-md border border-border/40 px-3 py-2", [])
          let title_p = p("", item.title)
          li_el.append(title_p.as_node())

          match item.suggested_integration {
            Some(integration) => {
              let int_p = p(
                "text-[11px] uppercase tracking-wide text-muted-foreground",
                "-> " + integration
              )
              li_el.append(int_p.as_node())
            }
            None => ()
          }
          ai_list.append(li_el.as_node())
        }
        ai_section.append(ai_list.as_node())
        container.append(ai_section.as_node())
      }

      // Suggestions section
      if a.suggestions.length() > 0 {
        let sugg_section = div("space-y-2", [])
        let sugg_label = p(
          "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
          "Suggestions"
        )
        sugg_section.append(sugg_label.as_node())

        let sugg_list = ul("space-y-1 text-sm text-foreground/90", [])
        for sugg in a.suggestions {
          let li_el = li("", [])
          let li_text = sugg.target + ": " + sugg.rationale
          set_text(li_el, li_text)
          sugg_list.append(li_el.as_node())
        }
        sugg_section.append(sugg_list.as_node())
        container.append(sugg_section.as_node())
      }
    }
    None => ()
  }

  // Logs section
  let logs_section = div("space-y-2", [])
  let logs_label = p(
    "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
    "Logs"
  )
  logs_section.append(logs_label.as_node())

  if entry.segments.length() > 0 {
    let logs_list = ul("space-y-2 text-sm text-foreground/90", [])
    for segment in entry.segments {
      match segment.content {
        Some(content) => {
          if content.length() > 0 {
            let li_el = li("flex gap-3", [])

            let time_label = match segment.start_time {
              Some(st) => @date.to_locale_time(st)
              None => "-"
            }
            let time_span = span(
              "text-[11px] font-mono text-muted-foreground min-w-[52px]",
              time_label
            )
            li_el.append(time_span.as_node())

            let content_span = span("whitespace-pre-wrap", content)
            li_el.append(content_span.as_node())

            logs_list.append(li_el.as_node())
          }
        }
        None => ()
      }
    }
    logs_section.append(logs_list.as_node())
  } else {
    let no_logs = p("text-sm text-muted-foreground", "No logs found.")
    logs_section.append(no_logs.as_node())
  }

  container.append(logs_section.as_node())
}

///|
/// Create analysis regenerate button
fn create_analysis_button(entry_id : String) -> @dom.Element {
  let btn = @dom.document().create_element("button")
  btn.setClassName(
    "inline-flex h-8 w-8 items-center justify-center rounded-full border border-border/60 bg-background/90 shadow-sm transition hover:bg-muted/40 disabled:opacity-60"
  )
  btn.setAttribute("type", "button")
  btn.setAttribute("aria-label", "Regenerate AI summary")

  let icon = img("h-4 w-4 rounded-full", "/images/openai-icon.svg", "ChatGPT")
  btn.append(icon.as_node())

  on(btn, "click", fn(_event) {
    @core.run_async(
      async fn() noraise {
        try {
          trigger_analysis(entry_id)
          // Refetch entry details
          let entry = fetch_entry_detail(entry_id)
          drawer_state.entry = Some(entry)
          match get_by_id("entry-drawer") {
            Some(container) => render_drawer_content(container, fn() { set_selected_entry(None) })
            None => ()
          }
        } catch {
          e => @console.error(@core.any("Analysis failed: " + e.to_string()))
        }
      }
    )
  })

  btn
}

///|
/// Close drawer
pub fn close_drawer() -> Unit {
  drawer_state.entry = None
  drawer_state.loading = false
  drawer_state.error = None
  match get_by_id("entry-drawer") {
    Some(el) => el.setInnerHTML("")
    None => ()
  }
}
