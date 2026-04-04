///| Native time measurement using clock_gettime

///|
struct Instant {
  ns : Int64
}

///|
extern "c" fn instant_now_ffi() -> Int64 = "instant_now_ffi"

///|
extern "c" fn instant_elapsed_ms_ffi(start : Int64) -> Double = "instant_elapsed_ms_ffi"

///|
pub fn instant_now() -> Instant {
  { ns: instant_now_ffi() }
}

///|
pub fn instant_elapsed_ms(start : Instant) -> Double {
  instant_elapsed_ms_ffi(start.ns)
}
