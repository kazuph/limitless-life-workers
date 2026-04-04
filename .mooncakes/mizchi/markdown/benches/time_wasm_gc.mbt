///| WASM-GC time measurement using performance.now()

///|
#external
type Instant

///|
pub fn instant_now() -> Instant = "__moonbit_time_unstable" "instant_now"

///|
fn instant_elapsed_as_secs_f64(x : Instant) -> Double = "__moonbit_time_unstable" "instant_elapsed_as_secs_f64"

///|
pub fn instant_elapsed_ms(start : Instant) -> Double {
  instant_elapsed_as_secs_f64(start) * 1000.0
}
