///|
/// Date processing module for timeline application
/// Provides date formatting and manipulation utilities

///|
/// Japanese weekday names
fn get_weekday_ja(day_index : Int) -> String {
  match day_index {
    0 => "日"
    1 => "月"
    2 => "火"
    3 => "水"
    4 => "木"
    5 => "金"
    6 => "土"
    _ => "?"
  }
}

///|
/// Pad a number with leading zeros to a specified length
pub fn pad_start(value : Int, length : Int) -> String {
  let s = value.to_string()
  let pad_count = length - s.length()
  if pad_count <= 0 {
    s
  } else {
    let mut result = ""
    for i = 0; i < pad_count; i = i + 1 {
      result = result + "0"
    }
    result + s
  }
}

///|
/// Maximum valid date range in milliseconds (roughly +/- 270,000 years)
let max_date_ms : Int = 2147483647 // Use Int max for safety

///|
/// Minimum valid date range in milliseconds
let min_date_ms : Int = -2147483647

///|
/// Check if a Date timestamp is valid (not NaN and within reasonable range)
pub fn is_valid_timestamp(timestamp : Int) -> Bool {
  // Check for reasonable date range (Int range is smaller than JS Date range)
  timestamp > min_date_ms && timestamp < max_date_ms
}

///|
/// Parse a date string and return components (year, month, day, hour, minute, second, day_of_week)
/// Returns None if the date string is invalid
pub fn parse_date_string(date_string : String) -> (Int, Int, Int, Int, Int, Int, Int)? {
  let d = @jsdate.Date::from_string(date_string)
  let timestamp = d.get_time()

  // Check for valid date - simple check for non-zero (invalid dates often return NaN which becomes 0)
  if timestamp == 0 && date_string.length() > 0 {
    // Additional validation: try to get year - if it fails, date is invalid
    let year = d.get_full_year()
    if year < 1900 || year > 2100 {
      return None
    }
  }

  Some((
    d.get_full_year(),
    d.get_month() + 1, // JS months are 0-indexed
    d.get_date(),
    d.get_hours(),
    d.get_minutes(),
    d.get_seconds(),
    d.get_day()
  ))
}

///|
/// Format a date string to "YYYY-MM-DD (曜日)" format
/// Returns "Unknown date" if the input is invalid
pub fn format_date_label(date_string : String) -> String {
  match parse_date_string(date_string) {
    Some((year, month, day, _, _, _, day_of_week)) => {
      let year_str = year.to_string()
      let month_str = pad_start(month, 2)
      let day_str = pad_start(day, 2)
      let weekday = get_weekday_ja(day_of_week)
      year_str + "-" + month_str + "-" + day_str + " (" + weekday + ")"
    }
    None => "Unknown date"
  }
}

///|
/// Format a date string to "HH:MM" format
/// Returns "--:--" if the input is invalid
pub fn to_locale_time(date_string : String) -> String {
  match parse_date_string(date_string) {
    Some((_, _, _, hour, minute, _, _)) => {
      let h = pad_start(hour, 2)
      let m = pad_start(minute, 2)
      h + ":" + m
    }
    None => "--:--"
  }
}

///|
/// Get the start of day (midnight) for a given date string
/// Returns the date components with time set to 00:00:00
pub fn get_start_of_day(date_string : String) -> (Int, Int, Int, Int, Int, Int)? {
  match parse_date_string(date_string) {
    Some((year, month, day, _, _, _, _)) => {
      Some((year, month - 1, day, 0, 0, 0)) // month back to 0-indexed for JS
    }
    None => None
  }
}

///|
/// Calculate the difference in minutes between two dates
/// Returns the difference as a Double
pub fn get_minutes_diff(
  start_date_string : String,
  end_date_string : String
) -> Double {
  let start = @jsdate.Date::from_string(start_date_string)
  let end = @jsdate.Date::from_string(end_date_string)

  let start_time = start.get_time()
  let end_time = end.get_time()

  let diff_ms = end_time - start_time
  diff_ms.to_double() / 60000.0 // Convert milliseconds to minutes
}

///|
/// Calculate percentage of the day for a given time
/// Returns value between 0.0 and 100.0
pub fn get_day_percentage(date_string : String) -> Double {
  match parse_date_string(date_string) {
    Some((_, _, _, hour, minute, second, _)) => {
      let total_minutes = 24.0 * 60.0
      let current_minutes = hour.to_double() * 60.0 +
                           minute.to_double() +
                           second.to_double() / 60.0
      (current_minutes / total_minutes) * 100.0
    }
    None => 0.0
  }
}

///|
/// Check if a date string is valid
pub fn is_valid_date(date_string : String) -> Bool {
  match parse_date_string(date_string) {
    Some(_) => true
    None => false
  }
}

///|
/// Extract date components from a date string
/// Returns (year, month, day) or None if invalid
pub fn get_date_components(date_string : String) -> (Int, Int, Int)? {
  match parse_date_string(date_string) {
    Some((year, month, day, _, _, _, _)) => Some((year, month, day))
    None => None
  }
}

///|
/// Extract time components from a date string
/// Returns (hour, minute, second) or None if invalid
pub fn get_time_components(date_string : String) -> (Int, Int, Int)? {
  match parse_date_string(date_string) {
    Some((_, _, _, hour, minute, second, _)) => Some((hour, minute, second))
    None => None
  }
}

///|
/// Compare two date strings and return ordering
/// Returns -1 if a < b, 0 if a == b, 1 if a > b
pub fn compare_dates(date_a : String, date_b : String) -> Int {
  let a = @jsdate.Date::from_string(date_a)
  let b = @jsdate.Date::from_string(date_b)

  let time_a = a.get_time()
  let time_b = b.get_time()

  if time_a < time_b {
    -1
  } else if time_a > time_b {
    1
  } else {
    0
  }
}

///|
/// Get a unique date key for grouping (YYYY-MM-DD format)
pub fn get_date_key(date_string : String) -> String {
  match parse_date_string(date_string) {
    Some((year, month, day, _, _, _, _)) => {
      let year_str = year.to_string()
      let month_str = pad_start(month, 2)
      let day_str = pad_start(day, 2)
      year_str + "-" + month_str + "-" + day_str
    }
    None => "unknown"
  }
}

///|
/// Select a valid date from value or fallback
/// Returns the parsed date components or current time if both are invalid
pub fn select_date(
  value : String,
  fallback : String
) -> (Int, Int, Int, Int, Int, Int, Int) {
  match parse_date_string(value) {
    Some(components) => components
    None => {
      match parse_date_string(fallback) {
        Some(components) => components
        None => {
          // Return current time as fallback
          let now = @jsdate.Date::new()
          (
            now.get_full_year(),
            now.get_month() + 1,
            now.get_date(),
            now.get_hours(),
            now.get_minutes(),
            now.get_seconds(),
            now.get_day()
          )
        }
      }
    }
  }
}

///|
/// Calculate time percentage within a day (0-100)
pub fn calculate_time_percentage(hour : Int, minute : Int, second : Int) -> Double {
  let total_seconds = 24.0 * 60.0 * 60.0
  let current_seconds = hour.to_double() * 3600.0 +
                       minute.to_double() * 60.0 +
                       second.to_double()
  (current_seconds / total_seconds) * 100.0
}

///|
/// Get the timestamp in milliseconds for a date string
pub fn get_timestamp(date_string : String) -> Int {
  let d = @jsdate.Date::from_string(date_string)
  d.get_time()
}

///|
/// Create a midnight timestamp for a given date string
pub fn get_midnight_timestamp(date_string : String) -> Int {
  match parse_date_string(date_string) {
    Some((year, month, day, _, _, _, _)) => {
      let midnight = @jsdate.Date::from_ymdhms(year, month - 1, day, 0, 0, 0)
      midnight.get_time()
    }
    None => 0
  }
}

///|
/// Calculate the percentage of time elapsed since midnight
pub fn percentage_from_midnight(date_string : String) -> Double {
  let d = @jsdate.Date::from_string(date_string)
  let timestamp = d.get_time()

  // Get midnight of the same day
  let midnight = @jsdate.Date::from_ymdhms(
    d.get_full_year(),
    d.get_month(),
    d.get_date(),
    0, 0, 0
  )

  let diff_ms = timestamp - midnight.get_time()
  let total_day_ms = 24.0 * 60.0 * 60.0 * 1000.0

  (diff_ms.to_double() / total_day_ms) * 100.0
}
