///|
priv type Object

///|
fn[T] Object::of(value : T) -> Object = "%identity"

///|
fn[T] Object::to(self : Object) -> T = "%identity"

///|
priv trait ToAny {
  id() -> Unit = _
  get_id(() -> Self) -> TypeId = _
}

///|
impl ToAny with id() -> Unit {

}

///|
impl ToAny with get_id(_ : () -> Self) -> TypeId {
  Self::id
}

///|
impl[T] ToAny for Ref[T]

///|
fn[T] any_to_string(value : T) -> String = "%any.to_string"

///|
fn[T] type_name(value : () -> T) -> String {
  let string = any_to_string(value)
  guard string is [.. "<obj:() -> ", .. name, '>'] else {
    abort(
      "@tonyfettes/any.type_name: unexpected any.to_string() format: \{string}",
    )
  }
  name.to_string()
}

///|
struct Any(TypeInfo, Object)

///|
/// Returns the complete type information for the value stored in this `Any`.
///
/// The `TypeInfo` contains both the runtime type id and the human-readable
/// type name. This is useful when you need both pieces of information or want
/// to pass the complete type metadata around.
pub fn Any::type_info(self : Any) -> TypeInfo {
  self.0
}

///|
/// Returns the runtime type identifier for the value stored in this `Any`.
///
/// The `TypeId` is used internally to perform type checks during extraction.
/// Two `Any` values will have physically equal type ids if and only if they
/// contain values of the same type.
pub fn Any::type_id(self : Any) -> TypeId {
  self.0.0
}

///|
/// Returns the human-readable name of the type stored in this `Any`.
///
/// This is particularly useful for debugging, logging, and error messages.
/// The name is captured when the value is first wrapped with `Any::of`.
pub fn Any::type_name(self : Any) -> String {
  self.0.1
}

///|
#warnings("-unused_constructor")
struct TypeId(() -> Unit)

///|
struct TypeInfo(TypeId, String)

///|
/// Extracts the runtime type identifier from this `TypeInfo`.
///
/// Returns the `TypeId` component which is used for physical equality checks
/// during type matching operations.
pub fn TypeInfo::id(self : TypeInfo) -> TypeId {
  self.0
}

///|
/// Extracts the human-readable type name from this `TypeInfo`.
///
/// Returns the string representation of the type, useful for debugging,
/// logging, and generating user-friendly error messages.
pub fn TypeInfo::name(self : TypeInfo) -> String {
  self.1
}

///|
let any_id : TypeId = ToAny::get_id((panic : () -> Ref[Any]))

///|
/// Wrap a value of type `T` in an `Any` container.
///
/// This records the runtime type id and stores the value in a type-erased box.
/// If the provided value is already an `Any`, the original `Any` is returned
/// (idempotent double-wrap elimination).
///
/// The first time a type id is encountered its human-readable name is cached.
#as_free_fn
pub fn[T] Any::of(value : T) -> Any {
  let r : Ref[T] = Ref::new(value)
  let id : TypeId = ToAny::get_id((panic : () -> Ref[T]))
  if physical_equal(id, any_id) {
    let r : Ref[Any] = Object::of(r).to()
    return r.val
  }
  let name : String = type_name((panic : () -> T))
  let info : TypeInfo = TypeInfo(id, name)
  Any(info, Object::of(r))
}

///|
/// Unsafely coerce the underlying value to type `T` without checking.
///
/// Only use when you are certain of the actual stored type. Prefer `to()` or
/// `try_to()` for safety. Incorrect use leads to undefined behavior.
pub fn[T] Any::unsafe_coerce(self : Any) -> T {
  let r : Ref[T] = self.1.to()
  r.val
}

///|
/// Error raised when attempting to extract a value as an incompatible type.
/// Carries both expected and actual runtime type ids so they can be converted
/// to human-readable names for diagnostics.
pub suberror TypeMismatch {
  TypeMismatch(expect~ : TypeInfo, actual~ : TypeInfo)
}

///|
pub impl Show for TypeMismatch with output(
  self : TypeMismatch,
  logger : &Logger,
) -> Unit {
  let TypeMismatch(expect~, actual~) = self
  logger.write_string(
    "TypeMismatch: expected type '\{expect.name()}' but found type '\{actual.name()}'",
  )
}

///|
pub impl ToJson for TypeMismatch with to_json(self : TypeMismatch) -> Json {
  let TypeMismatch(expect~, actual~) = self
  { "TypeMismatch": { "expect": expect.name(), "actual": actual.name() } }
}

///|
/// Extract the stored value as type `T` performing a runtime type id check.
///
/// Raises `TypeMismatch` if the ids differ. When `T` itself is `Any`, this will
/// unwrap one level (special-case id) to avoid double wrapping.
///
/// On first mismatch for a type, its name is lazily registered for error
/// output.
pub fn[T] Any::to(self : Any) -> T raise TypeMismatch {
  let id : TypeId = ToAny::get_id((panic : () -> Ref[T]))
  if physical_equal(id, any_id) {
    let r : Ref[T] = Object::of(Ref::new(self)).to()
    return r.val
  }
  guard physical_equal(self.type_id(), id) else {
    let name = type_name((panic : () -> T))
    raise TypeMismatch::TypeMismatch(expect=TypeInfo(id, name), actual=self.0)
  }
  let r : Ref[T] = self.1.to()
  r.val
}

///|
/// Attempt to extract the stored value as type `T` returning `None` if the
/// runtime type id does not match. This is the non-raising variant of `to()`.
pub fn[T] Any::try_to(self : Any) -> T? {
  let id : TypeId = ToAny::get_id((panic : () -> Ref[T]))
  if physical_equal(id, any_id) {
    let r : Ref[T] = Object::of(Ref::new(self)).to()
    return Some(r.val)
  }
  guard physical_equal(self.type_id(), id) else { return None }
  let r : Ref[T] = self.1.to()
  Some(r.val)
}

///|
/// Conditionally apply `f` to the stored value if its runtime type matches `T`.
///
/// When it matches, the result of `f` is rewrapped with `Any::of`; otherwise
/// the original `Any` is returned unchanged. Enables chaining to build
/// exhaustive type-dispatch pipelines. Propagates any error (`raise?`) from
/// `f`.
pub fn[T, R] Any::map(self : Any, f : (T) -> R raise?) -> Any raise? {
  let id : TypeId = ToAny::get_id((panic : () -> Ref[T]))
  if physical_equal(self.type_id(), id) {
    let r : Ref[T] = self.1.to()
    Any::of(f(r.val))
  } else {
    self
  }
}
