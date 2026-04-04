///|
/// Edge case HTML tests
test "html: empty paragraph" {
  assert_html_compat("\n\n", "empty paragraph")
}

///|
test "html: multiple blank lines" {
  assert_html_compat("text\n\n\n\nmore text\n", "multiple blank lines")
}

///|
test "html: heading with trailing hashes" {
  assert_html_compat("# heading #\n", "heading with trailing hashes")
}

///|
test "html: atx heading with closing" {
  assert_html_compat("## Heading ##\n", "atx heading with closing")
}

///|
test "html: thematic break asterisks" {
  assert_html_compat("***\n", "thematic break asterisks")
}

///|
test "html: thematic break underscores" {
  assert_html_compat("___\n", "thematic break underscores")
}

///|
test "html: fenced code tildes" {
  assert_html_compat("~~~\ncode\n~~~\n", "fenced code tildes")
}

///|
test "html: list tight" {
  assert_html_compat("- a\n- b\n- c\n", "list tight")
}

///|
test "html: list with blank line" {
  assert_html_compat("- item 1\n\n- item 2\n", "list with blank line")
}

///|
test "html: ordered list different markers" {
  assert_html_compat("1) first\n2) second\n", "ordered list different markers")
}
