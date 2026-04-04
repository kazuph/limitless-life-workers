/**
 * Web Components SSR - Main Entry
 *
 * サーバー/クライアント共通のエクスポート
 */

// Types
export type {
  State,
  EventPayload,
  Handler,
  RenderFn,
  CSSStrategy,
  ComponentDef,
  SSROptions,
  RenderOptions,
  RegisterOptions,
  SimpleComponentDef,
  HandlerResult,
} from './types.js';

// Server (純粋関数、DOM依存なし)
export {
  escapeAttr,
  escapeHtml,
  escapeJson,
  createSSRRenderer,
  renderDocument,
  renderComponentInline,
  renderComponentLink,
} from './server.js';

// Client (ブラウザ環境のみ)
export {
  registerComponent,
  registerComponents,
  defineComponent,
  hydrateElement,
  clearStyleSheetCache,
  getRegisteredComponents,
} from './client.js';
