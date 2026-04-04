///|
/// Basic HTML rendering tests - comparing with remark-html
test "html: paragraph" {
  assert_html_compat("Hello, world!\n", "paragraph")
}

///|
test "html: heading h1" {
  assert_html_compat("# Title\n", "heading h1")
}

///|
test "html: heading h2" {
  assert_html_compat("## Subtitle\n", "heading h2")
}

///|
test "html: heading h3-h6" {
  assert_html_compat("### H3\n#### H4\n##### H5\n###### H6\n", "heading h3-h6")
}

///|
test "html: emphasis" {
  assert_html_compat("*italic* text\n", "emphasis")
}

///|
test "html: strong" {
  assert_html_compat("**bold** text\n", "strong")
}

///|
test "html: code span" {
  assert_html_compat("Use `code` here\n", "code span")
}

///|
test "html: link" {
  assert_html_compat("[click](https://example.com)\n", "link")
}

///|
test "html: link with title" {
  assert_html_compat(
    "[click](https://example.com \"title\")\n", "link with title",
  )
}

///|
test "html: image" {
  assert_html_compat("![alt](image.png)\n", "image")
}

///|
test "html: thematic break" {
  assert_html_compat("---\n", "thematic break")
}
