///|
/// Block-level HTML rendering tests
test "html: fenced code block" {
  assert_html_compat("```js\nconsole.log('hi');\n```\n", "fenced code block")
}

///|
test "html: fenced code block no lang" {
  assert_html_compat("```\ncode\n```\n", "fenced code block no lang")
}

///|
test "html: blockquote" {
  assert_html_compat("> quote\n", "blockquote")
}

///|
test "html: blockquote multiline" {
  assert_html_compat("> line 1\n> line 2\n", "blockquote multiline")
}

///|
test "html: bullet list" {
  assert_html_compat("- one\n- two\n- three\n", "bullet list")
}

///|
test "html: ordered list" {
  assert_html_compat("1. one\n2. two\n3. three\n", "ordered list")
}

///|
test "html: ordered list start" {
  assert_html_compat("5. five\n6. six\n", "ordered list start")
}
