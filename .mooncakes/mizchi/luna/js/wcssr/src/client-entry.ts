/**
 * Web Components SSR - Client Entry
 *
 * ブラウザ専用。Hydration とイベント処理。
 */

// Types (クライアントで必要なもののみ)
export type {
  State,
  EventPayload,
  Handler,
  RenderFn,
  ComponentDef,
  RegisterOptions,
  CSSStrategy,
} from './types.js';

// Client functions
export {
  registerComponent,
  registerComponents,
  defineComponent,
  hydrateElement,
  clearStyleSheetCache,
  getRegisteredComponents,
} from './client.js';

// Parts (for MoonBit FFI integration)
export {
  hydratePartsFromElement,
  NodePart,
  AttributePart,
  ChildNodePart,
  PropertyPart,
  PartGroup,
} from './parts.js';

// Global API for browser (for wc-loader)
import {
  registerComponent,
  registerComponents,
  hydrateElement,
} from './client.js';
import { hydratePartsFromElement } from './parts.js';

if (typeof window !== 'undefined') {
  (window as any).__WCSSR__ = {
    registerComponent,
    registerComponents,
    hydrateElement,
    hydratePartsFromElement,
  };
}
