///| HTML renderer compatibility tests

///| Compares output with remark-html

///|
/// Test helper: compare our HTML output with remark-html output
pub fn assert_html_compat(input : String, name : String) -> Unit {
  let our_output = @markdown.md_to_html(input)
  let remark_output = remark_html(input)

  // Normalize trailing whitespace for comparison
  let our_normalized = our_output.trim_end(chars=" \n\t")
  let remark_normalized = remark_output.trim_end(chars=" \n\t")
  if our_normalized != remark_normalized {
    println("=== HTML Test: \{name} ===")
    println("=== Input ===")
    println(input)
    println("=== Our output ===")
    println(our_normalized)
    println("=== Remark-html output ===")
    println(remark_normalized)
    panic()
  }
}

///|
/// Test helper with strict mode
pub fn assert_html_compat_strict(input : String, name : String) -> Unit {
  let our_output = @markdown.md_to_html_strict(input)
  let remark_output = remark_html(input)
  let our_normalized = our_output.trim_end(chars=" \n\t")
  let remark_normalized = remark_output.trim_end(chars=" \n\t")
  if our_normalized != remark_normalized {
    println("=== HTML Test (strict): \{name} ===")
    println("=== Input ===")
    println(input)
    println("=== Our output ===")
    println(our_normalized)
    println("=== Remark-html output ===")
    println(remark_normalized)
    panic()
  }
}
