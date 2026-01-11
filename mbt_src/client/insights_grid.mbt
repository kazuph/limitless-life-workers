///|
/// Insights Grid component
/// Displays AI analysis cards for analyzed entries

///|
/// Render insights grid (2-column layout for main content)
pub fn render_insights_grid(
  container : @dom.Element,
  entries : Array[TimelineEntry]
) -> Unit {
  // Clear container
  container.setInnerHTML("")

  // Filter entries with analysis (first 4)
  let analyzed : Array[TimelineEntry] = []
  for entry in entries {
    match entry.analysis {
      Some(_) => {
        if analyzed.length() < 4 {
          analyzed.push(entry)
        }
      }
      None => ()
    }
  }

  if analyzed.length() == 0 {
    return
  }

  let grid = div("grid gap-4 md:grid-cols-2", [])

  for entry in analyzed {
    let card = render_insight_card(entry)
    grid.append(card.as_node())
  }

  container.append(grid.as_node())
}

///|
/// Render insights sidebar (vertical stack layout for right sidebar)
pub fn render_insights_sidebar(
  container : @dom.Element,
  entries : Array[TimelineEntry]
) -> Unit {
  // Clear container
  container.setInnerHTML("")

  // Filter entries with analysis (first 6 for sidebar)
  let analyzed : Array[TimelineEntry] = []
  for entry in entries {
    match entry.analysis {
      Some(_) => {
        if analyzed.length() < 6 {
          analyzed.push(entry)
        }
      }
      None => ()
    }
  }

  if analyzed.length() == 0 {
    let empty = div("py-8 text-center text-muted-foreground/60 text-sm", [])
    set_text(empty, "No insights yet")
    container.append(empty.as_node())
    return
  }

  // Vertical stack layout
  let stack = div("space-y-3", [])

  for entry in analyzed {
    let card = render_sidebar_insight_card(entry)
    stack.append(card.as_node())
  }

  container.append(stack.as_node())
}

///|
/// Render a compact insight card for sidebar
fn render_sidebar_insight_card(entry : TimelineEntry) -> @dom.Element {
  let card = div(
    "rounded-lg border border-border/40 bg-card/50 hover:bg-card hover:border-border/60 transition-all duration-200 overflow-hidden",
    []
  )

  // Compact card content
  let content = div("p-3 space-y-2", [])

  // Title row with truncation
  let title = @dom.document().create_element("h4")
  title.setClassName("text-sm font-medium leading-snug line-clamp-2 text-foreground")
  set_text(title, entry.title)
  content.append(title.as_node())

  match entry.analysis {
    Some(a) => {
      // Summary (if available)
      match a.summary {
        Some(summary) => {
          if summary.length() > 0 {
            let summary_el = p(
              "text-xs text-muted-foreground line-clamp-2",
              summary
            )
            content.append(summary_el.as_node())
          }
        }
        None => ()
      }

      // Tags (up to 2)
      if a.tags.length() > 0 {
        let tags_row = div("flex flex-wrap gap-1 mt-1", [])
        let mut tag_count = 0
        for tag in a.tags {
          if tag_count < 2 {
            let badge = span(
              "inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium bg-muted/60 text-muted-foreground",
              tag
            )
            tags_row.append(badge.as_node())
            tag_count = tag_count + 1
          }
        }
        content.append(tags_row.as_node())
      }

      // Action items preview (first 2)
      if a.action_items.length() > 0 {
        let actions_section = div("mt-2 pt-2 border-t border-border/30", [])
        let actions_title = p("text-[10px] uppercase tracking-wide text-muted-foreground/70 mb-1", "Actions")
        actions_section.append(actions_title.as_node())

        let actions_list = div("space-y-1", [])
        let mut action_count = 0
        for item in a.action_items {
          if action_count < 2 {
            let action_row = div("flex items-start gap-1.5", [])
            let bullet = span("text-purple-500 text-xs mt-0.5", "•")
            action_row.append(bullet.as_node())
            let action_text = span("text-xs text-foreground/80 line-clamp-1", item.title)
            action_row.append(action_text.as_node())
            actions_list.append(action_row.as_node())
            action_count = action_count + 1
          }
        }
        actions_section.append(actions_list.as_node())
        content.append(actions_section.as_node())
      }
    }
    None => ()
  }

  card.append(content.as_node())
  card
}

///|
/// Render a single insight card
fn render_insight_card(entry : TimelineEntry) -> @dom.Element {
  let card = div(
    "rounded-lg border bg-card text-card-foreground shadow-sm",
    []
  )

  // Card header
  let card_header = div("flex flex-col space-y-1.5 p-6", [])

  let header_row = div("flex items-center justify-between", [])
  let title = @dom.document().create_element("h3")
  title.setClassName("text-base font-semibold leading-none tracking-tight")
  set_text(title, entry.title)
  header_row.append(title.as_node())

  // Tags
  match entry.analysis {
    Some(a) => {
      let tags_container = div("flex gap-1", [])
      let mut tag_count = 0
      for tag in a.tags {
        if tag_count < 2 {
          let badge = span(
            "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80",
            tag
          )
          tags_container.append(badge.as_node())
          tag_count = tag_count + 1
        }
      }
      header_row.append(tags_container.as_node())

      let summary_text = match a.summary {
        Some(s) => s
        None => ""
      }
      if summary_text.length() > 0 {
        let summary_p = p("text-sm text-muted-foreground", summary_text)
        card_header.append(summary_p.as_node())
      }
    }
    None => ()
  }

  card_header.append(header_row.as_node())
  card.append(card_header.as_node())

  // Card content
  let card_content = div("p-6 pt-0 space-y-4", [])

  match entry.analysis {
    Some(a) => {
      // Action items
      if a.action_items.length() > 0 {
        let ai_section = div("text-sm", [])
        let ai_title = p("mb-2 font-semibold text-foreground/80", "Action Items")
        ai_section.append(ai_title.as_node())

        let ai_list = ul("space-y-1 text-muted-foreground", [])
        let mut ai_count = 0
        for item in a.action_items {
          if ai_count < 3 {
            let li_el = li("rounded-md border border-border/30 px-3 py-2", [])
            let item_title = p("text-foreground", item.title)
            li_el.append(item_title.as_node())

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
            ai_count = ai_count + 1
          }
        }
        ai_section.append(ai_list.as_node())
        card_content.append(ai_section.as_node())
      }

      // Suggestions
      if a.suggestions.length() > 0 {
        // Separator
        let separator = div("shrink-0 bg-border h-[1px] w-full", [])
        card_content.append(separator.as_node())

        let sugg_section = div("text-sm", [])
        let sugg_title = p("mb-2 font-semibold", "Integration ideas")
        sugg_section.append(sugg_title.as_node())

        let sugg_list = ul("space-y-1 text-muted-foreground", [])
        let mut sugg_count = 0
        for sugg in a.suggestions {
          if sugg_count < 2 {
            let li_el = li("text-foreground/90", [])
            let sugg_text = sugg.target + ": "
            let target_span = span("", sugg_text)
            li_el.append(target_span.as_node())

            let rationale_span = span("text-muted-foreground", sugg.rationale)
            li_el.append(rationale_span.as_node())

            sugg_list.append(li_el.as_node())
            sugg_count = sugg_count + 1
          }
        }
        sugg_section.append(sugg_list.as_node())
        card_content.append(sugg_section.as_node())
      }
    }
    None => ()
  }

  card.append(card_content.as_node())
  card
}
