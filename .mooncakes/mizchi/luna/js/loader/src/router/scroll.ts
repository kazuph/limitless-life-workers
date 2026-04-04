/*! luna router-scroll v1 - Scroll Position Management */

export interface ScrollPosition {
  x: number;
  y: number;
}

export interface ScrollManagerOptions {
  /** Storage key prefix (default: "luna:scroll:") */
  storagePrefix?: string;
  /** Use sessionStorage for persistence (default: true) */
  useStorage?: boolean;
  /** Max entries to store (default: 50) */
  maxEntries?: number;
}

/**
 * ScrollManager handles scroll position saving and restoration
 * - Memory storage for current session
 * - Optional sessionStorage persistence
 * - Automatic cleanup of old entries
 */
export class ScrollManager {
  private options: Required<ScrollManagerOptions>;
  private positions = new Map<string, ScrollPosition>();

  constructor(options: ScrollManagerOptions = {}) {
    this.options = {
      storagePrefix: options.storagePrefix ?? 'luna:scroll:',
      useStorage: options.useStorage ?? true,
      maxEntries: options.maxEntries ?? 50,
    };

    // Load persisted positions
    if (this.options.useStorage) {
      this.loadFromStorage();
    }
  }

  /**
   * Save scroll position for a path
   */
  save(path: string): void {
    const position: ScrollPosition = {
      x: window.scrollX,
      y: window.scrollY,
    };

    this.positions.set(path, position);

    // Persist to storage
    if (this.options.useStorage) {
      this.saveToStorage(path, position);
    }

    // Cleanup if too many entries
    if (this.positions.size > this.options.maxEntries) {
      this.cleanup();
    }
  }

  /**
   * Restore scroll position for a path
   */
  restore(path: string): boolean {
    const position = this.positions.get(path);
    if (position) {
      window.scrollTo(position.x, position.y);
      return true;
    }
    return false;
  }

  /**
   * Get scroll position for a path
   */
  get(path: string): ScrollPosition | undefined {
    return this.positions.get(path);
  }

  /**
   * Clear all saved positions
   */
  clear(): void {
    this.positions.clear();
    if (this.options.useStorage) {
      this.clearStorage();
    }
  }

  /**
   * Scroll to top of page
   */
  scrollToTop(behavior: ScrollBehavior = 'auto'): void {
    window.scrollTo({ top: 0, left: 0, behavior });
  }

  /**
   * Scroll to element by selector or hash
   */
  scrollToElement(selector: string, behavior: ScrollBehavior = 'auto'): boolean {
    const element = document.querySelector(selector);
    if (element) {
      element.scrollIntoView({ behavior });
      return true;
    }
    return false;
  }

  /**
   * Handle hash navigation
   */
  scrollToHash(hash: string): boolean {
    if (!hash || hash === '#') return false;

    // Try ID first
    const element = document.getElementById(hash.slice(1));
    if (element) {
      element.scrollIntoView();
      return true;
    }

    // Try querySelector for other selectors
    return this.scrollToElement(hash);
  }

  private loadFromStorage(): void {
    try {
      const keys = Object.keys(sessionStorage).filter(k =>
        k.startsWith(this.options.storagePrefix)
      );

      for (const key of keys) {
        const path = key.slice(this.options.storagePrefix.length);
        const value = sessionStorage.getItem(key);
        if (value) {
          try {
            const position = JSON.parse(value) as ScrollPosition;
            if (typeof position.x === 'number' && typeof position.y === 'number') {
              this.positions.set(path, position);
            }
          } catch {
            // Invalid JSON, skip
          }
        }
      }
    } catch {
      // Storage not available
    }
  }

  private saveToStorage(path: string, position: ScrollPosition): void {
    try {
      const key = this.options.storagePrefix + path;
      sessionStorage.setItem(key, JSON.stringify(position));
    } catch {
      // Storage full or not available
    }
  }

  private clearStorage(): void {
    try {
      const keys = Object.keys(sessionStorage).filter(k =>
        k.startsWith(this.options.storagePrefix)
      );
      keys.forEach(k => sessionStorage.removeItem(k));
    } catch {
      // Storage not available
    }
  }

  private cleanup(): void {
    // Remove oldest entries (simple FIFO)
    const entries = Array.from(this.positions.entries());
    const toRemove = entries.slice(0, entries.length - this.options.maxEntries);

    for (const [path] of toRemove) {
      this.positions.delete(path);
      if (this.options.useStorage) {
        try {
          sessionStorage.removeItem(this.options.storagePrefix + path);
        } catch {
          // Ignore
        }
      }
    }
  }
}

// Global singleton
let globalScrollManager: ScrollManager | null = null;

/**
 * Get or create the scroll manager
 */
export function getScrollManager(options?: ScrollManagerOptions): ScrollManager {
  if (!globalScrollManager) {
    globalScrollManager = new ScrollManager(options);
  }
  return globalScrollManager;
}

/**
 * Enable browser's native scroll restoration
 */
export function enableNativeScrollRestoration(): void {
  if ('scrollRestoration' in history) {
    history.scrollRestoration = 'auto';
  }
}

/**
 * Disable browser's native scroll restoration (for manual control)
 */
export function disableNativeScrollRestoration(): void {
  if ('scrollRestoration' in history) {
    history.scrollRestoration = 'manual';
  }
}
