///| Combined formatting HTML tests

///|
/// Note: Some tests use strict mode for proper nested emphasis handling
test "html: multiple paragraphs" {
  assert_html_compat(
    "First paragraph.\n\nSecond paragraph.\n", "multiple paragraphs",
  )
}

///|
test "html: heading with inline" {
  assert_html_compat("# Title with **bold**\n", "heading with inline")
}

///|
test "html: list with inline" {
  assert_html_compat(
    "- item with *emphasis*\n- item with `code`\n", "list with inline",
  )
}

///|
test "html: blockquote with inline" {
  assert_html_compat(
    "> quote with **bold** and *italic*\n", "blockquote with inline",
  )
}

///|
test "html: link with emphasis" {
  assert_html_compat(
    "[*emphasized link*](https://example.com)\n", "link with emphasis",
  )
}

///|
test "html: code block with info" {
  assert_html_compat(
    "```javascript\nconst x = 1;\n```\n", "code block with info",
  )
}

///|
test "html: nested blockquote" {
  assert_html_compat("> outer\n> > inner\n", "nested blockquote")
}
