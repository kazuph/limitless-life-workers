///|
/// Timeline Board component
/// Renders a vertical card-based timeline grouped by date and hour
/// Design: Editorial journal aesthetic with warm tones

///|
/// Group entries by date
fn group_by_date(entries : Array[TimelineEntry]) -> Array[(String, Array[TimelineEntry])] {
  let groups : Array[(String, Array[TimelineEntry])] = []
  let date_map : @core.Any = @core.new_object()

  for entry in entries {
    let label = match entry.date_label {
      Some(dl) => dl
      None => @date.format_date_label(entry.start_time)
    }

    if @core.is_nullish(date_map._get(label)) {
      date_map._set(label, @core.new_array()) |> ignore
    }

    let arr : @core.Any = date_map._get(label)
    arr._call("push", [@core.any(entry)]) |> ignore
  }

  // Extract groups in order (entries are already sorted by date)
  let seen : @core.Any = @core.new_object()
  for entry in entries {
    let label = match entry.date_label {
      Some(dl) => dl
      None => @date.format_date_label(entry.start_time)
    }
    if @core.is_nullish(seen._get(label)) {
      seen._set(label, @core.any(true)) |> ignore
      let items_any = date_map._get(label)
      let items : Array[TimelineEntry] = []
      let items_arr = @core.array_from(items_any)
      for item in items_arr {
        items.push(@core.identity(item))
      }
      groups.push((label, items))
    }
  }

  groups
}

///|
/// Group entries by hour within a date (returns hours in descending order)
fn group_by_hour(entries : Array[TimelineEntry]) -> Array[(Int, Array[TimelineEntry])] {
  let hour_map : @core.Any = @core.new_object()

  for entry in entries {
    match @date.get_time_components(entry.start_time) {
      Some((hour, _, _)) => {
        let key = hour.to_string()
        if @core.is_nullish(hour_map._get(key)) {
          hour_map._set(key, @core.new_array()) |> ignore
        }
        let arr : @core.Any = hour_map._get(key)
        arr._call("push", [@core.any(entry)]) |> ignore
      }
      None => ()
    }
  }

  // Collect hours in descending order (23 -> 0)
  let groups : Array[(Int, Array[TimelineEntry])] = []
  let mut hour = 23
  while hour >= 0 {
    let key = hour.to_string()
    if not(@core.is_nullish(hour_map._get(key))) {
      let items_any = hour_map._get(key)
      let items : Array[TimelineEntry] = []
      let items_arr = @core.array_from(items_any)
      for item in items_arr {
        items.push(@core.identity(item))
      }
      // Sort by start_time descending within hour
      sort_entries_by_time_desc(items)
      groups.push((hour, items))
    }
    hour = hour - 1
  }

  groups
}

///|
/// Sort entries by start time descending (latest first)
fn sort_entries_by_time_desc(entries : Array[TimelineEntry]) -> Unit {
  // Simple bubble sort for small arrays
  let n = entries.length()
  let mut i = 0
  while i < n - 1 {
    let mut j = 0
    while j < n - i - 1 {
      if @date.compare_dates(entries[j].start_time, entries[j + 1].start_time) < 0 {
        let temp = entries[j]
        entries[j] = entries[j + 1]
        entries[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
}

///|
/// Render timeline board
pub fn render_timeline_board(
  container : @dom.Element,
  entries : Array[TimelineEntry],
  on_open_details : (String) -> Unit
) -> Unit {
  container.setInnerHTML("")

  if entries.length() == 0 {
    let empty = div(
      "flex flex-col items-center justify-center py-16 text-center",
      []
    )
    let icon = div("text-4xl mb-4 opacity-40", [])
    set_text(icon, "📝")
    empty.append(icon.as_node())

    let msg = p("text-muted-foreground text-lg", "No lifelogs saved yet")
    empty.append(msg.as_node())

    let hint = p("text-muted-foreground/60 text-sm mt-1", "Sync your Limitless data to get started")
    empty.append(hint.as_node())

    container.append(empty.as_node())
    return
  }

  let groups = group_by_date(entries)

  for group in groups {
    let (date, items) = group
    let group_el = render_date_group(date, items, on_open_details)
    container.append(group_el.as_node())
  }
}

///|
/// Render a date group with hour-based card layout
fn render_date_group(
  date : String,
  items : Array[TimelineEntry],
  on_open_details : (String) -> Unit
) -> @dom.Element {
  let wrapper = div(
    "mb-8",
    []
  )

  // Date header
  let header = render_date_header(date, items)
  wrapper.append(header.as_node())

  // Hour groups container
  let content = div("space-y-1", [])

  let hour_groups = group_by_hour(items)
  for hour_group in hour_groups {
    let (hour, hour_items) = hour_group
    let hour_row = render_hour_row(hour, hour_items, on_open_details)
    content.append(hour_row.as_node())
  }

  wrapper.append(content.as_node())
  wrapper
}

///|
/// Render date header with elegant styling
fn render_date_header(date : String, items : Array[TimelineEntry]) -> @dom.Element {
  let header = div(
    "flex items-center justify-between mb-4 pb-3 border-b border-border/30",
    []
  )

  let left = div("flex items-center gap-4", [])

  // Date with refined typography
  let date_el = div("flex items-baseline gap-2", [])
  let date_text = span("text-xl font-semibold tracking-tight text-foreground", date)
  date_el.append(date_text.as_node())
  left.append(date_el.as_node())

  // Entry count badge
  let count_text = items.length().to_string() + (if items.length() == 1 { " entry" } else { " entries" })
  let count_badge = span(
    "px-2.5 py-1 rounded-full text-xs font-medium bg-muted/60 text-muted-foreground",
    count_text
  )
  left.append(count_badge.as_node())

  header.append(left.as_node())

  // Regenerate buttons
  let buttons = div("flex items-center gap-2", [])
  let openai_btn = create_regenerate_button("/images/openai-icon.svg", "GPT-OSS-120B", date, "openai")
  let gemini_btn = create_regenerate_button("/images/gemini-icon.svg", "Gemini 2.0 Flash", date, "gemini")
  buttons.append(openai_btn.as_node())
  buttons.append(gemini_btn.as_node())
  header.append(buttons.as_node())

  header
}

///|
/// Create regenerate button
fn create_regenerate_button(
  icon_src : String,
  alt : String,
  date : String,
  provider : String
) -> @dom.Element {
  let btn = @dom.document().create_element("button")
  btn.setClassName(
    "inline-flex h-8 w-8 items-center justify-center rounded-full border border-border/40 bg-background/80 hover:bg-muted/60 hover:border-border transition-all duration-200"
  )
  btn.setAttribute("type", "button")
  btn.setAttribute("aria-label", "Regenerate with " + alt)
  btn.setAttribute("title", "Regenerate with " + alt)

  let icon = img("h-4 w-4 rounded-full", icon_src, alt)
  btn.append(icon.as_node())

  on(btn, "click", fn(_event) {
    @core.run_async(
      async fn() noraise {
        try {
          let summary = regenerate_day_summary(date, provider)
          set_day_summary(date, summary)
        } catch {
          e => @console.error(@core.any("Regenerate failed: " + e.to_string()))
        }
      }
    )
  })

  btn
}

///|
/// Render an hour row with horizontally arranged cards
fn render_hour_row(
  hour : Int,
  items : Array[TimelineEntry],
  on_open_details : (String) -> Unit
) -> @dom.Element {
  let row = div(
    "flex gap-3 py-2",
    []
  )

  // Hour label - elegant sidebar indicator
  let hour_label = div(
    "flex-shrink-0 w-14 flex items-start justify-end pt-3 pr-3",
    []
  )
  let hour_text = span(
    "text-sm font-medium text-muted-foreground/70 tabular-nums",
    @utils.pad_left(hour.to_string(), 2, "0") + ":00"
  )
  hour_label.append(hour_text.as_node())
  row.append(hour_label.as_node())

  // Cards container with flex wrap
  let cards = div(
    "flex-1 flex flex-wrap gap-3",
    []
  )

  for item in items {
    let card = render_entry_card(item, on_open_details)
    cards.append(card.as_node())
  }

  row.append(cards.as_node())
  row
}

///|
/// Render a single entry card
fn render_entry_card(
  entry : TimelineEntry,
  on_open_details : (String) -> Unit
) -> @dom.Element {
  let card = div(
    "group relative flex flex-col p-4 rounded-xl border border-border/40 bg-card/50 hover:bg-card hover:border-border/60 hover:shadow-md transition-all duration-200 cursor-pointer min-w-[200px] max-w-[320px]",
    []
  )

  // Top row: Time range and duration
  let top_row = div("flex items-center justify-between gap-3 mb-2", [])

  // Time range with subtle styling
  let time_range = @date.to_locale_time(entry.start_time) + " – " + @date.to_locale_time(entry.end_time)
  let time_el = span(
    "text-xs font-medium text-muted-foreground tabular-nums",
    time_range
  )
  top_row.append(time_el.as_node())

  // Duration or char count badge
  let char_count = count_segment_chars(entry.segments)
  let metric_text = if char_count > 0 {
    @entry.format_number_with_comma(char_count) + " chars"
  } else if entry.segments.length() > 0 {
    entry.segments.length().to_string() + " seg"
  } else {
    match entry.duration_minutes {
      Some(d) => d.to_string() + " min"
      None => ""
    }
  }

  if metric_text.length() > 0 {
    let metric_badge = span(
      "text-[10px] font-medium px-1.5 py-0.5 rounded bg-muted/50 text-muted-foreground",
      metric_text
    )
    top_row.append(metric_badge.as_node())
  }

  card.append(top_row.as_node())

  // Title - the main content
  let title_row = div("flex items-start gap-2", [])
  let title_el = p(
    "text-sm font-medium text-foreground leading-snug line-clamp-2 group-hover:text-foreground/90",
    entry.title
  )
  title_row.append(title_el.as_node())
  card.append(title_row.as_node())

  // Mood indicator (if available)
  match entry.analysis {
    Some(a) => {
      match a.mood {
        Some(mood) => {
          let mood_row = div("mt-2 flex items-center gap-1.5", [])
          let mood_el = span("text-base", mood)
          mood_row.append(mood_el.as_node())

          // Optional: show summary excerpt
          match a.summary {
            Some(summary) => {
              if summary.length() > 0 {
                let summary_el = span(
                  "text-xs text-muted-foreground/70 truncate max-w-[180px]",
                  @utils.truncate(summary, 40, "...")
                )
                mood_row.append(summary_el.as_node())
              }
            }
            None => ()
          }

          card.append(mood_row.as_node())
        }
        None => ()
      }
    }
    None => ()
  }

  // Purple accent line - reminiscent of the timeline bars
  let accent = div(
    "absolute left-0 top-3 bottom-3 w-1 rounded-full bg-purple-500 group-hover:bg-purple-400 transition-all duration-200",
    []
  )
  card.append(accent.as_node())

  // Click handler
  on(card, "click", fn(_event) {
    on_open_details(entry.id)
  })

  card
}

///|
/// Count characters in segments
fn count_segment_chars(segments : Array[TimelineSegment]) -> Int {
  let mut total = 0
  for segment in segments {
    match segment.content {
      Some(c) => total = total + c.length()
      None => ()
    }
  }
  total
}
