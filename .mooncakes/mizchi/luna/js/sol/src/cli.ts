#!/usr/bin/env node
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

// Set assets directory for MoonBit loader
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Assets are at js/sol/assets/ relative to dist/cli.js
// dist/cli.js -> js/sol/dist/cli.js
// assets -> js/sol/assets/
(globalThis as any).__sol_assets_dir = join(__dirname, "..", "assets");

// Worker script is at dist/worker.js relative to dist/cli.js
(globalThis as any).__sol_worker_script = join(__dirname, "worker.js");

// Import MoonBit CLI (dynamic import to ensure globalThis is set first)
await import("../../../target/js/release/build/sol/cli/cli");
