///| Benchmark for validation performance

///|
/// Simple string validation
test "bench_string_validation" (b : @bench.T) {
  let schema = @types.JsonSchema::String(@types.StringSchema::{
    min_length: Some(1),
    max_length: Some(100),
    enum_: None,
    strict_type: Some(true),
  })
  let input : Json = "hello world"
  let resolver = Resolver::empty()
  b.bench(name="string_valid", fn() {
    b.keep(
      Validatable::validate(
        schema,
        input,
        resolver~,
        json_path=@types.JsonPointer::Root,
        schema_path=@types.JsonPointer::Root,
      ),
    )
  })
}

///|
/// Object validation with properties
test "bench_object_validation" (b : @bench.T) {
  let schema = @types.JsonSchema::Object(@types.ObjectSchema::{
    properties: Some({
      "name": @types.JsonSchema::String(@types.StringSchema::{
        min_length: Some(1),
        max_length: None,
        enum_: None,
        strict_type: Some(true),
      }),
      "age": @types.JsonSchema::Integer(@types.IntegerSchema::{
        minimum: Some(0),
        maximum: Some(150),
        exclusive_minimum: None,
        exclusive_maximum: None,
        multiple_of: None,
        strict_type: Some(true),
      }),
    }),
    required: Some(["name"]),
    additional_properties: None,
    strict_type: Some(true),
  })
  let input : Json = { "name": "John", "age": 30 }
  let resolver = Resolver::empty()
  b.bench(name="object_valid", fn() {
    b.keep(
      Validatable::validate(
        schema,
        input,
        resolver~,
        json_path=@types.JsonPointer::Root,
        schema_path=@types.JsonPointer::Root,
      ),
    )
  })
}

///|
/// Array validation
test "bench_array_validation" (b : @bench.T) {
  let schema = @types.JsonSchema::Array(@types.ArraySchema::{
    items: Some(
      @types.JsonSchema::Integer(@types.IntegerSchema::{
        minimum: None,
        maximum: None,
        exclusive_minimum: None,
        exclusive_maximum: None,
        multiple_of: None,
        strict_type: Some(true),
      }),
    ),
    prefix_items: None,
    contains: None,
    min_contains: None,
    max_contains: None,
    min_items: Some(1),
    max_items: Some(100),
    strict_type: Some(true),
  })
  let input : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let resolver = Resolver::empty()
  b.bench(name="array_10_items", fn() {
    b.keep(
      Validatable::validate(
        schema,
        input,
        resolver~,
        json_path=@types.JsonPointer::Root,
        schema_path=@types.JsonPointer::Root,
      ),
    )
  })
}

///|
/// Nested object validation
test "bench_nested_object_validation" (b : @bench.T) {
  let address_schema = @types.JsonSchema::Object(@types.ObjectSchema::{
    properties: Some({
      "street": @types.JsonSchema::String(@types.StringSchema::{
        min_length: None,
        max_length: None,
        enum_: None,
        strict_type: Some(true),
      }),
      "city": @types.JsonSchema::String(@types.StringSchema::{
        min_length: None,
        max_length: None,
        enum_: None,
        strict_type: Some(true),
      }),
    }),
    required: Some(["street", "city"]),
    additional_properties: None,
    strict_type: Some(true),
  })
  let schema = @types.JsonSchema::Object(@types.ObjectSchema::{
    properties: Some({
      "name": @types.JsonSchema::String(@types.StringSchema::{
        min_length: None,
        max_length: None,
        enum_: None,
        strict_type: Some(true),
      }),
      "address": address_schema,
    }),
    required: Some(["name", "address"]),
    additional_properties: None,
    strict_type: Some(true),
  })
  let input : Json = {
    "name": "John",
    "address": { "street": "123 Main St", "city": "Tokyo" },
  }
  let resolver = Resolver::empty()
  b.bench(name="nested_object", fn() {
    b.keep(
      Validatable::validate(
        schema,
        input,
        resolver~,
        json_path=@types.JsonPointer::Root,
        schema_path=@types.JsonPointer::Root,
      ),
    )
  })
}

///|
/// JSON Schema parsing benchmark
test "bench_parse_schema" (b : @bench.T) {
  let raw : Json = {
    "type": "object",
    "properties": {
      "name": { "type": "string", "minLength": 1 },
      "age": { "type": "integer", "minimum": 0 },
    },
    "required": ["name"],
  }
  b.bench(name="parse_object_schema", fn() {
    let schema = @parser.parse_schema(raw) catch { _ => return }
    b.keep(schema)
  })
}

///|
/// Full validation with parsing
test "bench_full_validation" (b : @bench.T) {
  let schema : Json = {
    "type": "object",
    "properties": {
      "name": { "type": "string", "minLength": 1 },
      "age": { "type": "integer", "minimum": 0 },
    },
    "required": ["name"],
  }
  let input : Json = { "name": "John", "age": 30 }
  let validator = build_validator(schema)
  b.bench(name="validate_with_validator", fn() {
    b.keep(validator.validate(input))
  })
}

///|
/// JsonPointer creation overhead
test "bench_jsonpointer_creation" (b : @bench.T) {
  b.bench(name="pointer_depth_5", fn() {
    let path = @types.JsonPointer::Root
      .key("foo")
      .key("bar")
      .index(0)
      .key("baz")
      .index(1)
    b.keep(path)
  })
}

///|
/// Integer type check overhead
test "bench_integer_check" (b : @bench.T) {
  let values : Array[Json] = [1, 2, 3, 42, 100, 999, 12345]
  b.bench(name="integer_check", fn() {
    for v in values {
      match v {
        @json.Number(n, ..) => b.keep(n == n.to_int().to_double())
        _ => ()
      }
    }
  })
}

///|
/// Large array validation (100 items)
test "bench_large_array_validation" (b : @bench.T) {
  let schema = @types.JsonSchema::Array(@types.ArraySchema::{
    items: Some(
      @types.JsonSchema::Integer(@types.IntegerSchema::{
        minimum: None,
        maximum: None,
        exclusive_minimum: None,
        exclusive_maximum: None,
        multiple_of: None,
        strict_type: Some(true),
      }),
    ),
    prefix_items: None,
    contains: None,
    min_contains: None,
    max_contains: None,
    min_items: None,
    max_items: None,
    strict_type: Some(true),
  })
  // Create array with 100 integers using JSON parse
  let input : Json = @json.parse(
    "[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99]",
  ) catch {
    _ => return
  }
  let resolver = Resolver::empty()
  b.bench(name="array_100_items", fn() {
    b.keep(
      Validatable::validate(
        schema,
        input,
        resolver~,
        json_path=@types.JsonPointer::Root,
        schema_path=@types.JsonPointer::Root,
      ),
    )
  })
}

///|
/// AnyOf validation - first schema matches
test "bench_anyof_first_match" (b : @bench.T) {
  let schema = @types.JsonSchema::AnyOf(@types.AnyOfSchema::{
    schemas: [
      @types.JsonSchema::String(@types.StringSchema::{
        min_length: None,
        max_length: None,
        enum_: None,
        strict_type: Some(true),
      }),
      @types.JsonSchema::Integer(@types.IntegerSchema::{
        minimum: None,
        maximum: None,
        exclusive_minimum: None,
        exclusive_maximum: None,
        multiple_of: None,
        strict_type: Some(true),
      }),
      @types.JsonSchema::Boolean(@types.BooleanSchema::{  }),
      @types.JsonSchema::Null(@types.NullSchema::{  }),
    ],
  })
  let input : Json = "hello" // matches first schema
  let resolver = Resolver::empty()
  b.bench(name="anyof_first", fn() {
    b.keep(
      Validatable::validate(
        schema,
        input,
        resolver~,
        json_path=@types.JsonPointer::Root,
        schema_path=@types.JsonPointer::Root,
      ),
    )
  })
}

///|
/// AnyOf validation - last schema matches
test "bench_anyof_last_match" (b : @bench.T) {
  let schema = @types.JsonSchema::AnyOf(@types.AnyOfSchema::{
    schemas: [
      @types.JsonSchema::String(@types.StringSchema::{
        min_length: None,
        max_length: None,
        enum_: None,
        strict_type: Some(true),
      }),
      @types.JsonSchema::Integer(@types.IntegerSchema::{
        minimum: None,
        maximum: None,
        exclusive_minimum: None,
        exclusive_maximum: None,
        multiple_of: None,
        strict_type: Some(true),
      }),
      @types.JsonSchema::Boolean(@types.BooleanSchema::{  }),
      @types.JsonSchema::Null(@types.NullSchema::{  }),
    ],
  })
  let obj : Json = { "v": Null }
  let input : Json = match obj {
    @json.Object(m) =>
      match m.get("v") {
        Some(v) => v
        None => return
      }
    _ => return
  }
  let resolver = Resolver::empty()
  b.bench(name="anyof_last", fn() {
    b.keep(
      Validatable::validate(
        schema,
        input,
        resolver~,
        json_path=@types.JsonPointer::Root,
        schema_path=@types.JsonPointer::Root,
      ),
    )
  })
}

///|
/// Deeply nested object validation
test "bench_deep_nested_validation" (b : @bench.T) {
  // Create nested schema: { a: { b: { c: { d: string } } } }
  let d_schema = @types.JsonSchema::Object(@types.ObjectSchema::{
    properties: Some({
      "d": @types.JsonSchema::String(@types.StringSchema::{
        min_length: None,
        max_length: None,
        enum_: None,
        strict_type: Some(true),
      }),
    }),
    required: Some(["d"]),
    additional_properties: None,
    strict_type: Some(true),
  })
  let c_schema = @types.JsonSchema::Object(@types.ObjectSchema::{
    properties: Some({ "c": d_schema }),
    required: Some(["c"]),
    additional_properties: None,
    strict_type: Some(true),
  })
  let b_schema = @types.JsonSchema::Object(@types.ObjectSchema::{
    properties: Some({ "b": c_schema }),
    required: Some(["b"]),
    additional_properties: None,
    strict_type: Some(true),
  })
  let schema = @types.JsonSchema::Object(@types.ObjectSchema::{
    properties: Some({ "a": b_schema }),
    required: Some(["a"]),
    additional_properties: None,
    strict_type: Some(true),
  })
  let input : Json = { "a": { "b": { "c": { "d": "value" } } } }
  let resolver = Resolver::empty()
  b.bench(name="nested_depth_4", fn() {
    b.keep(
      Validatable::validate(
        schema,
        input,
        resolver~,
        json_path=@types.JsonPointer::Root,
        schema_path=@types.JsonPointer::Root,
      ),
    )
  })
}
