///|
test "Int" {
  let any = @any.of(42)
  let value : Int = any.to()
  @json.inspect(value, content=42)
  let value : Result[Bool, @any.TypeMismatch] = try? any.to()
  @json.inspect(value, content={
    "Err": { "TypeMismatch": { "expect": "Bool", "actual": "Int" } },
  })
}

///|
test "Fn" {
  let any = @any.of(() => 42)
  let value : () -> Int = any.to()
  @json.inspect(value(), content=42)
  let value : Result[() -> String, @any.TypeMismatch] = try? any.to()
  let value : Result[String, @any.TypeMismatch] = value.map(f => f())
  @json.inspect(value, content={
    "Err": {
      "TypeMismatch": { "expect": "() -> String", "actual": "() -> Int" },
    },
  })
}

///|
test "type_name" (t : @test.Test) {
  let any = @any.of(42)
  @json.inspect(any.type_name(), content="Int")
  @json.inspect(@any.of(t).type_name(), content="@moonbitlang/core/test.Test")
  @json.inspect(@any.of(Some(3)).type_name(), content="Int?")
  @json.inspect(@any.of("string").type_name(), content="String")
  @json.inspect(@any.of([1, 2, 3]).type_name(), content="Array[Int]")
  @json.inspect(
    @any.of(@immut/array.from_array([1, 2, 3])).type_name(),
    content="@moonbitlang/core/immut/array.T[Int]",
  )
  @json.inspect(
    @any.of((try? any.to() : Result[Bool, @any.TypeMismatch])).type_name(),
    content="Result[Bool, @tonyfettes/any.TypeMismatch]",
  )
}

///|
test "Array[Int]" {
  let array = [1, 2, 3]
  let any = @any.of(array)
  let value : Array[Int] = any.to()
  @json.inspect(value, content=[1, 2, 3])
  let value : Array[Int]? = any.try_to()
  @json.inspect(value, content=[[1, 2, 3]])
  let value : Result[Bool, @any.TypeMismatch] = try? any.to()
  @json.inspect(value, content={
    "Err": { "TypeMismatch": { "expect": "Bool", "actual": "Array[Int]" } },
  })
  let value : Result[Array[Double], @any.TypeMismatch] = try? any.to()
  @json.inspect(value, content={
    "Err": {
      "TypeMismatch": { "expect": "Array[Double]", "actual": "Array[Int]" },
    },
  })
}

///|
test "Any::map/Unit" {
  let any = @any.of("42")
  any
  .map((int : Int) => println("Int(\{int})"))
  .map((str : String) => println("String(\{str})"))
  // Ensures all possible types of `any` are handled
  .to()
}

///|
test "Any::map/Int" {
  fn any_to_int(any : @any.Any) -> Int raise {
    any
    .map((int : Int) => int)
    .map((str : String) => @strconv.parse_int(str))
    .map((double : Double) => double.to_int())
    .to()
  }

  @json.inspect(any_to_int(@any.of(42)), content=42)
  @json.inspect(any_to_int(@any.of("43")), content=43)
  @json.inspect(any_to_int(@any.of(44.0)), content=44)
  @json.inspect(try? any_to_int(@any.of(Json::null())), content={
    "Err": { "TypeMismatch": { "expect": "Int", "actual": "Json" } },
  })
}

///|
test "Idempotence" {
  let a0 : @any.Any = @any.of(42)
  let a1 : @any.Any = @any.of(a0)
  let a2 : @any.Any = a1.to()
  let a3 : @any.Any? = a2.try_to()
  @json.inspect(physical_equal(a1, a0), content=true)
  @json.inspect(physical_equal(a1, a2), content=true)
  @json.inspect(physical_equal(a2, a0), content=true)
  @json.inspect(physical_equal(a3.unwrap(), a0), content=true)
  let i0 : Int = a0.to()
  let i1 : Int = a1.to()
  let i2 : Int = a2.to()
  @json.inspect(i0, content=42)
  @json.inspect(i1, content=42)
  @json.inspect(i2, content=42)
}

///|
type A

///|
pub fn A::of(value : Ref[Int]) -> A = "%identity"

///|
type B

///|
pub fn B::to(value : B) -> Ref[Double] = "%identity"

///|
test "Abstract" {
  let any_a = @any.of(A::of(Ref::new(42)))
  @json.inspect(any_a.type_name(), content="A")
  let ra : Result[Ref[Int], @any.TypeMismatch] = try? any_a.to()
  let i : Result[Int, @any.TypeMismatch] = ra.map(r => r.val)
  @json.inspect(i, content={
    "Err": { "TypeMismatch": { "expect": "Ref[Int]", "actual": "A" } },
  })
  let b : Result[B, @any.TypeMismatch] = try? any_a.to()
  let b = b.map(b => b.to().val)
  @json.inspect(b, content={
    "Err": { "TypeMismatch": { "expect": "B", "actual": "A" } },
  })
}
