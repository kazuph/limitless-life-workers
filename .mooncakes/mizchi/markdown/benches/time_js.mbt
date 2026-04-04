///| JavaScript time measurement FFI

///|
#external
type Instant

///|
pub extern "js" fn instant_now() -> Instant =
  #| () => performance.now()

///|
pub extern "js" fn instant_elapsed_ms(start : Instant) -> Double =
  #| (start) => performance.now() - start
