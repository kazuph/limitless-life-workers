# @mizchi/jsonschema

```
$ moon add mizchi/jsonschema
```

## Features

- JSON Schema validation with `$ref` support
- Schema builder (valibot-style API)
- MoonBit code generation from JSON Schema

## Package Structure

```
mizchi/jsonschema/
  types/     # Schema type definitions
  parser/    # JSON Schema parser (opt-in)
  validate/  # Validation implementation
  codegen/   # Code generation
  exports/   # Main exports for JS
```

## Usage

### Schema Builder (Recommended)

```moonbit
let schema = object_schema(
  properties=Some({
    "name": string_schema(min_length=Some(1)),
    "age": integer_schema(minimum=Some(0)),
  }),
  required=Some(["name"]),
)

let result = validate_schema(schema, { "name": "John", "age": 30 })
```

### JSON Schema Parsing

```moonbit
let raw : Json = {
  "type": "object",
  "properties": {
    "name": { "type": "string" },
    "age": { "type": "integer" }
  },
  "required": ["name"]
}

let validator = build_validator(raw)
let result = validator.validate({ "name": "John", "age": 30 })
```

## Supported Features

- [x] type: any, null, boolean, string, number, integer, array, object
- [x] String: minLength, maxLength, enum
- [x] Number/Integer: minimum, maximum, exclusiveMinimum, exclusiveMaximum, multipleOf
- [x] Array: items, minItems, maxItems, prefixItems
- [x] Object: properties, required, additionalProperties
- [x] Combinators: anyOf, allOf, oneOf
- [x] `$ref` with JSON Pointer (`#/definitions/Foo`)
- [x] const, enum
- [x] Multiple types: `{ "type": ["string", "null"] }`

## Performance

### Recommended Target

**wasm-gc** is the recommended target for best performance.

### Benchmark Results (wasm-gc)

| Operation | Time |
|-----------|------|
| String validation | 0.01 µs |
| Object validation (2 props) | 0.08 µs |
| Array validation (10 items) | 0.14 µs |
| Nested object (depth 2) | 0.17 µs |
| Full validation with pre-built schema | 0.14 µs |
| JSON Schema parsing | 1.25 µs |

### Performance Tips

1. **Use Schema Builder** - Pre-built schemas skip parsing overhead (~10x faster)

```moonbit
// Fast: schema is pre-built
let schema = object_schema(properties=Some({ "name": string_schema() }))
let result = validate_schema(schema, input)

// Slower: requires parsing JSON Schema
let validator = build_validator({ "type": "object", ... })
```

2. **Reuse Validators** - Build once, validate many times

```moonbit
let validator = build_validator(schema_json)  // Build once
for input in inputs {
  validator.validate(input)  // Reuse
}
```

3. **Use wasm-gc target** - 2-7x faster than other targets

## Known Limitations

- **patternProperties**: Not implemented
- **Grapheme cluster counting**: `minLength`/`maxLength` count UTF-16 code units, not Unicode grapheme clusters

## LICENSE

MIT
