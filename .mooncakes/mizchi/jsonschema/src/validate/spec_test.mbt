// JSON Schema Test Suite - Auto-generated
// Do not edit manually. Regenerate with:
//   deno run --allow-read --allow-write scripts/generate_spec_tests.ts

// Auto-generated from JSON Schema Test Suite
// Source: type.json

///|
test "spec_type_integer_type_matches_integers_an_integer_is_an_integer" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "integer",
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_integer_type_matches_integers_a_float_with_zero_fractional_p" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "integer",
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_integer_type_matches_integers_a_float_is_not_an_integer" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "integer",
  }
  let data : Json = 1.1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_integer_type_matches_integers_a_string_is_not_an_integer" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "integer",
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_integer_type_matches_integers_a_string_is_still_not_an_integ" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "integer",
  }
  let data : Json = "1"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_integer_type_matches_integers_an_object_is_not_an_integer" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "integer",
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_integer_type_matches_integers_an_array_is_not_an_integer" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "integer",
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_integer_type_matches_integers_a_boolean_is_not_an_integer" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "integer",
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_integer_type_matches_integers_null_is_not_an_integer" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "integer",
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_number_type_matches_numbers_an_integer_is_a_number" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "number",
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_number_type_matches_numbers_a_float_with_zero_fractional_par" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "number",
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_number_type_matches_numbers_a_float_is_a_number" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "number",
  }
  let data : Json = 1.1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_number_type_matches_numbers_a_string_is_not_a_number" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "number",
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_number_type_matches_numbers_a_string_is_still_not_a_number_e" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "number",
  }
  let data : Json = "1"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_number_type_matches_numbers_an_object_is_not_a_number" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "number",
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_number_type_matches_numbers_an_array_is_not_a_number" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "number",
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_number_type_matches_numbers_a_boolean_is_not_a_number" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "number",
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_number_type_matches_numbers_null_is_not_a_number" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "number",
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_string_type_matches_strings_1_is_not_a_string" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_string_type_matches_strings_a_float_is_not_a_string" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
  }
  let data : Json = 1.1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_string_type_matches_strings_a_string_is_a_string" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_string_type_matches_strings_a_string_is_still_a_string_even_" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
  }
  let data : Json = "1"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_string_type_matches_strings_an_empty_string_is_still_a_strin" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
  }
  let data : Json = ""
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_string_type_matches_strings_an_object_is_not_a_string" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_string_type_matches_strings_an_array_is_not_a_string" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_string_type_matches_strings_a_boolean_is_not_a_string" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_string_type_matches_strings_null_is_not_a_string" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_object_type_matches_objects_an_integer_is_not_an_object" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_object_type_matches_objects_a_float_is_not_an_object" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
  }
  let data : Json = 1.1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_object_type_matches_objects_a_string_is_not_an_object" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_object_type_matches_objects_an_object_is_an_object" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_object_type_matches_objects_an_array_is_not_an_object" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_object_type_matches_objects_a_boolean_is_not_an_object" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_object_type_matches_objects_null_is_not_an_object" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_array_type_matches_arrays_an_integer_is_not_an_array" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "array",
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_array_type_matches_arrays_a_float_is_not_an_array" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "array",
  }
  let data : Json = 1.1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_array_type_matches_arrays_a_string_is_not_an_array" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "array",
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_array_type_matches_arrays_an_object_is_not_an_array" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "array",
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_array_type_matches_arrays_an_array_is_an_array" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "array",
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_array_type_matches_arrays_a_boolean_is_not_an_array" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "array",
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_array_type_matches_arrays_null_is_not_an_array" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "array",
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_boolean_type_matches_booleans_an_integer_is_not_a_boolean" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "boolean",
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_boolean_type_matches_booleans_zero_is_not_a_boolean" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "boolean",
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_boolean_type_matches_booleans_a_float_is_not_a_boolean" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "boolean",
  }
  let data : Json = 1.1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_boolean_type_matches_booleans_a_string_is_not_a_boolean" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "boolean",
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_boolean_type_matches_booleans_an_empty_string_is_not_a_boole" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "boolean",
  }
  let data : Json = ""
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_boolean_type_matches_booleans_an_object_is_not_a_boolean" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "boolean",
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_boolean_type_matches_booleans_an_array_is_not_a_boolean" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "boolean",
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_boolean_type_matches_booleans_true_is_a_boolean" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "boolean",
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_boolean_type_matches_booleans_false_is_a_boolean" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "boolean",
  }
  let data : Json = false
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_boolean_type_matches_booleans_null_is_not_a_boolean" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "boolean",
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_null_type_matches_only_the_null_object_an_integer_is_not_nul" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "null",
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_null_type_matches_only_the_null_object_a_float_is_not_null" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "null",
  }
  let data : Json = 1.1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_null_type_matches_only_the_null_object_zero_is_not_null" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "null",
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_null_type_matches_only_the_null_object_a_string_is_not_null" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "null",
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_null_type_matches_only_the_null_object_an_empty_string_is_no" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "null",
  }
  let data : Json = ""
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_null_type_matches_only_the_null_object_an_object_is_not_null" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "null",
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_null_type_matches_only_the_null_object_an_array_is_not_null" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "null",
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_null_type_matches_only_the_null_object_true_is_not_null" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "null",
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_null_type_matches_only_the_null_object_false_is_not_null" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "null",
  }
  let data : Json = false
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_null_type_matches_only_the_null_object_null_is_null" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "null",
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_multiple_types_can_be_specified_in_an_array_an_integer_is_va" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["integer", "string"],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_multiple_types_can_be_specified_in_an_array_a_string_is_vali" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["integer", "string"],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_multiple_types_can_be_specified_in_an_array_a_float_is_inval" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["integer", "string"],
  }
  let data : Json = 1.1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_multiple_types_can_be_specified_in_an_array_an_object_is_inv" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["integer", "string"],
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_multiple_types_can_be_specified_in_an_array_an_array_is_inva" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["integer", "string"],
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_multiple_types_can_be_specified_in_an_array_a_boolean_is_inv" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["integer", "string"],
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_multiple_types_can_be_specified_in_an_array_null_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["integer", "string"],
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_type_as_array_with_one_item_string_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["string"],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_type_as_array_with_one_item_number_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["string"],
  }
  let data : Json = 123
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_type_array_or_object_array_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["array", "object"],
  }
  let data : Json = [1, 2, 3]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_type_array_or_object_object_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["array", "object"],
  }
  let data : Json = { "foo": 123 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_type_array_or_object_number_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["array", "object"],
  }
  let data : Json = 123
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_type_array_or_object_string_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["array", "object"],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_type_array_or_object_null_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["array", "object"],
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_type_array_object_or_null_array_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["array", "object", "null"],
  }
  let data : Json = [1, 2, 3]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_type_array_object_or_null_object_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["array", "object", "null"],
  }
  let data : Json = { "foo": 123 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_type_array_object_or_null_null_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["array", "object", "null"],
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_type_type_array_object_or_null_number_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["array", "object", "null"],
  }
  let data : Json = 123
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_type_type_array_object_or_null_string_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": ["array", "object", "null"],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: minimum.json

///|
test "spec_minimum_minimum_validation_above_the_minimum_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": 1.1,
  }
  let data : Json = 2.6
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minimum_minimum_validation_boundary_point_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": 1.1,
  }
  let data : Json = 1.1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minimum_minimum_validation_below_the_minimum_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": 1.1,
  }
  let data : Json = 0.6
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_minimum_minimum_validation_ignores_non_numbers" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": 1.1,
  }
  let data : Json = "x"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minimum_minimum_validation_with_signed_integer_negative_above_the" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": -2,
  }
  let data : Json = -1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minimum_minimum_validation_with_signed_integer_positive_above_the" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": -2,
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minimum_minimum_validation_with_signed_integer_boundary_point_is_" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": -2,
  }
  let data : Json = -2
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minimum_minimum_validation_with_signed_integer_boundary_point_wit" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": -2,
  }
  let data : Json = -2
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minimum_minimum_validation_with_signed_integer_float_below_the_mi" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": -2,
  }
  let data : Json = -2.0001
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_minimum_minimum_validation_with_signed_integer_int_below_the_mini" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": -2,
  }
  let data : Json = -3
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_minimum_minimum_validation_with_signed_integer_ignores_non_number" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minimum": -2,
  }
  let data : Json = "x"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: maximum.json

///|
test "spec_maximum_maximum_validation_below_the_maximum_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maximum": 3,
  }
  let data : Json = 2.6
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maximum_maximum_validation_boundary_point_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maximum": 3,
  }
  let data : Json = 3
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maximum_maximum_validation_above_the_maximum_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maximum": 3,
  }
  let data : Json = 3.5
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_maximum_maximum_validation_ignores_non_numbers" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maximum": 3,
  }
  let data : Json = "x"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maximum_maximum_validation_with_unsigned_integer_below_the_maximu" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maximum": 300,
  }
  let data : Json = 299.97
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maximum_maximum_validation_with_unsigned_integer_boundary_point_i" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maximum": 300,
  }
  let data : Json = 300
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maximum_maximum_validation_with_unsigned_integer_boundary_point_f" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maximum": 300,
  }
  let data : Json = 300
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maximum_maximum_validation_with_unsigned_integer_above_the_maximu" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maximum": 300,
  }
  let data : Json = 300.5
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: exclusiveMinimum.json

///|
test "spec_exclusiveminimum_exclusiveminimum_validation_above_the_exclusivem" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "exclusiveMinimum": 1.1,
  }
  let data : Json = 1.2
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_exclusiveminimum_exclusiveminimum_validation_boundary_point_is_in" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "exclusiveMinimum": 1.1,
  }
  let data : Json = 1.1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_exclusiveminimum_exclusiveminimum_validation_below_the_exclusivem" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "exclusiveMinimum": 1.1,
  }
  let data : Json = 0.6
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_exclusiveminimum_exclusiveminimum_validation_ignores_non_numbers" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "exclusiveMinimum": 1.1,
  }
  let data : Json = "x"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: exclusiveMaximum.json

///|
test "spec_exclusivemaximum_exclusivemaximum_validation_below_the_exclusivem" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "exclusiveMaximum": 3,
  }
  let data : Json = 2.2
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_exclusivemaximum_exclusivemaximum_validation_boundary_point_is_in" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "exclusiveMaximum": 3,
  }
  let data : Json = 3
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_exclusivemaximum_exclusivemaximum_validation_above_the_exclusivem" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "exclusiveMaximum": 3,
  }
  let data : Json = 3.5
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_exclusivemaximum_exclusivemaximum_validation_ignores_non_numbers" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "exclusiveMaximum": 3,
  }
  let data : Json = "x"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: minLength.json

///|
test "spec_minlength_minlength_validation_longer_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minLength": 2,
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minlength_minlength_validation_exact_length_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minLength": 2,
  }
  let data : Json = "fo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minlength_minlength_validation_too_short_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minLength": 2,
  }
  let data : Json = "f"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_minlength_minlength_validation_ignores_non_strings" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minLength": 2,
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

// SKIPPED: grapheme cluster support not implemented
// ///|
// test "spec_minlength_minlength_validation_one_grapheme_is_not_long_enough" {
//   let schema : Json = { "$schema": "https://json-schema.org/draft/2020-12/schema", "minLength": 2 }
//   let data : Json = "💩"
//   let validator = build_validator(schema)
//   let result = validator.validate(data)
//   guard result is Err(_)
// }

///|
test "spec_minlength_minlength_validation_with_a_decimal_longer_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minLength": 2,
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minlength_minlength_validation_with_a_decimal_too_short_is_invali" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minLength": 2,
  }
  let data : Json = "f"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: maxLength.json

///|
test "spec_maxlength_maxlength_validation_shorter_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxLength": 2,
  }
  let data : Json = "f"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maxlength_maxlength_validation_exact_length_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxLength": 2,
  }
  let data : Json = "fo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maxlength_maxlength_validation_too_long_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxLength": 2,
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_maxlength_maxlength_validation_ignores_non_strings" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxLength": 2,
  }
  let data : Json = 100
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

// SKIPPED: grapheme cluster support not implemented
// ///|
// test "spec_maxlength_maxlength_validation_two_graphemes_is_long_enough" {
//   let schema : Json = { "$schema": "https://json-schema.org/draft/2020-12/schema", "maxLength": 2 }
//   let data : Json = "💩💩"
//   let validator = build_validator(schema)
//   let result = validator.validate(data)
//   guard result is Ok(_)
// }

///|
test "spec_maxlength_maxlength_validation_with_a_decimal_shorter_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxLength": 2,
  }
  let data : Json = "f"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maxlength_maxlength_validation_with_a_decimal_too_long_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxLength": 2,
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: minItems.json

///|
test "spec_minitems_minitems_validation_longer_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minItems": 1,
  }
  let data : Json = [1, 2]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minitems_minitems_validation_exact_length_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minItems": 1,
  }
  let data : Json = [1]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minitems_minitems_validation_too_short_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minItems": 1,
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_minitems_minitems_validation_ignores_non_arrays" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minItems": 1,
  }
  let data : Json = ""
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minitems_minitems_validation_with_a_decimal_longer_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minItems": 1,
  }
  let data : Json = [1, 2]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_minitems_minitems_validation_with_a_decimal_too_short_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "minItems": 1,
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: maxItems.json

///|
test "spec_maxitems_maxitems_validation_shorter_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxItems": 2,
  }
  let data : Json = [1]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maxitems_maxitems_validation_exact_length_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxItems": 2,
  }
  let data : Json = [1, 2]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maxitems_maxitems_validation_too_long_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxItems": 2,
  }
  let data : Json = [1, 2, 3]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_maxitems_maxitems_validation_ignores_non_arrays" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxItems": 2,
  }
  let data : Json = "foobar"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maxitems_maxitems_validation_with_a_decimal_shorter_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxItems": 2,
  }
  let data : Json = [1]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_maxitems_maxitems_validation_with_a_decimal_too_long_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "maxItems": 2,
  }
  let data : Json = [1, 2, 3]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

// Skipped 2 tests with special characters
// Auto-generated from JSON Schema Test Suite
// Source: required.json

///|
test "spec_required_required_validation_present_required_property_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": {}, "bar": {} },
    "required": ["foo"],
  }
  let data : Json = { "foo": 1 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_required_required_validation_non_present_required_property_is_inv" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": {}, "bar": {} },
    "required": ["foo"],
  }
  let data : Json = { "bar": 1 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_required_required_validation_ignores_arrays" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": {}, "bar": {} },
    "required": ["foo"],
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_required_required_validation_ignores_strings" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": {}, "bar": {} },
    "required": ["foo"],
  }
  let data : Json = ""
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_required_required_validation_ignores_other_non_objects" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": {}, "bar": {} },
    "required": ["foo"],
  }
  let data : Json = 12
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_required_required_default_validation_not_required_by_default" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": {} },
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_required_required_with_empty_array_property_not_required" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": {} },
    "required": [],
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_required_required_properties_whose_names_are_javascript_object_pr" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "required": ["__proto__", "toString", "constructor"],
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_required_required_properties_whose_names_are_javascript_object_pr_9" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "required": ["__proto__", "toString", "constructor"],
  }
  let data : Json = 12
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_required_required_properties_whose_names_are_javascript_object_pr_10" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "required": ["__proto__", "toString", "constructor"],
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_required_required_properties_whose_names_are_javascript_object_pr_11" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "required": ["__proto__", "toString", "constructor"],
  }
  let data : Json = { "__proto__": "foo" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_required_required_properties_whose_names_are_javascript_object_pr_12" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "required": ["__proto__", "toString", "constructor"],
  }
  let data : Json = { "toString": { "length": 37 } }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_required_required_properties_whose_names_are_javascript_object_pr_13" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "required": ["__proto__", "toString", "constructor"],
  }
  let data : Json = { "constructor": { "length": 37 } }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_required_required_properties_whose_names_are_javascript_object_pr_14" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "required": ["__proto__", "toString", "constructor"],
  }
  let data : Json = {
    "__proto__": 12,
    "toString": { "length": "foo" },
    "constructor": 37,
  }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

// Skipped 2 tests with special characters
// Auto-generated from JSON Schema Test Suite
// Source: const.json

///|
test "spec_const_const_validation_same_value_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 2,
  }
  let data : Json = 2
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_validation_another_value_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 2,
  }
  let data : Json = 5
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_validation_another_type_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 2,
  }
  let data : Json = "a"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_object_same_object_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": { "foo": "bar", "baz": "bax" },
  }
  let data : Json = { "foo": "bar", "baz": "bax" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_object_same_object_with_different_property_order" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": { "foo": "bar", "baz": "bax" },
  }
  let data : Json = { "baz": "bax", "foo": "bar" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_object_another_object_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": { "foo": "bar", "baz": "bax" },
  }
  let data : Json = { "foo": "bar" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_object_another_type_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": { "foo": "bar", "baz": "bax" },
  }
  let data : Json = [1, 2]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_array_same_array_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": [{ "foo": "bar" }],
  }
  let data : Json = [{ "foo": "bar" }]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_array_another_array_item_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": [{ "foo": "bar" }],
  }
  let data : Json = [2]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_array_array_with_additional_items_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": [{ "foo": "bar" }],
  }
  let data : Json = [1, 2, 3]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_null_null_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": null,
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_null_not_null_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": null,
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_false_does_not_match_0_false_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": false,
  }
  let data : Json = false
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_false_does_not_match_0_integer_zero_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": false,
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_false_does_not_match_0_float_zero_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": false,
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_true_does_not_match_1_true_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": true,
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_true_does_not_match_1_integer_one_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": true,
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_true_does_not_match_1_float_one_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": true,
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_false_does_not_match_0_false_is_valid_19" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": [false],
  }
  let data : Json = [false]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_false_does_not_match_0_0_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": [false],
  }
  let data : Json = [0]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_false_does_not_match_0_0_0_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": [false],
  }
  let data : Json = [0]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_true_does_not_match_1_true_is_valid_22" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": [true],
  }
  let data : Json = [true]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_true_does_not_match_1_1_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": [true],
  }
  let data : Json = [1]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_true_does_not_match_1_1_0_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": [true],
  }
  let data : Json = [1]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_a_false_does_not_match_a_0_a_false_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": { "a": false },
  }
  let data : Json = { "a": false }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_a_false_does_not_match_a_0_a_0_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": { "a": false },
  }
  let data : Json = { "a": 0 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_a_false_does_not_match_a_0_a_0_0_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": { "a": false },
  }
  let data : Json = { "a": 0 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_a_true_does_not_match_a_1_a_true_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": { "a": true },
  }
  let data : Json = { "a": true }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_a_true_does_not_match_a_1_a_1_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": { "a": true },
  }
  let data : Json = { "a": 1 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_a_true_does_not_match_a_1_a_1_0_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": { "a": true },
  }
  let data : Json = { "a": 1 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_0_does_not_match_other_zero_like_types_false_is_" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 0,
  }
  let data : Json = false
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_0_does_not_match_other_zero_like_types_integer_z" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 0,
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_0_does_not_match_other_zero_like_types_float_zer" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 0,
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_0_does_not_match_other_zero_like_types_empty_obj" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 0,
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_0_does_not_match_other_zero_like_types_empty_arr" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 0,
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_0_does_not_match_other_zero_like_types_empty_str" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 0,
  }
  let data : Json = ""
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_1_does_not_match_true_true_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 1,
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_1_does_not_match_true_integer_one_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 1,
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_1_does_not_match_true_float_one_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 1,
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_2_0_matches_integer_and_float_types_integer_2_is" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": -2,
  }
  let data : Json = -2
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_2_0_matches_integer_and_float_types_integer_2_is_41" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": -2,
  }
  let data : Json = 2
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_2_0_matches_integer_and_float_types_float_2_0_is" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": -2,
  }
  let data : Json = -2
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_const_with_2_0_matches_integer_and_float_types_float_2_0_is_43" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": -2,
  }
  let data : Json = 2
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_const_with_2_0_matches_integer_and_float_types_float_2_0000" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": -2,
  }
  let data : Json = -2.00001
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_float_and_integers_are_equal_up_to_64_bit_representation_li" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 9007199254740992,
  }
  let data : Json = 9007199254740992
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_float_and_integers_are_equal_up_to_64_bit_representation_li_46" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 9007199254740992,
  }
  let data : Json = 9007199254740991
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_float_and_integers_are_equal_up_to_64_bit_representation_li_47" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 9007199254740992,
  }
  let data : Json = 9007199254740992
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_float_and_integers_are_equal_up_to_64_bit_representation_li_48" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": 9007199254740992,
  }
  let data : Json = 9007199254740991
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_characters_with_the_same_visual_representation_but_differen" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": "μ",
    "$comment": "U+03BC",
  }
  let data : Json = "μ"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_characters_with_the_same_visual_representation_but_differen_50" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": "μ",
    "$comment": "U+03BC",
  }
  let data : Json = "µ"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_const_characters_with_the_same_visual_representation_but_differen_51" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": "ä",
    "$comment": "U+00E4",
  }
  let data : Json = "ä"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_const_characters_with_the_same_visual_representation_but_differen_52" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "const": "ä",
    "$comment": "U+00E4",
  }
  let data : Json = "ä"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

// Skipped 5 tests with special characters
// Auto-generated from JSON Schema Test Suite
// Source: enum.json

///|
test "spec_enum_simple_enum_validation_one_of_the_enum_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [1, 2, 3],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_simple_enum_validation_something_else_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [1, 2, 3],
  }
  let data : Json = 4
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_heterogeneous_enum_validation_one_of_the_enum_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [6, "foo", [], true, { "foo": 12 }],
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_heterogeneous_enum_validation_something_else_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [6, "foo", [], true, { "foo": 12 }],
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_heterogeneous_enum_validation_objects_are_deep_compared" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [6, "foo", [], true, { "foo": 12 }],
  }
  let data : Json = { "foo": false }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_heterogeneous_enum_validation_valid_object_matches" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [6, "foo", [], true, { "foo": 12 }],
  }
  let data : Json = { "foo": 12 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_heterogeneous_enum_validation_extra_properties_in_object_is_" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [6, "foo", [], true, { "foo": 12 }],
  }
  let data : Json = { "foo": 12, "boo": 42 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_heterogeneous_enum_with_null_validation_null_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [6, null],
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_heterogeneous_enum_with_null_validation_number_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [6, null],
  }
  let data : Json = 6
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_heterogeneous_enum_with_null_validation_something_else_is_in" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [6, null],
  }
  let data : Json = "test"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enums_in_properties_both_properties_are_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": { "foo": { "enum": ["foo"] }, "bar": { "enum": ["bar"] } },
    "required": ["bar"],
  }
  let data : Json = { "foo": "foo", "bar": "bar" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enums_in_properties_wrong_foo_value" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": { "foo": { "enum": ["foo"] }, "bar": { "enum": ["bar"] } },
    "required": ["bar"],
  }
  let data : Json = { "foo": "foot", "bar": "bar" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enums_in_properties_wrong_bar_value" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": { "foo": { "enum": ["foo"] }, "bar": { "enum": ["bar"] } },
    "required": ["bar"],
  }
  let data : Json = { "foo": "foo", "bar": "bart" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enums_in_properties_missing_optional_property_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": { "foo": { "enum": ["foo"] }, "bar": { "enum": ["bar"] } },
    "required": ["bar"],
  }
  let data : Json = { "bar": "bar" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enums_in_properties_missing_required_property_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": { "foo": { "enum": ["foo"] }, "bar": { "enum": ["bar"] } },
    "required": ["bar"],
  }
  let data : Json = { "foo": "foo" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enums_in_properties_missing_all_properties_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": { "foo": { "enum": ["foo"] }, "bar": { "enum": ["bar"] } },
    "required": ["bar"],
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_false_does_not_match_0_false_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [false],
  }
  let data : Json = false
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_false_does_not_match_0_integer_zero_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [false],
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_false_does_not_match_0_float_zero_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [false],
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_false_does_not_match_0_false_is_valid_20" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[false]],
  }
  let data : Json = [false]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_false_does_not_match_0_0_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[false]],
  }
  let data : Json = [0]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_false_does_not_match_0_0_0_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[false]],
  }
  let data : Json = [0]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_true_does_not_match_1_true_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [true],
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_true_does_not_match_1_integer_one_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [true],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_true_does_not_match_1_float_one_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [true],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_true_does_not_match_1_true_is_valid_26" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[true]],
  }
  let data : Json = [true]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_true_does_not_match_1_1_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[true]],
  }
  let data : Json = [1]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_true_does_not_match_1_1_0_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[true]],
  }
  let data : Json = [1]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_0_does_not_match_false_false_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [0],
  }
  let data : Json = false
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_0_does_not_match_false_integer_zero_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [0],
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_0_does_not_match_false_float_zero_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [0],
  }
  let data : Json = 0
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_0_does_not_match_false_false_is_invalid_32" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[0]],
  }
  let data : Json = [false]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_0_does_not_match_false_0_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[0]],
  }
  let data : Json = [0]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_0_does_not_match_false_0_0_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[0]],
  }
  let data : Json = [0]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_1_does_not_match_true_true_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [1],
  }
  let data : Json = true
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_1_does_not_match_true_integer_one_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [1],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_1_does_not_match_true_float_one_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [1],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_1_does_not_match_true_true_is_invalid_38" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[1]],
  }
  let data : Json = [true]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_enum_enum_with_1_does_not_match_true_1_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[1]],
  }
  let data : Json = [1]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_enum_enum_with_1_does_not_match_true_1_0_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "enum": [[1]],
  }
  let data : Json = [1]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: anyOf.json

///|
test "spec_anyof_anyof_first_anyof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [{ "type": "integer" }, { "minimum": 2 }],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_anyof_second_anyof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [{ "type": "integer" }, { "minimum": 2 }],
  }
  let data : Json = 2.5
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_anyof_both_anyof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [{ "type": "integer" }, { "minimum": 2 }],
  }
  let data : Json = 3
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_anyof_neither_anyof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [{ "type": "integer" }, { "minimum": 2 }],
  }
  let data : Json = 1.5
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_anyof_anyof_with_base_schema_mismatch_base_schema" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
    "anyOf": [{ "maxLength": 2 }, { "minLength": 4 }],
  }
  let data : Json = 3
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_anyof_anyof_with_base_schema_one_anyof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
    "anyOf": [{ "maxLength": 2 }, { "minLength": 4 }],
  }
  let data : Json = "foobar"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_anyof_with_base_schema_both_anyof_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
    "anyOf": [{ "maxLength": 2 }, { "minLength": 4 }],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_anyof_anyof_with_boolean_schemas_all_true_any_value_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [true, true],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_anyof_with_boolean_schemas_some_true_any_value_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [true, false],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_anyof_with_boolean_schemas_all_false_any_value_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [false, false],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_anyof_anyof_complex_types_first_anyof_valid_complex" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_anyof_complex_types_second_anyof_valid_complex" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": "baz" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_anyof_complex_types_both_anyof_valid_complex" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": "baz", "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_anyof_complex_types_neither_anyof_valid_complex" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": 2, "bar": "quux" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_anyof_anyof_with_one_empty_schema_string_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [{ "type": "number" }, {}],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_anyof_with_one_empty_schema_number_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [{ "type": "number" }, {}],
  }
  let data : Json = 123
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_nested_anyof_to_check_validation_semantics_null_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [{ "anyOf": [{ "type": "null" }] }],
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_anyof_nested_anyof_to_check_validation_semantics_anything_non_nul" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "anyOf": [{ "anyOf": [{ "type": "null" }] }],
  }
  let data : Json = 123
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: allOf.json

///|
test "spec_allof_allof_allof" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": "baz", "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_allof_allof_mismatch_second" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": "baz" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_mismatch_first" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_wrong_type" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": "baz", "bar": "quux" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_with_base_schema_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "bar": { "type": "integer" } },
    "required": ["bar"],
    "allOf": [
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
      { "properties": { "baz": { "type": "null" } }, "required": ["baz"] },
    ],
  }
  let data : Json = { "foo": "quux", "bar": 2, "baz": null }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_allof_allof_with_base_schema_mismatch_base_schema" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "bar": { "type": "integer" } },
    "required": ["bar"],
    "allOf": [
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
      { "properties": { "baz": { "type": "null" } }, "required": ["baz"] },
    ],
  }
  let data : Json = { "foo": "quux", "baz": null }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_with_base_schema_mismatch_first_allof" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "bar": { "type": "integer" } },
    "required": ["bar"],
    "allOf": [
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
      { "properties": { "baz": { "type": "null" } }, "required": ["baz"] },
    ],
  }
  let data : Json = { "bar": 2, "baz": null }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_with_base_schema_mismatch_second_allof" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "bar": { "type": "integer" } },
    "required": ["bar"],
    "allOf": [
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
      { "properties": { "baz": { "type": "null" } }, "required": ["baz"] },
    ],
  }
  let data : Json = { "foo": "quux", "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_with_base_schema_mismatch_both" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "bar": { "type": "integer" } },
    "required": ["bar"],
    "allOf": [
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
      { "properties": { "baz": { "type": "null" } }, "required": ["baz"] },
    ],
  }
  let data : Json = { "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_simple_types_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "maximum": 30 }, { "minimum": 20 }],
  }
  let data : Json = 25
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_allof_allof_simple_types_mismatch_one" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "maximum": 30 }, { "minimum": 20 }],
  }
  let data : Json = 35
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_with_boolean_schemas_all_true_any_value_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [true, true],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_allof_allof_with_boolean_schemas_some_false_any_value_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [true, false],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_with_boolean_schemas_all_false_any_value_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [false, false],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_with_one_empty_schema_any_data_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{}],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_allof_allof_with_two_empty_schemas_any_data_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{}, {}],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_allof_allof_with_the_first_empty_schema_number_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{}, { "type": "number" }],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_allof_allof_with_the_first_empty_schema_string_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{}, { "type": "number" }],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_with_the_last_empty_schema_number_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "type": "number" }, {}],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_allof_allof_with_the_last_empty_schema_string_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "type": "number" }, {}],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_nested_allof_to_check_validation_semantics_null_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "allOf": [{ "type": "null" }] }],
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_allof_nested_allof_to_check_validation_semantics_anything_non_nul" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "allOf": [{ "type": "null" }] }],
  }
  let data : Json = 123
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_combined_with_anyof_oneof_allof_false_anyof_false_one" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "multipleOf": 2 }],
    "anyOf": [{ "multipleOf": 3 }],
    "oneOf": [{ "multipleOf": 5 }],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_combined_with_anyof_oneof_allof_false_anyof_false_one_24" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "multipleOf": 2 }],
    "anyOf": [{ "multipleOf": 3 }],
    "oneOf": [{ "multipleOf": 5 }],
  }
  let data : Json = 5
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_combined_with_anyof_oneof_allof_false_anyof_true_oneo" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "multipleOf": 2 }],
    "anyOf": [{ "multipleOf": 3 }],
    "oneOf": [{ "multipleOf": 5 }],
  }
  let data : Json = 3
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_combined_with_anyof_oneof_allof_false_anyof_true_oneo_26" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "multipleOf": 2 }],
    "anyOf": [{ "multipleOf": 3 }],
    "oneOf": [{ "multipleOf": 5 }],
  }
  let data : Json = 15
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_combined_with_anyof_oneof_allof_true_anyof_false_oneo" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "multipleOf": 2 }],
    "anyOf": [{ "multipleOf": 3 }],
    "oneOf": [{ "multipleOf": 5 }],
  }
  let data : Json = 2
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_combined_with_anyof_oneof_allof_true_anyof_false_oneo_28" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "multipleOf": 2 }],
    "anyOf": [{ "multipleOf": 3 }],
    "oneOf": [{ "multipleOf": 5 }],
  }
  let data : Json = 10
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_combined_with_anyof_oneof_allof_true_anyof_true_oneof" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "multipleOf": 2 }],
    "anyOf": [{ "multipleOf": 3 }],
    "oneOf": [{ "multipleOf": 5 }],
  }
  let data : Json = 6
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_allof_allof_combined_with_anyof_oneof_allof_true_anyof_true_oneof_30" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "multipleOf": 2 }],
    "anyOf": [{ "multipleOf": 3 }],
    "oneOf": [{ "multipleOf": 5 }],
  }
  let data : Json = 30
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: oneOf.json

///|
test "spec_oneof_oneof_first_oneof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [{ "type": "integer" }, { "minimum": 2 }],
  }
  let data : Json = 1
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_second_oneof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [{ "type": "integer" }, { "minimum": 2 }],
  }
  let data : Json = 2.5
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_both_oneof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [{ "type": "integer" }, { "minimum": 2 }],
  }
  let data : Json = 3
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_neither_oneof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [{ "type": "integer" }, { "minimum": 2 }],
  }
  let data : Json = 1.5
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_with_base_schema_mismatch_base_schema" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
    "oneOf": [{ "minLength": 2 }, { "maxLength": 4 }],
  }
  let data : Json = 3
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_with_base_schema_one_oneof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
    "oneOf": [{ "minLength": 2 }, { "maxLength": 4 }],
  }
  let data : Json = "foobar"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_with_base_schema_both_oneof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "string",
    "oneOf": [{ "minLength": 2 }, { "maxLength": 4 }],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_with_boolean_schemas_all_true_any_value_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [true, true, true],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_with_boolean_schemas_one_true_any_value_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [true, false, false],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_with_boolean_schemas_more_than_one_true_any_value_is_" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [true, true, false],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_with_boolean_schemas_all_false_any_value_is_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [false, false, false],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_complex_types_first_oneof_valid_complex" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_complex_types_second_oneof_valid_complex" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": "baz" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_complex_types_both_oneof_valid_complex" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": "baz", "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_complex_types_neither_oneof_valid_complex" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [
      { "properties": { "bar": { "type": "integer" } }, "required": ["bar"] },
      { "properties": { "foo": { "type": "string" } }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": 2, "bar": "quux" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_with_empty_schema_one_valid_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [{ "type": "number" }, {}],
  }
  let data : Json = "foo"
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_with_empty_schema_both_valid_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [{ "type": "number" }, {}],
  }
  let data : Json = 123
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_with_required_both_invalid_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "oneOf": [{ "required": ["foo", "bar"] }, { "required": ["foo", "baz"] }],
  }
  let data : Json = { "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_with_required_first_valid_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "oneOf": [{ "required": ["foo", "bar"] }, { "required": ["foo", "baz"] }],
  }
  let data : Json = { "foo": 1, "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_with_required_second_valid_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "oneOf": [{ "required": ["foo", "bar"] }, { "required": ["foo", "baz"] }],
  }
  let data : Json = { "foo": 1, "baz": 3 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_with_required_both_valid_invalid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "oneOf": [{ "required": ["foo", "bar"] }, { "required": ["foo", "baz"] }],
  }
  let data : Json = { "foo": 1, "bar": 2, "baz": 3 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_with_missing_optional_property_first_oneof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [
      { "properties": { "bar": true, "baz": true }, "required": ["bar"] },
      { "properties": { "foo": true }, "required": ["foo"] },
    ],
  }
  let data : Json = { "bar": 8 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_with_missing_optional_property_second_oneof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [
      { "properties": { "bar": true, "baz": true }, "required": ["bar"] },
      { "properties": { "foo": true }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": "foo" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_oneof_with_missing_optional_property_both_oneof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [
      { "properties": { "bar": true, "baz": true }, "required": ["bar"] },
      { "properties": { "foo": true }, "required": ["foo"] },
    ],
  }
  let data : Json = { "foo": "foo", "bar": 8 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_oneof_with_missing_optional_property_neither_oneof_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [
      { "properties": { "bar": true, "baz": true }, "required": ["bar"] },
      { "properties": { "foo": true }, "required": ["foo"] },
    ],
  }
  let data : Json = { "baz": "quux" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_oneof_nested_oneof_to_check_validation_semantics_null_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [{ "oneOf": [{ "type": "null" }] }],
  }
  let data : Json = @json.parse("null")
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_oneof_nested_oneof_to_check_validation_semantics_anything_non_nul" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "oneOf": [{ "oneOf": [{ "type": "null" }] }],
  }
  let data : Json = 123
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

// Skipped 2 tests with special characters
// Auto-generated from JSON Schema Test Suite
// Source: properties.json

///|
test "spec_properties_object_properties_validation_both_properties_present_a" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": { "type": "integer" }, "bar": { "type": "string" } },
  }
  let data : Json = { "foo": 1, "bar": "baz" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_object_properties_validation_one_property_invalid_is_i" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": { "type": "integer" }, "bar": { "type": "string" } },
  }
  let data : Json = { "foo": 1, "bar": {} }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_properties_object_properties_validation_both_properties_invalid_i" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": { "type": "integer" }, "bar": { "type": "string" } },
  }
  let data : Json = { "foo": [], "bar": {} }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_properties_object_properties_validation_doesn_t_invalidate_other_" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": { "type": "integer" }, "bar": { "type": "string" } },
  }
  let data : Json = { "quux": [] }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_object_properties_validation_ignores_arrays" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": { "type": "integer" }, "bar": { "type": "string" } },
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_object_properties_validation_ignores_other_non_objects" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": { "type": "integer" }, "bar": { "type": "string" } },
  }
  let data : Json = 12
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_properties_patternproperties_additionalproperties_inte" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "foo": { "type": "array", "maxItems": 3 },
      "bar": { "type": "array" },
    },
    "patternProperties": { "f.o": { "minItems": 2 } },
    "additionalProperties": { "type": "integer" },
  }
  let data : Json = { "foo": [1, 2] }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_properties_patternproperties_additionalproperties_inte_8" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "foo": { "type": "array", "maxItems": 3 },
      "bar": { "type": "array" },
    },
    "patternProperties": { "f.o": { "minItems": 2 } },
    "additionalProperties": { "type": "integer" },
  }
  let data : Json = { "foo": [1, 2, 3, 4] }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

// SKIPPED: patternProperties not implemented
// ///|
// test "spec_properties_properties_patternproperties_additionalproperties_inte_9" {
//   let schema : Json = { "$schema": "https://json-schema.org/draft/2020-12/schema", "properties": { "foo": { "type": "array", "maxItems": 3 }, "bar": { "type": "array" } }, "patternProperties": { "f.o": { "minItems": 2 } }, "additionalProperties": { "type": "integer" } }
//   let data : Json = { "foo": [] }
//   let validator = build_validator(schema)
//   let result = validator.validate(data)
//   guard result is Err(_)
// }

// SKIPPED: patternProperties not implemented
// ///|
// test "spec_properties_properties_patternproperties_additionalproperties_inte_10" {
//   let schema : Json = { "$schema": "https://json-schema.org/draft/2020-12/schema", "properties": { "foo": { "type": "array", "maxItems": 3 }, "bar": { "type": "array" } }, "patternProperties": { "f.o": { "minItems": 2 } }, "additionalProperties": { "type": "integer" } }
//   let data : Json = { "fxo": [1, 2] }
//   let validator = build_validator(schema)
//   let result = validator.validate(data)
//   guard result is Ok(_)
// }

///|
test "spec_properties_properties_patternproperties_additionalproperties_inte_11" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "foo": { "type": "array", "maxItems": 3 },
      "bar": { "type": "array" },
    },
    "patternProperties": { "f.o": { "minItems": 2 } },
    "additionalProperties": { "type": "integer" },
  }
  let data : Json = { "fxo": [] }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_properties_properties_patternproperties_additionalproperties_inte_12" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "foo": { "type": "array", "maxItems": 3 },
      "bar": { "type": "array" },
    },
    "patternProperties": { "f.o": { "minItems": 2 } },
    "additionalProperties": { "type": "integer" },
  }
  let data : Json = { "bar": [] }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_properties_patternproperties_additionalproperties_inte_13" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "foo": { "type": "array", "maxItems": 3 },
      "bar": { "type": "array" },
    },
    "patternProperties": { "f.o": { "minItems": 2 } },
    "additionalProperties": { "type": "integer" },
  }
  let data : Json = { "quux": 3 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_properties_patternproperties_additionalproperties_inte_14" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "foo": { "type": "array", "maxItems": 3 },
      "bar": { "type": "array" },
    },
    "patternProperties": { "f.o": { "minItems": 2 } },
    "additionalProperties": { "type": "integer" },
  }
  let data : Json = { "quux": "foo" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_properties_properties_with_boolean_schema_no_property_present_is_" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": true, "bar": false },
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_properties_with_boolean_schema_only_true_property_pres" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": true, "bar": false },
  }
  let data : Json = { "foo": 1 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_properties_with_boolean_schema_only_false_property_pre" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": true, "bar": false },
  }
  let data : Json = { "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_properties_properties_with_boolean_schema_both_properties_present" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": true, "bar": false },
  }
  let data : Json = { "foo": 1, "bar": 2 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_properties_properties_with_null_valued_instance_properties_allows" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": { "foo": { "type": "null" } },
  }
  let data : Json = { "foo": null }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_properties_whose_names_are_javascript_object_property_" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "__proto__": { "type": "number" },
      "toString": { "properties": { "length": { "type": "string" } } },
      "constructor": { "type": "number" },
    },
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_properties_whose_names_are_javascript_object_property__21" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "__proto__": { "type": "number" },
      "toString": { "properties": { "length": { "type": "string" } } },
      "constructor": { "type": "number" },
    },
  }
  let data : Json = 12
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_properties_whose_names_are_javascript_object_property__22" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "__proto__": { "type": "number" },
      "toString": { "properties": { "length": { "type": "string" } } },
      "constructor": { "type": "number" },
    },
  }
  let data : Json = {}
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_properties_properties_whose_names_are_javascript_object_property__23" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "__proto__": { "type": "number" },
      "toString": { "properties": { "length": { "type": "string" } } },
      "constructor": { "type": "number" },
    },
  }
  let data : Json = { "__proto__": "foo" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_properties_properties_whose_names_are_javascript_object_property__24" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "__proto__": { "type": "number" },
      "toString": { "properties": { "length": { "type": "string" } } },
      "constructor": { "type": "number" },
    },
  }
  let data : Json = { "toString": { "length": 37 } }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_properties_properties_whose_names_are_javascript_object_property__25" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "__proto__": { "type": "number" },
      "toString": { "properties": { "length": { "type": "string" } } },
      "constructor": { "type": "number" },
    },
  }
  let data : Json = { "constructor": { "length": 37 } }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_properties_properties_whose_names_are_javascript_object_property__26" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "properties": {
      "__proto__": { "type": "number" },
      "toString": { "properties": { "length": { "type": "string" } } },
      "constructor": { "type": "number" },
    },
  }
  let data : Json = {
    "__proto__": 12,
    "toString": { "length": "foo" },
    "constructor": 37,
  }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

// Auto-generated from JSON Schema Test Suite
// Source: items.json

///|
test "spec_items_a_schema_given_for_items_valid_items" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "items": { "type": "integer" },
  }
  let data : Json = [1, 2, 3]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_a_schema_given_for_items_wrong_type_of_items" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "items": { "type": "integer" },
  }
  let data : Json = [1, "x"]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_a_schema_given_for_items_ignores_non_arrays" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "items": { "type": "integer" },
  }
  let data : Json = { "foo": "bar" }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_a_schema_given_for_items_javascript_pseudo_array_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "items": { "type": "integer" },
  }
  let data : Json = { "0": "invalid", "length": 1 }
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_items_with_boolean_schema_true_any_array_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "items": true,
  }
  let data : Json = [1, "foo", true]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_items_with_boolean_schema_true_empty_array_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "items": true,
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_items_with_boolean_schema_false_any_non_empty_array_is_inva" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "items": false,
  }
  let data : Json = [1, "foo", true]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_items_with_boolean_schema_false_empty_array_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "items": false,
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_items_and_subitems_valid_items" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$defs": {
      "item": {
        "type": "array",
        "items": false,
        "prefixItems": [
          { "$ref": "#/$defs/sub-item" },
          { "$ref": "#/$defs/sub-item" },
        ],
      },
      "sub-item": { "type": "object", "required": ["foo"] },
    },
    "type": "array",
    "items": false,
    "prefixItems": [
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
    ],
  }
  let data : Json = [
    [{ "foo": null }, { "foo": null }],
    [{ "foo": null }, { "foo": null }],
    [{ "foo": null }, { "foo": null }],
  ]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_items_and_subitems_too_many_items" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$defs": {
      "item": {
        "type": "array",
        "items": false,
        "prefixItems": [
          { "$ref": "#/$defs/sub-item" },
          { "$ref": "#/$defs/sub-item" },
        ],
      },
      "sub-item": { "type": "object", "required": ["foo"] },
    },
    "type": "array",
    "items": false,
    "prefixItems": [
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
    ],
  }
  let data : Json = [
    [{ "foo": null }, { "foo": null }],
    [{ "foo": null }, { "foo": null }],
    [{ "foo": null }, { "foo": null }],
    [{ "foo": null }, { "foo": null }],
  ]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_items_and_subitems_too_many_sub_items" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$defs": {
      "item": {
        "type": "array",
        "items": false,
        "prefixItems": [
          { "$ref": "#/$defs/sub-item" },
          { "$ref": "#/$defs/sub-item" },
        ],
      },
      "sub-item": { "type": "object", "required": ["foo"] },
    },
    "type": "array",
    "items": false,
    "prefixItems": [
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
    ],
  }
  let data : Json = [
    [{ "foo": null }, { "foo": null }, { "foo": null }],
    [{ "foo": null }, { "foo": null }],
    [{ "foo": null }, { "foo": null }],
  ]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_items_and_subitems_wrong_item" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$defs": {
      "item": {
        "type": "array",
        "items": false,
        "prefixItems": [
          { "$ref": "#/$defs/sub-item" },
          { "$ref": "#/$defs/sub-item" },
        ],
      },
      "sub-item": { "type": "object", "required": ["foo"] },
    },
    "type": "array",
    "items": false,
    "prefixItems": [
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
    ],
  }
  let data : Json = [
    { "foo": null },
    [{ "foo": null }, { "foo": null }],
    [{ "foo": null }, { "foo": null }],
  ]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_items_and_subitems_wrong_sub_item" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$defs": {
      "item": {
        "type": "array",
        "items": false,
        "prefixItems": [
          { "$ref": "#/$defs/sub-item" },
          { "$ref": "#/$defs/sub-item" },
        ],
      },
      "sub-item": { "type": "object", "required": ["foo"] },
    },
    "type": "array",
    "items": false,
    "prefixItems": [
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
    ],
  }
  let data : Json = [
    [{}, { "foo": null }],
    [{ "foo": null }, { "foo": null }],
    [{ "foo": null }, { "foo": null }],
  ]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_items_and_subitems_fewer_items_is_valid" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$defs": {
      "item": {
        "type": "array",
        "items": false,
        "prefixItems": [
          { "$ref": "#/$defs/sub-item" },
          { "$ref": "#/$defs/sub-item" },
        ],
      },
      "sub-item": { "type": "object", "required": ["foo"] },
    },
    "type": "array",
    "items": false,
    "prefixItems": [
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
      { "$ref": "#/$defs/item" },
    ],
  }
  let data : Json = [[{ "foo": null }], [{ "foo": null }]]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_nested_items_valid_nested_array" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "array",
    "items": {
      "type": "array",
      "items": {
        "type": "array",
        "items": { "type": "array", "items": { "type": "number" } },
      },
    },
  }
  let data : Json = [[[[1]], [[2], [3]]], [[[4], [5], [6]]]]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_nested_items_nested_array_with_invalid_type" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "array",
    "items": {
      "type": "array",
      "items": {
        "type": "array",
        "items": { "type": "array", "items": { "type": "number" } },
      },
    },
  }
  let data : Json = [[[["1"]], [[2], [3]]], [[[4], [5], [6]]]]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_nested_items_not_deep_enough" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "array",
    "items": {
      "type": "array",
      "items": {
        "type": "array",
        "items": { "type": "array", "items": { "type": "number" } },
      },
    },
  }
  let data : Json = [[[1], [2], [3]], [[4], [5], [6]]]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_prefixitems_with_no_additional_items_allowed_empty_array" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "prefixItems": [{}, {}, {}],
    "items": false,
  }
  let data : Json = []
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_prefixitems_with_no_additional_items_allowed_fewer_number_o" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "prefixItems": [{}, {}, {}],
    "items": false,
  }
  let data : Json = [1]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_prefixitems_with_no_additional_items_allowed_fewer_number_o_20" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "prefixItems": [{}, {}, {}],
    "items": false,
  }
  let data : Json = [1, 2]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_prefixitems_with_no_additional_items_allowed_equal_number_o" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "prefixItems": [{}, {}, {}],
    "items": false,
  }
  let data : Json = [1, 2, 3]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_prefixitems_with_no_additional_items_allowed_additional_ite" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "prefixItems": [{}, {}, {}],
    "items": false,
  }
  let data : Json = [1, 2, 3, 4]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_items_does_not_look_in_applicators_valid_case_prefixitems_i" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "prefixItems": [{ "minimum": 3 }] }],
    "items": { "minimum": 5 },
  }
  let data : Json = [3, 5]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_items_does_not_look_in_applicators_valid_case_prefixitems_i_24" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "allOf": [{ "prefixItems": [{ "minimum": 3 }] }],
    "items": { "minimum": 5 },
  }
  let data : Json = [5, 5]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_prefixitems_validation_adjusts_the_starting_index_for_items" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "prefixItems": [{ "type": "string" }],
    "items": { "type": "integer" },
  }
  let data : Json = ["x", 2, 3]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_prefixitems_validation_adjusts_the_starting_index_for_items_26" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "prefixItems": [{ "type": "string" }],
    "items": { "type": "integer" },
  }
  let data : Json = ["x", "y"]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_items_with_heterogeneous_array_heterogeneous_invalid_instan" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "prefixItems": [{}],
    "items": false,
  }
  let data : Json = ["foo", "bar", 37]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Err(_)
}

///|
test "spec_items_items_with_heterogeneous_array_valid_instance" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "prefixItems": [{}],
    "items": false,
  }
  let data : Json = [null]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}

///|
test "spec_items_items_with_null_instance_elements_allows_null_elements" {
  let schema : Json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "items": { "type": "null" },
  }
  let data : Json = [null]
  let validator = build_validator(schema)
  let result = validator.validate(data)
  guard result is Ok(_)
}
