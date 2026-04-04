/**
 * Web Components SSR - Server Entry
 *
 * サーバーサイド専用。DOM依存なし。
 * Node.js / Deno / Bun / MoonBit(WASM) で動作可能。
 */

// Types (サーバーで必要なもののみ)
export type {
  State,
  ComponentDef,
  SSROptions,
  RenderOptions,
  CSSStrategy,
  RenderFn,
} from './types.js';

// Server functions
export {
  escapeAttr,
  escapeHtml,
  escapeJson,
  createSSRRenderer,
  renderDocument,
  renderComponentInline,
  renderComponentLink,
} from './server.js';

// Re-export DocumentOptions type
export type { DocumentOptions } from './server.js';
