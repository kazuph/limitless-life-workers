///|
/// Tests for JSON parser

// =============================================================================
// Tokenizer Tests
// =============================================================================

test "JsonTokenizer tokenizes simple object" {
  let tokenizer = JsonTokenizer::new("{\"a\": 1}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 5)
  assert_eq(tokens[0].node_type, BraceOpen)
  assert_eq(tokens[1].node_type, String)
  assert_eq(tokens[2].node_type, Colon)
  assert_eq(tokens[3].node_type, Number)
  assert_eq(tokens[4].node_type, BraceClose)
}

///|
test "JsonTokenizer tokenizes array" {
  let tokenizer = JsonTokenizer::new("[1, 2, 3]")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 7)
  assert_eq(tokens[0].node_type, BracketOpen)
  assert_eq(tokens[1].node_type, Number)
  assert_eq(tokens[2].node_type, Comma)
  assert_eq(tokens[3].node_type, Number)
  assert_eq(tokens[4].node_type, Comma)
  assert_eq(tokens[5].node_type, Number)
  assert_eq(tokens[6].node_type, BracketClose)
}

///|
test "JsonTokenizer tokenizes keywords" {
  let tokenizer = JsonTokenizer::new("[true, false, null]")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 7)
  assert_eq(tokens[1].node_type, True)
  assert_eq(tokens[3].node_type, False)
  assert_eq(tokens[5].node_type, Null)
}

///|
test "JsonTokenizer tokenizes numbers" {
  let tokenizer = JsonTokenizer::new("[123, -45, 3.14, 1e10]")
  let tokens = tokenizer.tokenize_all()

  // Check all numbers are recognized
  assert_eq(tokens[1].node_type, Number)
  assert_eq(tokens[3].node_type, Number)
  assert_eq(tokens[5].node_type, Number)
  assert_eq(tokens[7].node_type, Number)
}

///|
test "JsonTokenizer tokenizes strings with escapes" {
  let tokenizer = JsonTokenizer::new("[\"hello\", \"with\\\"quote\"]")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[1].node_type, String)
  assert_eq(tokens[3].node_type, String)
}

// =============================================================================
// Parser Tests
// =============================================================================

///|
test "parse_json parses simple value" {
  let tree = parse_json("123")
  assert_true(tree is Some(_))
  let doc = tree.unwrap()
  assert_eq(doc.node_type().unwrap().name, "JsonDocument")
}

///|
test "parse_json parses object" {
  let tree = parse_json("{\"name\": \"test\"}")
  assert_true(tree is Some(_))
  let doc = tree.unwrap()
  assert_eq(doc.node_type().unwrap().name, "JsonDocument")

  // First child should be Object
  let children = doc.children()
  assert_eq(children.length(), 1)
  assert_eq(children[0].node_type().unwrap().name, "Object")
}

///|
test "parse_json parses nested structure" {
  let tree = parse_json("{\"arr\": [1, 2]}")
  assert_true(tree is Some(_))
  let doc = tree.unwrap()
  let obj = doc.children()[0]
  assert_eq(obj.node_type().unwrap().name, "Object")

  // Object should have children: { Property }
  let obj_children = obj.children()
  // Should include: BraceOpen, Property, BraceClose
  assert_true(obj_children.length() >= 3)
}

///|
test "parse_json parses array" {
  let tree = parse_json("[1, true, null]")
  assert_true(tree is Some(_))
  let doc = tree.unwrap()
  let arr = doc.children()[0]
  assert_eq(arr.node_type().unwrap().name, "Array")
}

// =============================================================================
// Tree Traversal Tests
// =============================================================================

///|
test "TreeCursor traverses JSON tree" {
  let tree = parse_json("{\"a\": 1}")
  assert_true(tree is Some(_))
  let cursor = @lezer.TreeCursor::new(tree.unwrap())
  assert_eq(cursor.name(), "JsonDocument")

  // Navigate to Object
  assert_true(cursor.first_child())
  assert_eq(cursor.name(), "Object")

  // Navigate to first child of Object (BraceOpen)
  assert_true(cursor.first_child())
  assert_eq(cursor.name(), "BraceOpen")

  // Navigate to Property
  assert_true(cursor.next_sibling())
  assert_eq(cursor.name(), "Property")
}

///|
test "Tree::resolve finds node at position" {
  let input = "{\"a\": 123}"
  let tree = parse_json(input)
  assert_true(tree is Some(_))
  let doc = tree.unwrap()

  // Position 1 should be in the property name "a"
  let node = doc.resolve(2) // inside "a"
  assert_true(node is Some(_))
  // Should resolve to something inside the object
}

///|
test "Tree::iter visits all nodes" {
  let tree = parse_json("{\"x\": 1}")
  assert_true(tree is Some(_))
  let names : Array[String] = []
  for node in tree.unwrap().iter() {
    match node.node_type() {
      Some(t) => names.push(t.name)
      None => ()
    }
  }

  // Should have: JsonDocument, Object, BraceOpen, Property, PropertyName, Colon, Number, BraceClose
  assert_true(names.length() >= 5)
  assert_true(names.contains("JsonDocument"))
  assert_true(names.contains("Object"))
  assert_true(names.contains("PropertyName"))
  assert_true(names.contains("Number"))
}

// =============================================================================
// Position Tracking Tests
// =============================================================================

///|
test "tokens have correct positions" {
  let input = "{\"ab\": 42}"
  let tokenizer = JsonTokenizer::new(input)
  let tokens = tokenizer.tokenize_all()

  // { is at position 0
  assert_eq(tokens[0].from, 0)
  assert_eq(tokens[0].to, 1)

  // "ab" is at positions 1-5
  assert_eq(tokens[1].from, 1)
  assert_eq(tokens[1].to, 5)

  // : is at position 5
  assert_eq(tokens[2].from, 5)
  assert_eq(tokens[2].to, 6)

  // 42 is at positions 7-9
  assert_eq(tokens[3].from, 7)
  assert_eq(tokens[3].to, 9)

  // } is at position 9
  assert_eq(tokens[4].from, 9)
  assert_eq(tokens[4].to, 10)
}

///|
test "parsed tree has correct spans" {
  let input = "{\"ab\": 42}"
  let tree = parse_json(input)
  assert_true(tree is Some(_))
  let doc = tree.unwrap()
  assert_eq(doc.from(), 0)
  assert_eq(doc.to(), 10)
  let obj = doc.children()[0]
  assert_eq(obj.from(), 0)
  assert_eq(obj.to(), 10)
}

// =============================================================================
// Edge Cases - Empty Structures
// =============================================================================

///|
test "parse_json handles empty object" {
  let tree = parse_json("{}")
  assert_true(tree is Some(_))
  let doc = tree.unwrap()
  let obj = doc.children()[0]
  assert_eq(obj.node_type().unwrap().name, "Object")

  // Should have BraceOpen and BraceClose
  let children = obj.children()
  assert_eq(children.length(), 2)
  assert_eq(children[0].node_type().unwrap().name, "BraceOpen")
  assert_eq(children[1].node_type().unwrap().name, "BraceClose")
}

///|
test "parse_json handles empty array" {
  let tree = parse_json("[]")
  assert_true(tree is Some(_))
  let doc = tree.unwrap()
  let arr = doc.children()[0]
  assert_eq(arr.node_type().unwrap().name, "Array")
  let children = arr.children()
  assert_eq(children.length(), 2)
  assert_eq(children[0].node_type().unwrap().name, "BracketOpen")
  assert_eq(children[1].node_type().unwrap().name, "BracketClose")
}

///|
test "parse_json handles nested arrays" {
  let tree = parse_json("[[1, 2], [3]]")
  assert_true(tree is Some(_))
  let doc = tree.unwrap()
  let arr = doc.children()[0]
  assert_eq(arr.node_type().unwrap().name, "Array")

  // Count nested arrays
  let mut nested_count = 0
  for node in arr.iter() {
    match node.node_type() {
      Some(t) if t.name == "Array" => nested_count += 1
      _ => ()
    }
  }
  // Should have 3 arrays: outer + 2 inner
  assert_eq(nested_count, 3)
}

///|
test "parse_json handles deeply nested structure" {
  let tree = parse_json("{\"a\": {\"b\": {\"c\": 1}}}")
  assert_true(tree is Some(_))

  // Count objects
  let mut obj_count = 0
  for node in tree.unwrap().iter() {
    match node.node_type() {
      Some(t) if t.name == "Object" => obj_count += 1
      _ => ()
    }
  }
  assert_eq(obj_count, 3)
}

// =============================================================================
// Edge Cases - Numbers
// =============================================================================

///|
test "JsonTokenizer handles zero" {
  let tokenizer = JsonTokenizer::new("0")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].node_type, Number)
  assert_eq(tokens[0].from, 0)
  assert_eq(tokens[0].to, 1)
}

///|
test "JsonTokenizer handles negative decimal" {
  let tokenizer = JsonTokenizer::new("-3.14159")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].node_type, Number)
}

///|
test "JsonTokenizer handles exponent variations" {
  // Test various exponent formats
  let inputs = ["1e10", "1E10", "1e+10", "1e-10", "1.5e10"]
  for input in inputs {
    let tokenizer = JsonTokenizer::new(input)
    let tokens = tokenizer.tokenize_all()
    assert_eq(tokens.length(), 1)
    assert_eq(tokens[0].node_type, Number)
  }
}

// =============================================================================
// Edge Cases - Strings
// =============================================================================

///|
test "JsonTokenizer handles empty string" {
  let tokenizer = JsonTokenizer::new("\"\"")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].node_type, String)
  assert_eq(tokens[0].from, 0)
  assert_eq(tokens[0].to, 2)
}

///|
test "JsonTokenizer handles escape sequences" {
  let tokenizer = JsonTokenizer::new("\"\\n\\t\\r\\\\\"")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].node_type, String)
}

///|
test "JsonTokenizer handles unicode escape" {
  let tokenizer = JsonTokenizer::new("\"\\u0041\"")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].node_type, String)
}

// =============================================================================
// Edge Cases - Whitespace
// =============================================================================

///|
test "JsonTokenizer skips various whitespace" {
  let tokenizer = JsonTokenizer::new("  \t\n\r  123  \t\n  ")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].node_type, Number)
}

///|
test "parse_json handles multiline input" {
  let input =
    #|{
    #|  "name": "test",
    #|  "value": 42
    #|}
  let tree = parse_json(input)
  assert_true(tree is Some(_))
  let doc = tree.unwrap()
  let obj = doc.children()[0]
  assert_eq(obj.node_type().unwrap().name, "Object")
}

// =============================================================================
// Multiple Properties
// =============================================================================

///|
test "parse_json handles multiple properties" {
  let tree = parse_json("{\"a\": 1, \"b\": 2, \"c\": 3}")
  assert_true(tree is Some(_))

  // Count properties
  let mut prop_count = 0
  for node in tree.unwrap().iter() {
    match node.node_type() {
      Some(t) if t.name == "Property" => prop_count += 1
      _ => ()
    }
  }
  assert_eq(prop_count, 3)
}

///|
test "parse_json handles mixed value types" {
  let tree = parse_json(
    "{\"str\": \"hello\", \"num\": 42, \"bool\": true, \"nil\": null}",
  )
  assert_true(tree is Some(_))
  let names : Array[String] = []
  for node in tree.unwrap().iter() {
    match node.node_type() {
      Some(t) => names.push(t.name)
      _ => ()
    }
  }
  assert_true(names.contains("String"))
  assert_true(names.contains("Number"))
  assert_true(names.contains("True"))
  assert_true(names.contains("Null"))
}

// =============================================================================
// TreeCursor Advanced Tests
// =============================================================================

///|
test "TreeCursor full traversal" {
  let tree = parse_json("{\"a\": [1, 2]}")
  assert_true(tree is Some(_))
  let cursor = @lezer.TreeCursor::new(tree.unwrap())
  let visited : Array[String] = []

  // Depth-first traversal using cursor
  fn traverse(cursor : @lezer.TreeCursor, visited : Array[String]) -> Unit {
    visited.push(cursor.name())
    if cursor.first_child() {
      traverse(cursor, visited)
      while cursor.next_sibling() {
        traverse(cursor, visited)
      }
      let _ = cursor.parent()

    }
  }

  traverse(cursor, visited)

  // Should visit all nodes
  assert_true(visited.contains("JsonDocument"))
  assert_true(visited.contains("Object"))
  assert_true(visited.contains("Array"))
  assert_true(visited.contains("Number"))
}

///|
test "TreeCursor depth tracking" {
  let tree = parse_json("{\"a\": {\"b\": 1}}")
  assert_true(tree is Some(_))
  let cursor = @lezer.TreeCursor::new(tree.unwrap())

  // Root depth = 0
  assert_eq(cursor.depth(), 0)

  // Go to Object
  assert_true(cursor.first_child())
  assert_eq(cursor.depth(), 1)

  // Go to BraceOpen
  assert_true(cursor.first_child())
  assert_eq(cursor.depth(), 2)

  // Back to Object
  assert_true(cursor.parent())
  assert_eq(cursor.depth(), 1)

  // Back to root
  assert_true(cursor.parent())
  assert_eq(cursor.depth(), 0)
}

// =============================================================================
// Error Handling
// =============================================================================

///|
test "JsonTokenizer handles invalid characters" {
  let tokenizer = JsonTokenizer::new("@#$")
  let tokens = tokenizer.tokenize_all()

  // Each invalid char should produce an Error token
  assert_eq(tokens.length(), 3)
  for token in tokens {
    assert_eq(token.node_type, Error)
  }
}

///|
test "parse_json returns None for empty input" {
  let tree = parse_json("")
  assert_true(tree is None)
}

///|
test "parse_json handles trailing content gracefully" {
  // Parser should parse the first valid value
  let tree = parse_json("123 456")
  assert_true(tree is Some(_))
  let doc = tree.unwrap()
  // Should have parsed at least the first number
  assert_eq(doc.node_type().unwrap().name, "JsonDocument")
}
