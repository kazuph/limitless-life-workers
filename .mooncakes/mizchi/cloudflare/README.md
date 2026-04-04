# cloudflare.mbt

MoonBit bindings for Cloudflare Workers APIs

## Features

- **KV (Workers KV)**: Key-value storage
- **D1**: Serverless SQL database
- **R2**: Object storage
- **Durable Objects**: Stateful serverless objects
- **Queues**: Message queues

## Installation

This package depends on `mizchi/js`. Make sure to add both dependencies to your `moon.mod.json`:

```json
{
  "deps": {
    "mizchi/js": "0.8.2",
    "mizchi/cloudflare": "0.1.0"
  }
}
```

## Usage

See examples in `examples/cfw/` directory.

## Development

```bash
# Install dependencies
pnpm install

# Run development server
pnpm dev

# Run tests
pnpm test
```

## Testing

Tests are located in `e2e/cloudflare/` and use Vitest with `@cloudflare/vitest-pool-workers`.

## License

MIT
