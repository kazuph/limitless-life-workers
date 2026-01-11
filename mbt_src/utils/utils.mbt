///|
/// Utility functions for the timeline application
/// Provides common helper functions

///|
/// Clamp a double value between min and max
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
/// Clamp an integer value between min and max
pub fn clamp_int(value : Int, min : Int, max : Int) -> Int {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

///|
/// Linear interpolation between two values
pub fn lerp(start : Double, end : Double, t : Double) -> Double {
  start + (end - start) * clamp(t, 0.0, 1.0)
}

///|
/// Calculate percentage of value within a range
pub fn percentage_in_range(value : Double, min : Double, max : Double) -> Double {
  if max <= min {
    0.0
  } else {
    clamp((value - min) / (max - min), 0.0, 1.0) * 100.0
  }
}

///|
/// Round a double to specified decimal places
pub fn round_to(value : Double, decimals : Int) -> Double {
  let multiplier = pow10(decimals)
  (value * multiplier).round() / multiplier
}

///|
/// Calculate power of 10
fn pow10(n : Int) -> Double {
  let mut result = 1.0
  let mut i = 0
  while i < n {
    result = result * 10.0
    i = i + 1
  }
  result
}

///|
/// Check if a value is within a range (inclusive)
pub fn in_range(value : Double, min : Double, max : Double) -> Bool {
  value >= min && value <= max
}

///|
/// Check if an integer is within a range (inclusive)
pub fn in_range_int(value : Int, min : Int, max : Int) -> Bool {
  value >= min && value <= max
}

///|
/// Get the minimum of two doubles
pub fn min_double(a : Double, b : Double) -> Double {
  if a < b { a } else { b }
}

///|
/// Get the maximum of two doubles
pub fn max_double(a : Double, b : Double) -> Double {
  if a > b { a } else { b }
}

///|
/// Get the minimum of two integers
pub fn min_int(a : Int, b : Int) -> Int {
  if a < b { a } else { b }
}

///|
/// Get the maximum of two integers
pub fn max_int(a : Int, b : Int) -> Int {
  if a > b { a } else { b }
}

///|
/// Normalize a value from one range to another
pub fn normalize_range(
  value : Double,
  from_min : Double,
  from_max : Double,
  to_min : Double,
  to_max : Double
) -> Double {
  let percentage = percentage_in_range(value, from_min, from_max) / 100.0
  lerp(to_min, to_max, percentage)
}

///|
/// Calculate the absolute value of a double
pub fn abs_double(value : Double) -> Double {
  if value < 0.0 { -value } else { value }
}

///|
/// Calculate the absolute value of an integer
pub fn abs_int(value : Int) -> Int {
  if value < 0 { -value } else { value }
}

///|
/// Sign function: returns -1, 0, or 1
pub fn sign_double(value : Double) -> Int {
  if value < 0.0 {
    -1
  } else if value > 0.0 {
    1
  } else {
    0
  }
}

///|
/// Sign function for integers: returns -1, 0, or 1
pub fn sign_int(value : Int) -> Int {
  if value < 0 {
    -1
  } else if value > 0 {
    1
  } else {
    0
  }
}

///|
/// Floor division for doubles
pub fn floor_div(value : Double, divisor : Double) -> Double {
  if divisor == 0.0 {
    0.0
  } else {
    (value / divisor).floor()
  }
}

///|
/// Modulo for doubles (always positive result)
pub fn mod_double(value : Double, divisor : Double) -> Double {
  if divisor == 0.0 {
    0.0
  } else {
    let result = value - floor_div(value, divisor) * divisor
    if result < 0.0 { result + abs_double(divisor) } else { result }
  }
}

///|
/// Check if two doubles are approximately equal
pub fn approx_equal(a : Double, b : Double, epsilon : Double) -> Bool {
  abs_double(a - b) < epsilon
}

///|
/// Check if a double is approximately zero
pub fn is_zero(value : Double, epsilon : Double) -> Bool {
  abs_double(value) < epsilon
}

///|
/// Default epsilon for floating point comparisons
pub let default_epsilon : Double = 0.000001

///|
/// Pad a string on the left to reach target length
pub fn pad_left(s : String, target_length : Int, pad_char : String) -> String {
  let current_length = s.length()
  if current_length >= target_length {
    s
  } else {
    let mut result = s
    let mut i = current_length
    while i < target_length {
      result = pad_char + result
      i = i + 1
    }
    result
  }
}

///|
/// Pad a string on the right to reach target length
pub fn pad_right(s : String, target_length : Int, pad_char : String) -> String {
  let current_length = s.length()
  if current_length >= target_length {
    s
  } else {
    let mut result = s
    let mut i = current_length
    while i < target_length {
      result = result + pad_char
      i = i + 1
    }
    result
  }
}

///|
/// Check if a string is empty or contains only whitespace
pub fn is_blank(s : String) -> Bool {
  let chars = s.to_array()
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    if not(c == ' ' || c == '\t' || c == '\n' || c == '\r') {
      return false
    }
  }
  true
}

///|
/// Check if a string is not empty and contains non-whitespace characters
pub fn is_not_blank(s : String) -> Bool {
  not(is_blank(s))
}

///|
/// Truncate a string to a maximum length with ellipsis
pub fn truncate(s : String, max_length : Int, suffix : String) -> String {
  if s.length() <= max_length {
    s
  } else {
    let truncate_at = max_length - suffix.length()
    if truncate_at <= 0 {
      suffix
    } else {
      let chars = s.to_array()
      let mut result = ""
      for i = 0; i < truncate_at; i = i + 1 {
        result = result + chars[i].to_string()
      }
      result + suffix
    }
  }
}

///|
/// Repeat a string n times
pub fn repeat(s : String, n : Int) -> String {
  if n <= 0 {
    ""
  } else {
    let mut result = ""
    for i = 0; i < n; i = i + 1 {
      result = result + s
    }
    result
  }
}

///|
/// Count occurrences of a substring in a string
pub fn count_occurrences(s : String, sub : String) -> Int {
  if sub.length() == 0 || sub.length() > s.length() {
    return 0
  }

  let s_chars = s.to_array()
  let sub_chars = sub.to_array()
  let s_len = s_chars.length()
  let sub_len = sub_chars.length()

  let mut count = 0
  let mut i = 0

  while i <= s_len - sub_len {
    let mut match_found = true
    for j = 0; j < sub_len; j = j + 1 {
      if s_chars[i + j] != sub_chars[j] {
        match_found = false
        break
      }
    }
    if match_found {
      count = count + 1
      i = i + sub_len // Non-overlapping count
    } else {
      i = i + 1
    }
  }
  count
}

///|
/// Check if a string starts with a prefix
pub fn starts_with(s : String, prefix : String) -> Bool {
  if prefix.length() > s.length() {
    return false
  }

  let s_chars = s.to_array()
  let prefix_chars = prefix.to_array()

  for i = 0; i < prefix_chars.length(); i = i + 1 {
    if s_chars[i] != prefix_chars[i] {
      return false
    }
  }
  true
}

///|
/// Check if a string ends with a suffix
pub fn ends_with(s : String, suffix : String) -> Bool {
  if suffix.length() > s.length() {
    return false
  }

  let s_chars = s.to_array()
  let suffix_chars = suffix.to_array()
  let offset = s_chars.length() - suffix_chars.length()

  for i = 0; i < suffix_chars.length(); i = i + 1 {
    if s_chars[offset + i] != suffix_chars[i] {
      return false
    }
  }
  true
}

///|
/// Convert a string to uppercase (ASCII only)
pub fn to_upper(s : String) -> String {
  let chars = s.to_array()
  let mut result = ""
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    let code = c.to_int()
    if code >= 97 && code <= 122 { // a-z
      result = result + (code - 32).unsafe_to_char().to_string()
    } else {
      result = result + c.to_string()
    }
  }
  result
}

///|
/// Convert a string to lowercase (ASCII only)
pub fn to_lower(s : String) -> String {
  let chars = s.to_array()
  let mut result = ""
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    let code = c.to_int()
    if code >= 65 && code <= 90 { // A-Z
      result = result + (code + 32).unsafe_to_char().to_string()
    } else {
      result = result + c.to_string()
    }
  }
  result
}

///|
/// Capitalize the first letter of a string
pub fn capitalize(s : String) -> String {
  if s.length() == 0 {
    return s
  }

  let chars = s.to_array()
  let first = chars[0]
  let code = first.to_int()

  let mut result = ""
  if code >= 97 && code <= 122 {
    result = (code - 32).unsafe_to_char().to_string()
  } else {
    result = first.to_string()
  }

  for i = 1; i < chars.length(); i = i + 1 {
    result = result + chars[i].to_string()
  }
  result
}

///|
/// Generate a simple hash code for a string
pub fn hash_string(s : String) -> Int {
  let chars = s.to_array()
  let mut hash = 0
  for i = 0; i < chars.length(); i = i + 1 {
    hash = 31 * hash + chars[i].to_int()
  }
  hash
}
