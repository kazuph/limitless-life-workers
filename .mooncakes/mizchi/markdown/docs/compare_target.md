# Target & Parser Performance Comparison

Benchmark results comparing JS, WASM-GC, and Native targets, as well as different Markdown parsers.

## Test Environment

- Document sizes:
  - small (5 sections): 1,737 chars
  - medium (20 sections): 6,893 chars
  - large (100 sections): 34,414 chars

## Parser Comparison (Parse Performance, us/iter, lower is better)

### mizchi/markdown vs rami3l/cmark vs Rust markdown-rs

| Parser | Target | small | medium | large |
|--------|--------|------:|-------:|------:|
| mizchi/markdown | JS | 134 | 356 | 1870 |
| mizchi/markdown | WASM-GC | 125 | 291 | 1329 |
| mizchi/markdown | Native | 81 | 315 | 1547 |
| rami3l/cmark | JS | 79 | 195 | 854 |
| rami3l/cmark | WASM-GC | **46** | **120** | **416** |
| rami3l/cmark | Native | 26 | 105 | 513 |
| markdown-rs | Rust Native | 202 | 621 | 3674 |

### Key Findings

1. **rami3l/cmark is 2-3x faster** than mizchi/markdown
   - cmark is a mature, well-optimized CommonMark implementation
   - mizchi/markdown is a CST-based parser with lossless serialization focus

2. **MoonBit WASM-GC outperforms Rust markdown-rs**
   - WASM-GC cmark: 416 us vs Rust markdown-rs: 3674 us (8.8x faster)
   - This demonstrates MoonBit's excellent performance characteristics

3. **Native MoonBit is fastest** for rami3l/cmark (26 us for small docs)

## mizchi/markdown Target Comparison

### Parse Performance (us/iter, lower is better)

| Benchmark | JS | WASM-GC | Native |
|-----------|---:|--------:|-------:|
| parse:small | 134 | 125 | **81** |
| parse:medium | 356 | 291 | **315** |
| parse:large | 1870 | **1329** | 1547 |

### Serialize Performance (us/iter, lower is better)

| Benchmark | JS | WASM-GC | Native |
|-----------|---:|--------:|-------:|
| serialize:small | 12 | 12 | **9** |
| serialize:medium | **28** | 56 | 40 |
| serialize:large | **123** | 158 | 179 |

### Incremental Parse Speedup (higher is better)

| Benchmark | JS | WASM-GC | Native |
|-----------|---:|--------:|-------:|
| 50 paragraphs | 18x | 19x | **31x** |
| 100 paragraphs | 46x | 38x | **52x** |

## Analysis

### Parser Design Trade-offs

- **rami3l/cmark**: Optimized for speed, standard CommonMark AST
- **mizchi/markdown**: CST-based, lossless serialization, incremental parsing support
- **markdown-rs (Rust)**: Safe, extensible, but slower than MoonBit implementations

### MoonBit Target Performance

- **Native**: Best for CPU-bound parsing tasks
- **WASM-GC**: Excellent JIT optimization, competitive with native
- **JS**: Slowest for parsing, but good string operations

### Why mizchi/markdown is slower than cmark

1. **CST overhead**: Preserves whitespace, markers, and positions
2. **Lossless design**: Enables exact roundtrip serialization
3. **Incremental support**: Additional metadata for efficient re-parsing

Despite being slower, mizchi/markdown provides unique features that cmark doesn't:
- Lossless serialization (parse → serialize = original)
- Incremental parsing (30-50x speedup for edits)
- Full position tracking with spans

## Running Benchmarks

```bash
# MoonBit benchmarks
cd benches
moon run . --target js       # JS target
moon run . --target wasm-gc  # WASM-GC target
moon run . --target native   # Native target

# Rust benchmark
cd rust-bench
cargo run --release
```


| Parser          | Target  | small | medium | large |
|-----------------|---------|-------|--------|-------|
| mizchi/markdown | Native  |    81 |    315 |  1547 |
| rami3l/cmark    | WASM-GC |    46 |    120 |   416 |
| rami3l/cmark    | Native  |    26 |    105 |   513 |
| markdown-rs     | Rust    |   202 |    621 |  3674 |