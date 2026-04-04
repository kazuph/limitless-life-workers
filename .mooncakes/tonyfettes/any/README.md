# tonyfettes/any

A type-safe dynamic typing library for MoonBit that provides runtime type
inspection and transformation capabilities.

## Overview

`tonyfettes/any` enables safe runtime type handling in MoonBit through the `Any`
type. It allows you to:

- Store values of any type and retrieve them with type safety
- Transform values between different types with compile-time guarantees
- Chain type-conditional operations on dynamic values
- Get informative error messages when type mismatches occur

## Installation

Add this package to your `moon.mod.json`:

```bash
moon update
moon add tonyfettes/any
```

## Quick Start

```moonbit test
// Store any value
let any = @any.of(42)

// Query type information
@json.inspect(any.type_name(), content="Int")

// Retrieve with type checking
let value : Int = any.to()
@json.inspect(value, content=42)

// Type mismatch raises TypeMismatch error
let value : Result[Bool, @any.TypeMismatch] = try? any.to()
@json.inspect(value, content={
  "Err": { "TypeMismatch": { "expect": "Bool", "actual": "Int" } },
})
```

## Core API

### Creating Any Values

#### `Any::of[T](value: T) -> Any`

Wraps a value of any type into an `Any` container.

```moonbit test
let int_any = @any.of(42)
@json.inspect((int_any.to() : Int))
let str_any = @any.of("hello")
@json.inspect((str_any.to() : String))
let arr_any = @any.of([1, 2, 3])
@json.inspect((arr_any.to() : Array[Int]))
```

**Special behavior**: Wrapping an `Any` value returns the original value
(identity operation):

```moonbit test
let a0 = @any.of(42)
let a1 = @any.of(a0)
@json.inspect(physical_equal(a0, a1), content=true)
```

### Type Information

#### `Any::type_info(self: Any) -> TypeInfo`

Returns the complete type information including both type ID and type name.

```moonbit test
let any = @any.of([1, 2, 3])
let info = any.type_info()
@json.inspect(
  physical_equal(info.id(), @any.of([1]).type_info().id()),
  content=true,
)
@json.inspect(info.name(), content="Array[Int]")
```

#### `Any::type_id(self: Any) -> TypeId`

Returns the runtime type identifier for the stored value.

```moonbit test
let any = @any.of(42)
let id = any.type_id()
@json.inspect(physical_equal(id, @any.of(100).type_id()), content=true)
```

#### `Any::type_name(self: Any) -> String`

Returns the human-readable type name of the stored value.

```moonbit test
let any = @any.of("hello")
@json.inspect(any.type_name())
let any = @any.of([1, 2, 3])
@json.inspect(any.type_name(), content="Array[Int]")
let any = @any.of(Some(42))
@json.inspect(any.type_name(), content="Int?")
```

### Retrieving Values

#### `Any::to[T](self: Any) -> T raise TypeMismatch`

Unwraps the value with type checking. Raises `TypeMismatch` if the actual type
doesn't match the expected type.

```moonbit test
let any = @any.of(42)
let value : Int = any.to()
@json.inspect(value, content=42)
let wrong : Result[String, _] = try? any.to()
@json.inspect(wrong, content={
  "Err": { "TypeMismatch": { "expect": "String", "actual": "Int" } },
})
```

#### `Any::try_to[T](self: Any) -> T?`

Safely attempts to unwrap the value. Returns `None` if types don't match,
`Some(value)` otherwise.

```moonbit test
let any = @any.of([1, 2, 3])
let value : Array[Int]? = any.try_to()
@json.inspect(value is Some([1, 2, 3]), content=true)
let wrong : String? = any.try_to()
@json.inspect(wrong is None, content=true)
```

#### `Any::unsafe_coerce[T](self: Any) -> T`

Performs unchecked type coercion. **Use with extreme caution** - incorrect usage
leads to undefined behavior.

```moonbit test
// Only use when you're absolutely certain about the type
let any = @any.of(42)
let value : Int = any.unsafe_coerce()
@json.inspect(value, content=42)
```

### Type Transformation

#### `Any::map[T, R](self: Any, f: (T) -> R raise?) -> Any raise?`

Conditionally applies a function if the value matches the expected type. Returns
the transformed value wrapped in `Any`, or returns the original `Any` unchanged
if types don't match.

This enables elegant type-conditional pipelines:

```moonbit test
fn any_to_int(any : @any.Any) -> Int raise {
  any
  .map((int : Int) => int) // If Int, return as-is
  .map((str : String) => @strconv.parse_int(str)) // If String, parse it
  .map((double : Double) => double.to_int()) // If Double, convert it
  .to() // Finally extract the Int
}

@json.inspect(any_to_int(@any.of(42)))
@json.inspect(any_to_int(@any.of("43")))
@json.inspect(any_to_int(@any.of(44.0)))
```

The `map` function is particularly powerful for:

- **Type-safe dispatching**: Handle different types with different logic
- **Fallthrough behavior**: Non-matching types pass through unchanged
- **Exhaustiveness checking**: Chain maps to handle all possible types

Example with Unit return type (side effects only):

```moonbit test
let any = @any.of("hello")
any
.map((int : Int) => println("Int(\{int})"))
.map((str : String) => println("String(\{str})")) // This executes
.to() // Ensures all cases are handled
```

## Error Handling

### TypeMismatch

The `TypeMismatch` error provides detailed information about type mismatches,
carrying complete `TypeInfo` for both expected and actual types:

```moonbit
///|
pub suberror TypeMismatch {
  TypeMismatch(expect~ : TypeInfo, actual~ : TypeInfo)
}
```

**Traits implemented**:

- `Show`: Human-readable error messages
- `ToJson`: JSON serialization for structured error handling

Example error output:

```moonbit test
let any = @any.of([1, 2, 3])
let result : Result[Bool, @any.TypeMismatch] = try? any.to()
@json.inspect(result, content={
  "Err": { "TypeMismatch": { "expect": "Bool", "actual": "Array[Int]" } },
})
```

The error message format:

```plaintext
TypeMismatch: expected type 'Bool' but found type 'Array[Int]'
```

JSON representation:

```json
{
  "TypeMismatch": {
    "expect": "Bool",
    "actual": "Array[Int]"
  }
}
```

## Best Practices

1. **Prefer static typing**: Use `Any` only when runtime type flexibility is
   necessary
2. **Use `try_to()` for optional extraction**: Allocates less than handling
   `TypeMismatch` exceptions
3. **Chain `map()` for exhaustive handling**: Ensures all expected types are
   covered
4. **Avoid `unsafe_coerce()`**: Only use when performance is critical and types
   are guaranteed

## License

Apache-2.0

## Contributing

This is a MoonBit project. See `AGENTS.md` for contribution guidelines and
coding conventions.
