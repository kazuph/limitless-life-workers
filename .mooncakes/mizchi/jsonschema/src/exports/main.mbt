///|
/// Create a validator from a pre-built schema (no parsing, no $ref support)
pub fn from_schema(schema : @types.JsonSchema) -> @validate.Validator {
  @validate.Validator::from_schema(schema)
}

///|
/// Validate JSON against a pre-built schema
pub fn validate_schema(
  schema : @types.JsonSchema,
  input : Json,
) -> Result[Unit, Array[@validate.ValidationError]] {
  @validate.Validator::from_schema(schema).validate(input)
}

///|
/// Build a validator from a JSON Schema (with parsing and $ref support)
pub fn build_validator(
  raw : Json,
) -> @validate.Validator raise @validate.ParseError {
  @validate.build_validator(raw)
}

///|
/// Validate JSON against a JSON schema (with parsing)
pub fn validate(
  schema : Json,
  input : Json,
) -> Result[Unit, Array[@validate.ValidationError]] {
  let validator = @validate.build_validator(schema) catch {
    @validate.ParseError::ParserError(_) =>
      return Err([
        @validate.ValidationError::new(
          schema,
          @types.JsonPointer::Root,
          @types.JsonPointer::Root,
          "Failed to parse schema: ParserError",
        ),
      ])
    @validate.ParseError::PointerParseError(msg) =>
      return Err([
        @validate.ValidationError::new(
          schema,
          @types.JsonPointer::Root,
          @types.JsonPointer::Root,
          "Failed to parse schema: PointerParseError - \{msg}",
        ),
      ])
    @validate.ParseError::InvalidSchema(msg) =>
      return Err([
        @validate.ValidationError::new(
          schema,
          @types.JsonPointer::Root,
          @types.JsonPointer::Root,
          "Failed to parse schema: InvalidSchema - \{msg}",
        ),
      ])
  }
  validator.validate(input)
}

// Schema builders (valibot-style)

///|
/// Create a string schema
pub fn string_schema(
  min_length? : Int? = None,
  max_length? : Int? = None,
  enum_? : Array[String]? = None,
) -> @types.JsonSchema {
  @types.JsonSchema::String(@types.StringSchema::{
    min_length,
    max_length,
    enum_,
    strict_type: Some(true),
  })
}

///|
/// Create a number schema
pub fn number_schema(
  minimum? : Double? = None,
  maximum? : Double? = None,
  exclusive_minimum? : Double? = None,
  exclusive_maximum? : Double? = None,
  multiple_of? : Double? = None,
) -> @types.JsonSchema {
  @types.JsonSchema::Number(@types.NumberSchema::{
    minimum,
    maximum,
    exclusive_minimum,
    exclusive_maximum,
    multiple_of,
    strict_type: Some(true),
  })
}

///|
/// Create an integer schema
pub fn integer_schema(
  minimum? : Int? = None,
  maximum? : Int? = None,
  exclusive_minimum? : Int? = None,
  exclusive_maximum? : Int? = None,
  multiple_of? : Int? = None,
) -> @types.JsonSchema {
  @types.JsonSchema::Integer(@types.IntegerSchema::{
    minimum,
    maximum,
    exclusive_minimum,
    exclusive_maximum,
    multiple_of,
    strict_type: Some(true),
  })
}

///|
/// Create a boolean schema
pub fn boolean_schema() -> @types.JsonSchema {
  @types.JsonSchema::Boolean(@types.BooleanSchema::{  })
}

///|
/// Create a null schema
pub fn null_schema() -> @types.JsonSchema {
  @types.JsonSchema::Null(@types.NullSchema::{  })
}

///|
/// Create an array schema
pub fn array_schema(
  items? : @types.JsonSchema? = None,
  min_items? : Int? = None,
  max_items? : Int? = None,
) -> @types.JsonSchema {
  @types.JsonSchema::Array(@types.ArraySchema::{
    items,
    prefix_items: None,
    contains: None,
    min_contains: None,
    max_contains: None,
    min_items,
    max_items,
    strict_type: Some(true),
  })
}

///|
/// Create an object schema
pub fn object_schema(
  properties? : Map[String, @types.JsonSchema]? = None,
  required? : Array[String]? = None,
  additional_properties? : @types.JsonSchema? = None,
) -> @types.JsonSchema {
  @types.JsonSchema::Object(@types.ObjectSchema::{
    properties,
    required,
    additional_properties,
    strict_type: Some(true),
  })
}

///|
/// Create an anyOf schema
pub fn any_of_schema(schemas : Array[@types.JsonSchema]) -> @types.JsonSchema {
  @types.JsonSchema::AnyOf(@types.AnyOfSchema::{ schemas, })
}

///|
/// Create a oneOf schema
pub fn one_of_schema(schemas : Array[@types.JsonSchema]) -> @types.JsonSchema {
  @types.JsonSchema::OneOf(@types.OneOfSchema::{
    schemas,
    parsed_enumerable: None,
    parsed_nullable: None,
  })
}

///|
/// Create a const schema
pub fn const_schema(value : Json) -> @types.JsonSchema {
  @types.JsonSchema::Const(@types.ConstSchema::{ value, })
}

///|
/// Create an any schema (accepts anything)
pub fn any_schema() -> @types.JsonSchema {
  @types.JsonSchema::Any(@types.AnySchema::{  })
}
