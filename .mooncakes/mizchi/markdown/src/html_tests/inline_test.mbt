///|
/// Inline element HTML tests
test "html: soft break" {
  assert_html_compat("line one\nline two\n", "soft break")
}

///|
test "html: multiple emphasis" {
  assert_html_compat("*one* and *two* and *three*\n", "multiple emphasis")
}

///|
test "html: multiple strong" {
  assert_html_compat("**one** and **two**\n", "multiple strong")
}

///|
test "html: code simple" {
  assert_html_compat("`hello world`\n", "code simple")
}

///|
test "html: link without title" {
  assert_html_compat("[text](url)\n", "link without title")
}

///|
test "html: image with title" {
  assert_html_compat("![alt](url \"title\")\n", "image with title")
}

///|
test "html: autolink url" {
  assert_html_compat("<https://example.com>\n", "autolink url")
}

///|
test "html: autolink email" {
  assert_html_compat("<test@example.com>\n", "autolink email")
}

///|
test "html: inline code backticks" {
  assert_html_compat("`` `code` ``\n", "inline code backticks")
}

///|
test "html: escaped characters" {
  assert_html_compat("\\*not emphasis\\*\n", "escaped characters")
}
