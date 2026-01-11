///|
/// Main entry point for MoonBit JS module generation
/// Re-exports all public functions from submodules for use from JavaScript

// ============================================================================
// Timeline functions (from @timeline module)
// ============================================================================

///|
/// Clamp a double value between min and max
pub fn clamp(value : Double, min : Double, max : Double) -> Double {
  @timeline.clamp(value, min, max)
}

///|
/// Compute band position for timeline
pub fn compute_band_position(
  start_hour : Int,
  start_minute : Int,
  start_second : Int,
  end_hour : Int,
  end_minute : Int,
  end_second : Int
) -> (Double, Double) {
  @timeline.compute_band_position(
    start_hour,
    start_minute,
    start_second,
    end_hour,
    end_minute,
    end_second,
  )
}

///|
/// Calculate horizontal scroll position
pub fn calculate_horizontal_scroll(
  hour : Int,
  minute : Int,
  scroll_width : Double,
  client_width : Double
) -> Double {
  @timeline.calculate_horizontal_scroll(hour, minute, scroll_width, client_width)
}

///|
/// Format time to HH:MM
pub fn format_time(hour : Int, minute : Int) -> String {
  @timeline.format_time(hour, minute)
}

// ============================================================================
// Date functions (from @date module)
// ============================================================================

///|
/// Format date to "YYYY-MM-DD (曜日)" format
pub fn format_date_label(date_string : String) -> String {
  @date.format_date_label(date_string)
}

///|
/// Format time to "HH:MM" format from date string
pub fn to_locale_time(date_string : String) -> String {
  @date.to_locale_time(date_string)
}

///|
/// Check if date string is valid
pub fn is_valid_date(date_string : String) -> Bool {
  @date.is_valid_date(date_string)
}

///|
/// Get date key for grouping (YYYY-MM-DD)
pub fn get_date_key(date_string : String) -> String {
  @date.get_date_key(date_string)
}

///|
/// Get time components (hour, minute, second)
pub fn get_time_components(date_string : String) -> (Int, Int, Int)? {
  @date.get_time_components(date_string)
}

///|
/// Get date components (year, month, day)
pub fn get_date_components(date_string : String) -> (Int, Int, Int)? {
  @date.get_date_components(date_string)
}

///|
/// Compare two dates
pub fn compare_dates(date_a : String, date_b : String) -> Int {
  @date.compare_dates(date_a, date_b)
}

///|
/// Get day percentage (0-100)
pub fn get_day_percentage(date_string : String) -> Double {
  @date.get_day_percentage(date_string)
}

///|
/// Get minutes difference between two dates
pub fn get_minutes_diff(start : String, end : String) -> Double {
  @date.get_minutes_diff(start, end)
}

///|
/// Select valid date from value or fallback
pub fn select_date(
  value : String,
  fallback : String
) -> (Int, Int, Int, Int, Int, Int, Int) {
  @date.select_date(value, fallback)
}

///|
/// Get percentage from midnight
pub fn percentage_from_midnight(date_string : String) -> Double {
  @date.percentage_from_midnight(date_string)
}

// ============================================================================
// Entry functions (from @entry module)
// ============================================================================

///|
/// Count characters in content
pub fn count_chars(content : String) -> Int {
  @entry.count_chars(content)
}

///|
/// Trim whitespace from string
pub fn trim_string(s : String) -> String {
  @entry.trim_string(s)
}

///|
/// Generate metric label from counts
pub fn generate_metric_label(
  char_count : Int,
  segment_count : Int,
  duration_minutes : Int
) -> String {
  @entry.generate_metric_label(char_count, segment_count, duration_minutes)
}

///|
/// Format number with comma separators
pub fn format_number_with_comma(n : Int) -> String {
  @entry.format_number_with_comma(n)
}

///|
/// Count total characters in array
pub fn count_total_chars(contents : Array[String]) -> Int {
  @entry.count_total_chars(contents)
}

///|
/// Calculate segment band position
pub fn calculate_segment_band(
  start_time : String,
  end_time : String,
  entry_start_time : String,
  entry_end_time : String
) -> (Double, Double) {
  @entry.calculate_segment_band(start_time, end_time, entry_start_time, entry_end_time)
}

///|
/// Check if content is valid
pub fn has_valid_content(content : String) -> Bool {
  @entry.has_valid_content(content)
}

///|
/// Check if band dimensions are valid
pub fn is_valid_band(left : Double, width : Double) -> Bool {
  @entry.is_valid_band(left, width)
}

///|
/// Format log time label
pub fn format_log_time_label(start_time : String) -> String {
  @entry.format_log_time_label(start_time)
}

///|
/// Get group date key
pub fn get_group_date_key(start_time : String) -> String {
  @entry.get_group_date_key(start_time)
}

///|
/// Get group date label
pub fn get_group_date_label(start_time : String) -> String {
  @entry.get_group_date_label(start_time)
}

// ============================================================================
// Utils functions (from @utils module)
// ============================================================================

///|
/// Clamp integer value
pub fn clamp_int(value : Int, min : Int, max : Int) -> Int {
  @utils.clamp_int(value, min, max)
}

///|
/// Pad string on left
pub fn pad_left(s : String, target_length : Int, pad_char : String) -> String {
  @utils.pad_left(s, target_length, pad_char)
}

///|
/// Pad string on right
pub fn pad_right(s : String, target_length : Int, pad_char : String) -> String {
  @utils.pad_right(s, target_length, pad_char)
}

///|
/// Check if string is blank
pub fn is_blank(s : String) -> Bool {
  @utils.is_blank(s)
}

///|
/// Check if string is not blank
pub fn is_not_blank(s : String) -> Bool {
  @utils.is_not_blank(s)
}

///|
/// Truncate string with suffix
pub fn truncate(s : String, max_length : Int, suffix : String) -> String {
  @utils.truncate(s, max_length, suffix)
}

///|
/// Linear interpolation
pub fn lerp(start : Double, end : Double, t : Double) -> Double {
  @utils.lerp(start, end, t)
}

///|
/// Calculate percentage in range
pub fn percentage_in_range(value : Double, min : Double, max : Double) -> Double {
  @utils.percentage_in_range(value, min, max)
}

///|
/// Round to decimal places
pub fn round_to(value : Double, decimals : Int) -> Double {
  @utils.round_to(value, decimals)
}

///|
/// Check if value is in range
pub fn in_range(value : Double, min : Double, max : Double) -> Bool {
  @utils.in_range(value, min, max)
}

///|
/// Get minimum of two doubles
pub fn min_double(a : Double, b : Double) -> Double {
  @utils.min_double(a, b)
}

///|
/// Get maximum of two doubles
pub fn max_double(a : Double, b : Double) -> Double {
  @utils.max_double(a, b)
}

///|
/// Get minimum of two integers
pub fn min_int(a : Int, b : Int) -> Int {
  @utils.min_int(a, b)
}

///|
/// Get maximum of two integers
pub fn max_int(a : Int, b : Int) -> Int {
  @utils.max_int(a, b)
}

///|
/// Get absolute value of double
pub fn abs_double(value : Double) -> Double {
  @utils.abs_double(value)
}

///|
/// Get absolute value of integer
pub fn abs_int(value : Int) -> Int {
  @utils.abs_int(value)
}

///|
/// Check if string starts with prefix
pub fn starts_with(s : String, prefix : String) -> Bool {
  @utils.starts_with(s, prefix)
}

///|
/// Check if string ends with suffix
pub fn ends_with(s : String, suffix : String) -> Bool {
  @utils.ends_with(s, suffix)
}

///|
/// Convert string to uppercase
pub fn to_upper(s : String) -> String {
  @utils.to_upper(s)
}

///|
/// Convert string to lowercase
pub fn to_lower(s : String) -> String {
  @utils.to_lower(s)
}

///|
/// Capitalize first letter
pub fn capitalize(s : String) -> String {
  @utils.capitalize(s)
}

///|
/// Generate hash code for string
pub fn hash_string(s : String) -> Int {
  @utils.hash_string(s)
}

// ============================================================================
// Main function (required for JS module generation)
// ============================================================================

///|
/// Entry point for MoonBit JS module generation
fn main {
  // No-op: Functions are exported via pub declarations
}
