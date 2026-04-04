///|
/// experimental TypeScript code generator from JSON Schema
fn generate_typescript(
  schema : @types.JsonSchema,
  root_name? : String = "Root",
  depth? : Int = 0,
) -> String {
  match schema {
    @types.JsonSchema::Object(constraints) => {
      let logger = StringBuilder::new()
      let prefix = "  ".repeat(depth)
      let is_root = depth == 0

      // open brace
      if is_root {
        logger.write_string("export type \{root_name} = {")
      } else {
        logger.write_string("{")
      }
      // let {required,cons} = constraints
      // logger.write_string("export type MyStruct = {")
      if constraints.properties is Some(properties) {
        let required_keys = match schema {
          @types.JsonSchema::Object(sub_constraints) =>
            match sub_constraints.required {
              Some(req) => req |> Set::from_array
              None => Set::new()
            }
          _ => Set::new()
        }
        let child_prefix = "  ".repeat(depth + 1)
        for key, subschema in properties {
          if required_keys.contains(key) {
            logger.write_string("\n\{child_prefix}\{key}: ")
          } else {
            logger.write_string("\n\{child_prefix}\{key}?: ")
          }
          let subtype = generate_typescript(subschema, depth=depth + 1)
          logger.write_string("\{subtype}")
        }
      }
      // close
      logger.write_string("\n\{prefix}};")
      return logger.to_string()
    }
    @types.JsonSchema::String(_) => "string"
    @types.JsonSchema::Number(_) => "number"
    @types.JsonSchema::Integer(_) => "number"
    @types.JsonSchema::Boolean(_) => "boolean"
    @types.JsonSchema::OneOf({ schemas, .. }) =>
      if schemas.length() == 2 {
        match schemas {
          [@types.JsonSchema::Null(_), other]
          | [other, @types.JsonSchema::Null(_)] =>
            return generate_typescript(other) + " | null"
          _ => "any | null"
        }
      } else {
        "any | null"
      }
    @types.JsonSchema::Array({ items, .. }) =>
      "Array<" + generate_typescript(items.unwrap()) + ">"
    _ => "\"unsupported type\"".to_string()
  }
}

///|
test "ts code generation" {
  let schema : Json = @json.parse(
    (
      #|{
      #|  "type": "object",
      #|  "properties": {
      #|    "name": { "type": "string" },
      #|    "age": { "type": "number" },
      #|    "items": {
      #|      "type": "array",
      #|      "items": { "type": "string" }
      #|    },
      #|    "opt_str": {
      #|      "oneOf": [
      #|        { "type": "string" },
      #|        { "type": "null" }
      #|      ]
      #|    },
      #|    "opt_number": {
      #|      "oneOf": [
      #|        { "type": "number" },
      #|        { "type": "null" }
      #|      ]
      #|    }
      #|  },
      #|  "required": ["name", "age"]
      #|}
    ),
  )
  let jschema : @types.JsonSchema = @parser.parse_schema(schema)
  let code = generate_typescript(jschema)
  inspect(
    code,
    content=(
      #|export type Root = {
      #|  name: string
      #|  age: number
      #|  items?: Array<string>
      #|  opt_str?: string | null
      #|  opt_number?: number | null
      #|};
    ),
  )
}

///|
test "ts code generation nested" {
  let schema : Json = @json.parse(
    (
      #|{
      #|  "type": "object",
      #|  "properties": {
      #|    "nested": {
      #|      "type": "object",
      #|      "properties": {
      #|         "v1": { "type": "number" },
      #|         "v2": { "type": "number" }
      #|      }
      #|    }
      #|  },
      #|  "required": ["nested"]
      #|}
    ),
  )
  let jschema : @types.JsonSchema = @parser.parse_schema(schema)
  let code = generate_typescript(jschema)
  inspect(
    code,
    content=(
      #|export type Root = {
      #|  nested: {
      #|    v1?: number
      #|    v2?: number
      #|  };
      #|};
    ),
  )
}
