///| JSON-specific syntax highlighting

// =============================================================================
// JSON Highlighter
// =============================================================================

///|
/// Create a highlighter configured for JSON
pub fn json_highlighter() -> @lezer.Highlighter {
  let h = @lezer.Highlighter::new()

  // Structural tokens
  h.add_rule("BraceOpen", Brace)
  h.add_rule("BraceClose", Brace)
  h.add_rule("BracketOpen", Bracket)
  h.add_rule("BracketClose", Bracket)
  h.add_rule("Colon", Punctuation)
  h.add_rule("Comma", Punctuation)

  // Values
  h.add_rule("String", String)
  h.add_rule("Number", Number)
  h.add_rule("True", Bool)
  h.add_rule("False", Bool)
  h.add_rule("Null", Null)

  // Property names (different from regular strings)
  h.add_rule("PropertyName", PropertyName)
  h
}

///|
/// Highlight JSON source code
pub fn highlight_json(source : String) -> Array[@lezer.HighlightToken] {
  match parse_json(source) {
    Some(tree) => {
      let highlighter = json_highlighter()
      highlighter.highlight(tree)
    }
    None => []
  }
}

///|
/// Convenience: highlight JSON and generate HTML
pub fn highlight_json_to_html(source : String) -> String {
  let tokens = highlight_json(source)
  @lezer.tokens_to_html(source, tokens)
}
