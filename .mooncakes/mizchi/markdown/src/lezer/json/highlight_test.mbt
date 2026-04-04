///|
/// Tests for syntax highlighting
test "@lezer.HighlightTag::to_class returns correct class names" {
  assert_eq(@lezer.HighlightTag::String.to_class(), "hl-string")
  assert_eq(@lezer.HighlightTag::Number.to_class(), "hl-number")
  assert_eq(@lezer.HighlightTag::PropertyName.to_class(), "hl-property")
  assert_eq(@lezer.HighlightTag::Brace.to_class(), "hl-brace")
  assert_eq(@lezer.HighlightTag::None.to_class(), "")
}

///|
test "highlight_json returns tokens for simple object" {
  let tokens = highlight_json("{\"a\": 1}")
  assert_true(tokens.length() > 0)

  // Should have: brace, property, punctuation, number, brace
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(Brace)) // { and }
  assert_true(tags.contains(PropertyName)) // "a"
  assert_true(tags.contains(Number)) // 1
}

///|
test "highlight_json handles keywords" {
  let tokens = highlight_json("[true, false, null]")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(Bool)) // true, false
  assert_true(tags.contains(Null)) // null
}

///|
test "highlight_json_to_html generates correct HTML" {
  let html = highlight_json_to_html("{\"x\": 1}")

  // Should contain span elements with classes
  assert_true(html.contains("<span class=\"hl-brace\">{</span>"))
  assert_true(html.contains("<span class=\"hl-property\">"))
  assert_true(html.contains("<span class=\"hl-number\">1</span>"))
}

///|
test "tokens_to_html escapes HTML" {
  // Test with content that needs escaping
  let source = "{\"a\": \"<b>\"}"
  let html = highlight_json_to_html(source)

  // Should escape < and >
  assert_true(html.contains("&lt;b&gt;"))
}

///|
test "highlight tokens have correct positions" {
  let source = "{\"ab\": 42}"
  let tokens = highlight_json(source)

  // Find the property name token
  let prop_token = tokens.iter().find_first(fn(t) { t.tag == PropertyName })
  assert_true(prop_token is Some(_))
  let prop = prop_token.unwrap()
  // "ab" should be at positions 1-5
  assert_eq(prop.from, 1)
  assert_eq(prop.to, 5)

  // Find the number token
  let num_token = tokens.iter().find_first(fn(t) { t.tag == Number })
  assert_true(num_token is Some(_))
  let num = num_token.unwrap()
  // 42 should be at positions 7-9
  assert_eq(num.from, 7)
  assert_eq(num.to, 9)
}

///|
test "@lezer.Highlighter::get_tag returns None for unknown nodes" {
  let h = @lezer.Highlighter::new()
  assert_eq(h.get_tag("UnknownNode"), None)
}

///|
test "Highlighter can be customized" {
  let h = @lezer.Highlighter::new()
  h.add_rule("CustomNode", Keyword)
  assert_eq(h.get_tag("CustomNode"), Keyword)
}

///|
test "highlight_json handles nested structures" {
  let source = "{\"obj\": {\"arr\": [1, 2]}}"
  let tokens = highlight_json(source)

  // Should have multiple braces and brackets
  let brace_count = tokens.iter().filter(fn(t) { t.tag == Brace }).count()
  let bracket_count = tokens.iter().filter(fn(t) { t.tag == Bracket }).count()
  assert_true(brace_count >= 4) // { } { }
  assert_true(bracket_count >= 2) // [ ]
}

///|
test "highlight_json handles strings" {
  let source = "{\"key\": \"value\"}"
  let tokens = highlight_json(source)

  // Should have one PropertyName and one String
  let prop_count = tokens.iter().filter(fn(t) { t.tag == PropertyName }).count()
  let string_count = tokens.iter().filter(fn(t) { t.tag == String }).count()
  assert_eq(prop_count, 1) // "key"
  assert_eq(string_count, 1) // "value"
}
