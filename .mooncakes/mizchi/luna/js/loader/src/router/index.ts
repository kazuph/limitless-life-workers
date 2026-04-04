/*! luna router v1 - Client-side routing module */

// Hybrid router (fetch + swap, Turbo/HTMX style)
export {
  HybridRouter,
  getHybridRouter,
  startHybridRouter,
  type HybridRouterOptions,
} from './hybrid';

// SPA router (client-side rendering)
export {
  SpaRouter,
  getSpaRouter,
  createSpaRouter,
  type SpaRouterOptions,
  type SpaRouteConfig,
  type RouteParams,
} from './spa';

// Scroll management
export {
  ScrollManager,
  getScrollManager,
  enableNativeScrollRestoration,
  disableNativeScrollRestoration,
  type ScrollPosition,
  type ScrollManagerOptions,
} from './scroll';
