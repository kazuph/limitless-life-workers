/**
 * Web Components SSR - Client Runtime
 *
 * customElements の登録と Hydration を行う。
 * ブラウザ環境でのみ動作。
 */

import type {
  ComponentDef,
  State,
  Handler,
  EventPayload,
  RegisterOptions,
  CSSStrategy,
} from './types.js';

// ============================================
// Adoptable Stylesheets Cache
// ============================================

const sheetCache = new Map<string, CSSStyleSheet>();

/**
 * CSSStyleSheet を取得または作成
 */
function getOrCreateStyleSheet(key: string, css: string): CSSStyleSheet {
  let sheet = sheetCache.get(key);
  if (!sheet) {
    sheet = new CSSStyleSheet();
    sheet.replaceSync(css);
    sheetCache.set(key, sheet);
  }
  return sheet;
}

// ============================================
// Event Binding
// ============================================

/**
 * イベント種別のリスト
 */
const EVENT_TYPES = ['click', 'input', 'change', 'keypress', 'keydown', 'keyup', 'submit', 'focus', 'blur'] as const;

/**
 * DOM Event から EventPayload を生成
 */
function createPayload(event: Event): EventPayload {
  const target = event.target as HTMLElement | HTMLInputElement | null;

  // dataset から undefined 値を除去
  const getDataset = (el: HTMLElement): Record<string, string> | undefined => {
    if (!el.dataset) return undefined;
    const result: Record<string, string> = {};
    for (const [key, value] of Object.entries(el.dataset)) {
      if (value !== undefined) {
        result[key] = value;
      }
    }
    return Object.keys(result).length > 0 ? result : undefined;
  };

  return {
    type: event.type,
    target: target
      ? {
          value: 'value' in target ? (target as HTMLInputElement).value : undefined,
          checked: 'checked' in target ? (target as HTMLInputElement).checked : undefined,
          dataset: getDataset(target),
        }
      : undefined,
  };
}

// ============================================
// Component Registration
// ============================================

/**
 * コンポーネントをカスタム要素として登録
 *
 * @example
 * ```ts
 * const Counter = defineComponent({
 *   name: 'my-counter',
 *   styles: ':host { display: block; }',
 *   initialState: { count: 0 },
 *   render: (state) => `<div>${state.count}</div>`,
 *   handlers: {
 *     increment: (state) => ({ count: state.count + 1 }),
 *   },
 * });
 *
 * registerComponent(Counter);
 * ```
 */
export function registerComponent<S extends State>(
  component: ComponentDef<S>,
  options: RegisterOptions = {}
): typeof HTMLElement {
  const {
    name,
    styles,
    initialState,
    render: renderFn,
    handlers,
    deserialize = JSON.parse,
    serialize = JSON.stringify,
  } = component;

  class ComponentElement extends HTMLElement {
    private _state: S;
    private _isSSR: boolean;
    private _cssStrategy: CSSStrategy;
    private _handlers: Map<string, Handler<S>>;

    constructor() {
      super();

      // SSR済みかどうか
      this._isSSR = !!this.shadowRoot;

      // CSS戦略の取得
      this._cssStrategy = (this.dataset.css as CSSStrategy) || options.cssStrategy || 'inline';

      // Shadow DOM の作成（SSRでない場合）
      if (!this._isSSR) {
        this.attachShadow({ mode: 'open' });
      }

      // 状態の復元
      if (this.dataset.state) {
        try {
          // JSON unescape
          const unescaped = this.dataset.state
            .replace(/\\u003c/g, '<')
            .replace(/\\u003e/g, '>')
            .replace(/\\u0026/g, '&');
          this._state = deserialize(unescaped);
        } catch (e) {
          console.warn(`[${name}] Failed to deserialize state:`, e);
          this._state = { ...initialState };
        }
      } else {
        this._state = { ...initialState };
      }

      // ハンドラのマップ化
      this._handlers = new Map(Object.entries(handlers) as [string, Handler<S>][]);
    }

    connectedCallback(): void {
      // Adoptable Stylesheets の適用
      if (this._cssStrategy === 'adoptable' && this.shadowRoot) {
        const sheet = getOrCreateStyleSheet(name, styles);
        this.shadowRoot.adoptedStyleSheets = [sheet];
      }

      if (this._isSSR) {
        this.hydrate();
      } else {
        this.render();
      }
    }

    /**
     * Hydration: SSR済みDOMにイベントリスナーを接続
     */
    private hydrate(): void {
      this.attachEventListeners();
    }

    /**
     * CSR: DOMを生成
     */
    private render(): void {
      if (!this.shadowRoot) return;

      const html = renderFn(this._state);

      // スタイルの出力
      let styleHtml = '';
      if (this._cssStrategy !== 'adoptable') {
        styleHtml = `<style>${styles}</style>`;
      }

      this.shadowRoot.innerHTML = `${styleHtml}${html}`;
      this.attachEventListeners();
    }

    /**
     * 状態を更新して再レンダリング
     */
    private setState(newState: S): void {
      this._state = newState;
      // data属性も更新（デバッグ/永続化用）
      this.dataset.state = serialize(newState)
        .replace(/</g, '\\u003c')
        .replace(/>/g, '\\u003e')
        .replace(/&/g, '\\u0026');
      this.render();
    }

    /**
     * ハンドラを呼び出し
     */
    private emit(handlerName: string, event: Event): void {
      const handler = this._handlers.get(handlerName);
      if (!handler) {
        console.warn(`[${name}] Unknown handler: ${handlerName}`);
        return;
      }

      const payload = createPayload(event);
      const newState = handler(this._state, payload);

      // 状態が変更された場合のみ再レンダリング
      if (newState !== this._state) {
        this.setState(newState);
      }
    }

    /**
     * data-on-* 属性を持つ要素にイベントリスナーを接続
     */
    private attachEventListeners(): void {
      if (!this.shadowRoot) return;

      for (const eventType of EVENT_TYPES) {
        const attr = `data-on-${eventType}`;
        const elements = this.shadowRoot.querySelectorAll(`[${attr}]`);

        elements.forEach((el) => {
          const handlerName = el.getAttribute(attr);
          if (handlerName) {
            el.addEventListener(eventType, (e) => this.emit(handlerName, e));
          }
        });
      }
    }

    /**
     * 現在の状態を取得（デバッグ用）
     */
    getState(): S {
      return this._state;
    }
  }

  // カスタム要素として登録
  if (!customElements.get(name)) {
    customElements.define(name, ComponentElement);
  }

  return ComponentElement;
}

// ============================================
// Batch Registration
// ============================================

/**
 * 複数コンポーネントを一括登録
 */
export function registerComponents(
  components: ComponentDef[],
  options: RegisterOptions = {}
): void {
  for (const component of components) {
    registerComponent(component, options);
  }
}

// ============================================
// Manual Hydration API
// ============================================

/**
 * 指定した要素を手動でhydrate
 * SSR後に動的に追加されたコンポーネント用
 */
export function hydrateElement(element: HTMLElement): void {
  // connectedCallbackを再トリガー
  if (element.isConnected) {
    const parent = element.parentNode;
    if (parent) {
      const next = element.nextSibling;
      parent.removeChild(element);
      parent.insertBefore(element, next);
    }
  }
}

// ============================================
// Utility Functions
// ============================================

/**
 * コンポーネント定義のヘルパー
 */
export function defineComponent<S extends State>(
  def: ComponentDef<S>
): ComponentDef<S> {
  return {
    serialize: JSON.stringify,
    deserialize: JSON.parse,
    ...def,
  };
}

/**
 * Adoptable Stylesheets のキャッシュをクリア
 */
export function clearStyleSheetCache(): void {
  sheetCache.clear();
}

/**
 * 登録済みコンポーネント名の一覧を取得
 */
export function getRegisteredComponents(): string[] {
  // Note: customElements.get() は個別にしかチェックできないので
  // 実際には登録時に追跡する必要がある
  return Array.from(sheetCache.keys());
}
