/**
 * Luna HMR Client
 *
 * Dev-only module injected by sol dev server.
 * Uses existing __LUNA_* APIs from loader.ts - no changes to prod loader needed.
 */

// Make this file a module so declare global works
export {};

declare global {
  interface Window {
    __LUNA_STATE__: Record<string, unknown>;
    __LUNA_HYDRATE__: (el: Element) => Promise<void>;
    __LUNA_UNLOAD__: (id: string) => boolean;
    __LUNA_SCAN__: () => void;
    __HMR_WS__?: WebSocket;
  }
}

interface HMRMessage {
  type: 'update' | 'full-reload' | 'error' | 'connected';
  islands?: string[];
  error?: string;
  timestamp?: number;
}

const log = (msg: string, ...args: unknown[]) => {
  console.log(`[HMR] ${msg}`, ...args);
};

const logError = (msg: string, ...args: unknown[]) => {
  console.error(`[HMR] ${msg}`, ...args);
};

/**
 * Handle island updates - unload and rehydrate affected islands
 */
const handleUpdate = async (islands: string[], timestamp?: number) => {
  const t = timestamp ?? Date.now();

  // Handle wildcard: update all islands
  let targetIslands = islands;
  if (islands.length === 1 && islands[0] === '*') {
    const allIslands = document.querySelectorAll('[luna\\:id]');
    targetIslands = Array.from(allIslands).map(el => el.getAttribute('luna:id')!).filter(Boolean);
    log(`Updating all islands: ${targetIslands.join(', ')}`);
  }

  for (const id of targetIslands) {
    const el = document.querySelector(`[luna\\:id="${id}"]`);
    if (!el) {
      log(`Island "${id}" not found in DOM, skipping`);
      continue;
    }

    // 1. Save current state from loader's state map
    const currentState = window.__LUNA_STATE__?.[id];

    // 2. Unload the island (removes from loaded set)
    window.__LUNA_UNLOAD__?.(id);

    // 3. Update URL with cache bust
    const url = el.getAttribute('luna:url');
    if (url) {
      const baseUrl = url.split('?')[0];
      el.setAttribute('luna:url', `${baseUrl}?t=${t}`);
    }

    // 4. Restore state so hydrate picks it up
    if (currentState !== undefined && window.__LUNA_STATE__) {
      window.__LUNA_STATE__[id] = currentState;
    }

    // 5. Rehydrate
    try {
      await window.__LUNA_HYDRATE__?.(el);
      log(`Updated: ${id}`);
    } catch (e) {
      logError(`Failed to rehydrate "${id}":`, e);
    }
  }
};

/**
 * Show error overlay for build errors
 */
const showErrorOverlay = (error?: string) => {
  // Remove existing overlay
  const existing = document.getElementById('__hmr-error-overlay');
  if (existing) existing.remove();

  if (!error) return;

  const overlay = document.createElement('div');
  overlay.id = '__hmr-error-overlay';
  overlay.innerHTML = `
    <style>
      #__hmr-error-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.85);
        color: #ff6b6b;
        font-family: monospace;
        font-size: 14px;
        padding: 24px;
        z-index: 99999;
        overflow: auto;
      }
      #__hmr-error-overlay h2 {
        color: #ff6b6b;
        margin: 0 0 16px 0;
        font-size: 18px;
      }
      #__hmr-error-overlay pre {
        background: #1a1a1a;
        padding: 16px;
        border-radius: 4px;
        overflow-x: auto;
        white-space: pre-wrap;
        word-break: break-word;
      }
      #__hmr-error-overlay button {
        position: absolute;
        top: 16px;
        right: 16px;
        background: #333;
        color: #fff;
        border: none;
        padding: 8px 16px;
        cursor: pointer;
        border-radius: 4px;
      }
      #__hmr-error-overlay button:hover {
        background: #444;
      }
    </style>
    <button onclick="this.parentElement.remove()">Close</button>
    <h2>Build Error</h2>
    <pre>${escapeHtml(error)}</pre>
  `;
  document.body.appendChild(overlay);
};

const escapeHtml = (str: string) => {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
};

/**
 * Hide error overlay (on successful rebuild)
 */
const hideErrorOverlay = () => {
  const existing = document.getElementById('__hmr-error-overlay');
  if (existing) existing.remove();
};

// HMR WebSocket port (must match sol dev server)
const HMR_PORT = 24678;

/**
 * Connect to HMR WebSocket server
 */
const connect = () => {
  // Connect to HMR server on dedicated port
  const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
  const ws = new WebSocket(`${protocol}//${location.hostname}:${HMR_PORT}`);

  window.__HMR_WS__ = ws;

  ws.onopen = () => {
    log('Connected');
    hideErrorOverlay();
  };

  ws.onmessage = async (e) => {
    let msg: HMRMessage;
    try {
      msg = JSON.parse(e.data);
    } catch {
      logError('Invalid message:', e.data);
      return;
    }

    switch (msg.type) {
      case 'connected':
        log('Server ready');
        break;

      case 'update':
        hideErrorOverlay();
        if (msg.islands && msg.islands.length > 0) {
          await handleUpdate(msg.islands, msg.timestamp);
        } else {
          // No specific islands - scan all
          window.__LUNA_SCAN__?.();
          log('Rescanned all islands');
        }
        break;

      case 'full-reload':
        log('Full reload requested');
        location.reload();
        break;

      case 'error':
        showErrorOverlay(msg.error);
        break;
    }
  };

  ws.onclose = () => {
    log('Disconnected, reconnecting in 1s...');
    window.__HMR_WS__ = undefined;
    setTimeout(connect, 1000);
  };

  ws.onerror = (e) => {
    logError('WebSocket error:', e);
  };
};

// Start connection
connect();

// Expose for debugging
(window as unknown as Record<string, unknown>).__HMR_UPDATE__ = handleUpdate;
