///|
/// Clamp a value between min and max
pub fn clamp(value : Double, min : Double, max : Double) -> Double {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

///|
/// Calculate the percentage of minutes from midnight
/// Returns minutes elapsed since midnight
pub fn calculate_minutes_from_midnight(
  hour : Int,
  minute : Int,
  second : Int
) -> Double {
  hour.to_double() * 60.0 + minute.to_double() + second.to_double() / 60.0
}

///|
/// Compute the left position and width for a timeline band
/// Returns (left%, width%)
pub fn compute_band_position(
  start_hour : Int,
  start_minute : Int,
  start_second : Int,
  end_hour : Int,
  end_minute : Int,
  end_second : Int
) -> (Double, Double) {
  let minutes_per_day = 24.0 * 60.0

  let start_minutes = calculate_minutes_from_midnight(
    start_hour,
    start_minute,
    start_second,
  )
  let end_minutes = calculate_minutes_from_midnight(
    end_hour,
    end_minute,
    end_second,
  )

  // Handle case where end is on next day
  let adjusted_end = if end_minutes < start_minutes {
    end_minutes + minutes_per_day
  } else {
    end_minutes
  }

  // Duration is at minimum 0.5 minutes for visibility
  let duration = clamp(adjusted_end - start_minutes, 0.5, minutes_per_day)

  let left = clamp(start_minutes / minutes_per_day, 0.0, 1.0) * 100.0
  let width = clamp(duration / minutes_per_day, 0.01, 1.0) * 100.0

  (left, width)
}

///|
/// Calculate horizontal scroll position for centering an entry in the viewport
/// Returns the optimal scroll position
pub fn calculate_horizontal_scroll(
  hour : Int,
  minute : Int,
  scroll_width : Double,
  client_width : Double
) -> Double {
  let total_minutes_in_day = 24.0 * 60.0
  let time_in_minutes = hour.to_double() * 60.0 + minute.to_double()
  let time_percentage = time_in_minutes / total_minutes_in_day

  let max_scroll = scroll_width - client_width
  let target_scroll = time_percentage * scroll_width - client_width / 2.0

  clamp(target_scroll, 0.0, max_scroll)
}

///|
/// Format a time value to HH:MM format
pub fn format_time(hour : Int, minute : Int) -> String {
  let h = if hour < 10 { "0" + hour.to_string() } else { hour.to_string() }
  let m = if minute < 10 {
    "0" + minute.to_string()
  } else {
    minute.to_string()
  }
  h + ":" + m
}
