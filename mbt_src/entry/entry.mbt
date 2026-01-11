///|
/// Entry processing module for timeline application
/// Provides utilities for processing timeline entries and segments

///|
/// Segment data structure representing a timeline segment
pub struct SegmentData {
  id : String
  content : String
  start_time : String
  end_time : String
  node_type : String
  speaker_name : String
}

///|
/// Create a new SegmentData
pub fn SegmentData::new(
  id : String,
  content : String,
  start_time : String,
  end_time : String,
  node_type : String,
  speaker_name : String
) -> SegmentData {
  { id, content, start_time, end_time, node_type, speaker_name }
}

///|
/// Raw log line structure
pub struct RawLogLine {
  text : String
  time_label : String
}

///|
/// Create a new RawLogLine
pub fn RawLogLine::new(text : String, time_label : String) -> RawLogLine {
  { text, time_label }
}

///|
/// Rendered segment with calculated position
pub struct RenderedSegment {
  id : String
  content : String
  start_time : String
  end_time : String
  node_type : String
  speaker_name : String
  left : Double
  width : Double
}

///|
/// Create a new RenderedSegment
pub fn RenderedSegment::new(
  segment : SegmentData,
  left : Double,
  width : Double
) -> RenderedSegment {
  {
    id: segment.id,
    content: segment.content,
    start_time: segment.start_time,
    end_time: segment.end_time,
    node_type: segment.node_type,
    speaker_name: segment.speaker_name,
    left,
    width
  }
}

///|
/// Count characters in a content string
/// Trims whitespace and returns the length
pub fn count_chars(content : String) -> Int {
  // Simple trim implementation
  let trimmed = trim_string(content)
  trimmed.length()
}

///|
/// Simple string trim implementation
pub fn trim_string(s : String) -> String {
  let chars = s.to_array()
  let len = chars.length()

  if len == 0 {
    return ""
  }

  // Find start index (skip leading whitespace)
  let mut start = 0
  while start < len && is_whitespace(chars[start]) {
    start = start + 1
  }

  // Find end index (skip trailing whitespace)
  let mut end = len - 1
  while end >= start && is_whitespace(chars[end]) {
    end = end - 1
  }

  if start > end {
    return ""
  }

  // Build result string
  let mut result = ""
  for i = start; i <= end; i = i + 1 {
    result = result + chars[i].to_string()
  }
  result
}

///|
/// Check if a character is whitespace
fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
/// Generate metric label based on character count, segment count, or duration
pub fn generate_metric_label(
  char_count : Int,
  segment_count : Int,
  duration_minutes : Int
) -> String {
  if char_count > 0 {
    format_number_with_comma(char_count) + "\u6587\u5b57" // 文字
  } else if segment_count > 0 {
    segment_count.to_string() + "\u30bb\u30b0\u30e1\u30f3\u30c8" // セグメント
  } else if duration_minutes > 0 {
    duration_minutes.to_string() + "\u5206" // 分
  } else {
    "\u2014" // em dash
  }
}

///|
/// Format a number with comma separators (e.g., 1000 -> "1,000")
pub fn format_number_with_comma(n : Int) -> String {
  let s = n.to_string()
  let len = s.length()

  if len <= 3 {
    return s
  }

  let chars = s.to_array()
  let mut result = ""
  let mut count = 0

  // Process from right to left
  for i = len - 1; i >= 0; i = i - 1 {
    if count > 0 && count % 3 == 0 {
      result = "," + result
    }
    result = chars[i].to_string() + result
    count = count + 1
  }

  result
}

///|
/// Count total characters across multiple content strings
pub fn count_total_chars(contents : Array[String]) -> Int {
  let mut total = 0
  for i = 0; i < contents.length(); i = i + 1 {
    let trimmed = trim_string(contents[i])
    if trimmed.length() > 0 {
      total = total + trimmed.length()
    }
  }
  total
}

///|
/// Calculate band position for a segment given start/end times
/// Returns (left%, width%)
pub fn calculate_segment_band(
  start_time : String,
  end_time : String,
  entry_start_time : String,
  entry_end_time : String
) -> (Double, Double) {
  // Get time components for start
  let start_components = @date.select_date(start_time, entry_start_time)
  let (_, _, _, start_hour, start_minute, start_second, _) = start_components

  // Get time components for end
  let end_components = @date.select_date(end_time, entry_end_time)
  let (_, _, _, end_hour, end_minute, end_second, _) = end_components

  let minutes_per_day = 24.0 * 60.0

  let start_minutes = start_hour.to_double() * 60.0 +
                     start_minute.to_double() +
                     start_second.to_double() / 60.0

  let end_minutes = end_hour.to_double() * 60.0 +
                   end_minute.to_double() +
                   end_second.to_double() / 60.0

  // Handle case where end is on next day
  let adjusted_end = if end_minutes < start_minutes {
    end_minutes + minutes_per_day
  } else {
    end_minutes
  }

  // Duration is at minimum 0.5 minutes for visibility
  let duration = clamp_double(adjusted_end - start_minutes, 0.5, minutes_per_day)

  let left = clamp_double(start_minutes / minutes_per_day, 0.0, 1.0) * 100.0
  let width = clamp_double(duration / minutes_per_day, 0.01, 1.0) * 100.0

  (left, width)
}

///|
/// Clamp a double value between min and max
fn clamp_double(value : Double, min : Double, max : Double) -> Double {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

///|
/// Check if a segment has valid content
pub fn has_valid_content(content : String) -> Bool {
  let trimmed = trim_string(content)
  trimmed.length() > 0
}

///|
/// Check if band dimensions are valid for rendering
pub fn is_valid_band(left : Double, width : Double) -> Bool {
  width > 0.0 && left >= 0.0 && left <= 100.0
}

///|
/// Create a formatted time label for a log entry
pub fn format_log_time_label(start_time : String) -> String {
  @date.to_locale_time(start_time)
}

///|
/// Entry statistics structure
pub struct EntryStats {
  total_chars : Int
  segment_count : Int
  valid_segment_count : Int
  duration_minutes : Int
}

///|
/// Create new EntryStats
pub fn EntryStats::new(
  total_chars : Int,
  segment_count : Int,
  valid_segment_count : Int,
  duration_minutes : Int
) -> EntryStats {
  { total_chars, segment_count, valid_segment_count, duration_minutes }
}

///|
/// Calculate entry statistics from segment contents
pub fn calculate_entry_stats(
  contents : Array[String],
  duration_minutes : Int
) -> EntryStats {
  let mut total_chars = 0
  let mut valid_count = 0

  for i = 0; i < contents.length(); i = i + 1 {
    let trimmed = trim_string(contents[i])
    if trimmed.length() > 0 {
      total_chars = total_chars + trimmed.length()
      valid_count = valid_count + 1
    }
  }

  EntryStats::new(total_chars, contents.length(), valid_count, duration_minutes)
}

///|
/// Get the metric label from entry stats
pub fn get_metric_label_from_stats(stats : EntryStats) -> String {
  generate_metric_label(stats.total_chars, stats.valid_segment_count, stats.duration_minutes)
}

///|
/// Grouped entry for date grouping
pub struct GroupedEntry {
  date : String
  date_label : String
  entry_count : Int
}

///|
/// Create a new GroupedEntry
pub fn GroupedEntry::new(
  date : String,
  date_label : String,
  entry_count : Int
) -> GroupedEntry {
  { date, date_label, entry_count }
}

///|
/// Get date key for grouping from a start time
pub fn get_group_date_key(start_time : String) -> String {
  @date.get_date_key(start_time)
}

///|
/// Get formatted date label for a start time
pub fn get_group_date_label(start_time : String) -> String {
  @date.format_date_label(start_time)
}
