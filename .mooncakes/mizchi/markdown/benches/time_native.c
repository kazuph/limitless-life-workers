#include <time.h>
#include <stdint.h>

// Opaque type for storing start time (nanoseconds as int64)
typedef int64_t Instant;

// Get current monotonic time in nanoseconds
Instant instant_now_ffi() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000LL + ts.tv_nsec;
}

// Calculate elapsed time in milliseconds
double instant_elapsed_ms_ffi(Instant start) {
    Instant now = instant_now_ffi();
    return (double)(now - start) / 1000000.0;
}
