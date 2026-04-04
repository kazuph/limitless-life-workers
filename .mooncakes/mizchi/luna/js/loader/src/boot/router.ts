/*! luna boot/router v2 - SPA-aware CSR router */

import { getLoader, RouteMatch, SegmentRef } from './loader';

export interface RouterOptions {
  /** Selector for interceptable links (default: "a[href]") */
  linkSelector?: string;
  /** Attribute to check for internal links (default: none) */
  linkAttribute?: string;
  /** Enable prefetch on hover (default: true) */
  prefetchOnHover?: boolean;
  /** Prefetch delay in ms (default: 50) */
  prefetchDelay?: number;
  /** Enable SPA mode for specific segments */
  spaSegments?: string[];
}

export interface NavigateEvent {
  path: string;
  params: Record<string, string>;
  segment?: string;
  isSpa?: boolean;
  isPopState: boolean;
}

export type NavigateHandler = (event: NavigateEvent) => void | Promise<void>;

/**
 * MinimalRouter handles link interception and navigation
 * Supports SPA fallback for hierarchical manifests
 */
export class MinimalRouter {
  private options: Required<RouterOptions>;
  private handlers: Set<NavigateHandler> = new Set();
  private prefetchTimers = new Map<string, number>();
  private currentMatch: RouteMatch | null = null;

  constructor(options: RouterOptions = {}) {
    this.options = {
      linkSelector: options.linkSelector ?? 'a[href]',
      linkAttribute: options.linkAttribute ?? '',
      prefetchOnHover: options.prefetchOnHover ?? true,
      prefetchDelay: options.prefetchDelay ?? 50,
      spaSegments: options.spaSegments ?? [],
    };
  }

  /**
   * Start intercepting links
   */
  start(): void {
    document.addEventListener('click', this.handleClick);
    if (this.options.prefetchOnHover) {
      document.addEventListener('mouseenter', this.handleHover, { capture: true });
      document.addEventListener('mouseleave', this.handleLeave, { capture: true });
    }
    window.addEventListener('popstate', this.handlePopState);
  }

  /**
   * Stop intercepting links
   */
  stop(): void {
    document.removeEventListener('click', this.handleClick);
    document.removeEventListener('mouseenter', this.handleHover, { capture: true });
    document.removeEventListener('mouseleave', this.handleLeave, { capture: true });
    window.removeEventListener('popstate', this.handlePopState);
  }

  /**
   * Register a navigation handler
   */
  onNavigate(handler: NavigateHandler): () => void {
    this.handlers.add(handler);
    return () => this.handlers.delete(handler);
  }

  /**
   * Navigate to a path
   */
  async navigate(path: string, options: { replace?: boolean } = {}): Promise<void> {
    const loader = getLoader();

    // Match path and load chunks
    const match = await loader.matchPath(path);
    if (!match) {
      // No match - let browser handle it (404)
      window.location.href = path;
      return;
    }

    this.currentMatch = match;

    // Load required chunks
    const missing = match.chunks.filter(c => !loader.isLoaded(c));
    await Promise.all(missing.map(c => loader.loadChunk(c)));

    // Update history
    if (options.replace) {
      history.replaceState({ luna: true, match }, '', path);
    } else {
      history.pushState({ luna: true, match }, '', path);
    }

    // Notify handlers
    await this.notifyHandlers({
      path,
      params: match.params,
      segment: match.segment,
      isSpa: match.isSpa,
      isPopState: false,
    });
  }

  /**
   * Prefetch a path (load chunks without navigating)
   */
  prefetch(path: string): void {
    const loader = getLoader();
    loader.prefetch(path);

    // Also prefetch segment manifest if hierarchical
    const segmentInfo = loader.getSegmentInfo(path);
    if (segmentInfo) {
      const segment = path.split('/').filter(Boolean)[0];
      if (segment) {
        loader.prefetchSegment(segment);
      }
    }
  }

  /**
   * Get current route match info
   */
  getCurrentMatch(): RouteMatch | null {
    return this.currentMatch;
  }

  /**
   * Get current route params
   */
  getParams(): Record<string, string> {
    return this.currentMatch?.params ?? {};
  }

  /**
   * Check if current route is in SPA mode
   */
  isSpaRoute(): boolean {
    return this.currentMatch?.isSpa ?? false;
  }

  /**
   * Get segment info for current route
   */
  getSegmentInfo(path?: string): SegmentRef | null {
    const loader = getLoader();
    return loader.getSegmentInfo(path ?? window.location.pathname);
  }

  /**
   * Check if a path should use SPA fallback
   */
  shouldUseSpaFallback(path: string): boolean {
    const loader = getLoader();
    const segmentInfo = loader.getSegmentInfo(path);
    return segmentInfo?.spa ?? false;
  }

  private handleClick = (e: MouseEvent): void => {
    const target = e.target as Element | null;
    const link = target?.closest<HTMLAnchorElement>(this.options.linkSelector);
    if (!link) return;

    // Check link attribute if specified
    if (this.options.linkAttribute && !link.hasAttribute(this.options.linkAttribute)) {
      return;
    }

    const href = link.getAttribute('href');
    if (!href) return;

    // Skip external links
    if (!this.isInternalLink(href)) return;

    // Skip if modifier key pressed
    if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;

    // Skip if target specified
    if (link.getAttribute('target')) return;

    // Check if this segment is SPA-enabled
    const segmentInfo = this.getSegmentInfo(href);
    const currentSegment = this.getSegmentInfo();

    // If navigating within same SPA segment, use client-side routing
    // If navigating to/from non-SPA segment, let browser handle it
    const isSpaNavigation = segmentInfo?.spa ||
      currentSegment?.spa ||
      this.options.spaSegments.some(s => href.startsWith(`/${s}/`));

    if (!isSpaNavigation && !getLoader().isHierarchical()) {
      // Not a SPA navigation and not hierarchical - use traditional navigation
      // Only intercept if we have matching routes
      const loader = getLoader();
      const chunks = loader.getChunksForPath(href);
      if (chunks.length === 0) return;
    }

    e.preventDefault();
    const replace = link.hasAttribute('data-replace');
    this.navigate(href, { replace });
  };

  private handleHover = (e: MouseEvent): void => {
    const target = e.target as Element | null;
    if (!target?.closest) return;

    const link = target.closest<HTMLAnchorElement>(this.options.linkSelector);
    if (!link) return;

    // Check link attribute if specified
    if (this.options.linkAttribute && !link.hasAttribute(this.options.linkAttribute)) {
      return;
    }

    const href = link.getAttribute('href');
    if (!href || !this.isInternalLink(href)) return;

    // Delay prefetch to avoid unnecessary loads
    const timer = window.setTimeout(() => {
      this.prefetch(href);
      this.prefetchTimers.delete(href);
    }, this.options.prefetchDelay);

    this.prefetchTimers.set(href, timer);
  };

  private handleLeave = (e: MouseEvent): void => {
    const target = e.target as Element | null;
    if (!target?.closest) return;

    const link = target.closest<HTMLAnchorElement>(this.options.linkSelector);
    if (!link) return;

    const href = link.getAttribute('href');
    if (!href) return;

    // Cancel pending prefetch
    const timer = this.prefetchTimers.get(href);
    if (timer) {
      clearTimeout(timer);
      this.prefetchTimers.delete(href);
    }
  };

  private handlePopState = async (e: PopStateEvent): Promise<void> => {
    const path = window.location.pathname;
    const loader = getLoader();

    // Try to get match from state
    let match = e.state?.match as RouteMatch | undefined;

    // If no match in state, resolve it
    if (!match) {
      match = await loader.matchPath(path) ?? undefined;
    }

    if (match) {
      this.currentMatch = match;
      await loader.loadForPath(path);

      await this.notifyHandlers({
        path,
        params: match.params,
        segment: match.segment,
        isSpa: match.isSpa,
        isPopState: true,
      });
    } else {
      // No match - reload the page
      window.location.reload();
    }
  };

  private async notifyHandlers(event: NavigateEvent): Promise<void> {
    const handlers = Array.from(this.handlers);
    for (let i = 0; i < handlers.length; i++) {
      await handlers[i](event);
    }
  }

  private isInternalLink(href: string): boolean {
    if (href.startsWith('http://') || href.startsWith('https://') || href.startsWith('//')) {
      try {
        const url = new URL(href, window.location.origin);
        return url.origin === window.location.origin;
      } catch {
        return false;
      }
    }
    // Relative or absolute path
    return href.startsWith('/') || !href.includes(':');
  }
}

// Global singleton instance
let globalRouter: MinimalRouter | null = null;

/**
 * Get or create the global router instance
 */
export function getRouter(options?: RouterOptions): MinimalRouter {
  if (!globalRouter) {
    globalRouter = new MinimalRouter(options);
  }
  return globalRouter;
}

/**
 * Start the global router
 */
export function startRouter(options?: RouterOptions): MinimalRouter {
  const router = getRouter(options);
  router.start();
  return router;
}

// Expose on window for debugging
declare global {
  interface Window {
    __LUNA_ROUTER__?: MinimalRouter;
  }
}

if (typeof window !== 'undefined') {
  window.__LUNA_ROUTER__ = getRouter();
}
