/**
 * Signal Propagation Tests
 *
 * Shadow Root 境界を越えた状態変更の伝搬を検証
 */

import { describe, test, expect, beforeEach, afterEach } from 'vitest';
import {
  registerComponent,
  defineComponent,
  clearStyleSheetCache,
} from '../src/client.js';
import type { ComponentDef } from '../src/types.js';

// ============================================
// Test Utilities
// ============================================

let container: HTMLDivElement;
let componentCounter = 0;

beforeEach(() => {
  container = document.createElement('div');
  container.id = 'test-container';
  document.body.appendChild(container);
  clearStyleSheetCache();
});

afterEach(() => {
  container.remove();
});

// ============================================
// Simple Signal Implementation
// ============================================

type Subscriber<T> = (value: T) => void;

interface Signal<T> {
  get(): T;
  set(value: T): void;
  subscribe(fn: Subscriber<T>): () => void;
}

function createSignal<T>(initial: T): Signal<T> {
  let value = initial;
  const subscribers = new Set<Subscriber<T>>();

  return {
    get: () => value,
    set: (newValue: T) => {
      if (value !== newValue) {
        value = newValue;
        subscribers.forEach((fn) => fn(value));
      }
    },
    subscribe: (fn: Subscriber<T>) => {
      subscribers.add(fn);
      return () => subscribers.delete(fn);
    },
  };
}

// ============================================
// Test: Attribute Propagation
// ============================================

describe('Attribute Propagation (Parent -> Child via attributes)', () => {
  test('Parent updates child attribute, child reflects change', async () => {
    const childName = `attr-child-${++componentCounter}`;
    const parentName = `attr-parent-${++componentCounter}`;

    // Child: observedAttributes で value を監視
    const ChildComponent = defineComponent({
      name: childName,
      styles: ':host { display: block; }',
      initialState: { value: '0' },
      render: (state) => `<span data-testid="child-value">${state.value}</span>`,
      handlers: {},
    });

    // Parent: 子に value 属性を渡す
    const ParentComponent = defineComponent({
      name: parentName,
      styles: ':host { display: block; }',
      initialState: { count: 0 },
      render: (state) => `
        <div>
          <span data-testid="parent-count">${state.count}</span>
          <button data-on-click="increment" data-testid="inc">+</button>
          <${childName} data-value="${state.count}"></${childName}>
        </div>
      `,
      handlers: {
        increment: (state) => ({ count: state.count + 1 }),
      },
    });

    // Child を拡張して attributeChangedCallback を追加
    class ObservableChild extends HTMLElement {
      static observedAttributes = ['data-value'];
      private _state = { value: '0' };

      constructor() {
        super();
        if (!this.shadowRoot) {
          this.attachShadow({ mode: 'open' });
        }
      }

      connectedCallback() {
        this.render();
      }

      attributeChangedCallback(name: string, _oldValue: string, newValue: string) {
        if (name === 'data-value' && newValue !== this._state.value) {
          this._state = { value: newValue };
          this.render();
        }
      }

      private render() {
        if (this.shadowRoot) {
          this.shadowRoot.innerHTML = `<span data-testid="child-value">${this._state.value}</span>`;
        }
      }
    }

    if (!customElements.get(childName)) {
      customElements.define(childName, ObservableChild);
    }
    registerComponent(ParentComponent);

    container.innerHTML = `<${parentName}></${parentName}>`;
    await customElements.whenDefined(parentName);
    await customElements.whenDefined(childName);

    const parent = container.querySelector(parentName)!;
    const getChildValue = () => {
      const child = parent.shadowRoot?.querySelector(childName);
      return child?.shadowRoot?.querySelector('[data-testid="child-value"]')?.textContent;
    };
    const getIncBtn = () =>
      parent.shadowRoot?.querySelector('[data-testid="inc"]') as HTMLButtonElement;

    // 初期状態
    expect(getChildValue()).toBe('0');

    // 親をインクリメント
    getIncBtn()?.click();

    // 子の値も更新される（親の再レンダリングで子のdata-value属性が更新）
    expect(getChildValue()).toBe('1');

    getIncBtn()?.click();
    expect(getChildValue()).toBe('2');
  });
});

// ============================================
// Test: Slot Content Propagation
// ============================================

describe('Slot Content Propagation', () => {
  test('Parent state change updates slot content', async () => {
    const slotChildName = `slot-child-${++componentCounter}`;
    const slotParentName = `slot-parent-${++componentCounter}`;

    // Child: slot で内容を受け取る
    const SlotChild = defineComponent({
      name: slotChildName,
      styles: `
        :host { display: block; border: 1px solid blue; padding: 8px; }
        .wrapper { background: #f0f0f0; }
      `,
      initialState: {},
      render: () => `<div class="wrapper"><slot></slot></div>`,
      handlers: {},
    });

    // Parent: slot に動的内容を渡す
    const SlotParent = defineComponent({
      name: slotParentName,
      styles: ':host { display: block; }',
      initialState: { message: 'Hello' },
      render: (state) => `
        <button data-on-click="toggle" data-testid="toggle">Toggle</button>
        <${slotChildName}>
          <span data-testid="slot-content">${state.message}</span>
        </${slotChildName}>
      `,
      handlers: {
        toggle: (state) => ({
          message: state.message === 'Hello' ? 'World' : 'Hello',
        }),
      },
    });

    registerComponent(SlotChild);
    registerComponent(SlotParent);

    container.innerHTML = `<${slotParentName}></${slotParentName}>`;
    await customElements.whenDefined(slotParentName);
    await customElements.whenDefined(slotChildName);

    const parent = container.querySelector(slotParentName)!;
    const getSlotContent = () => {
      // slot 内容は Light DOM にあるので、親の shadowRoot 内を探す
      return parent.shadowRoot?.querySelector('[data-testid="slot-content"]')?.textContent;
    };
    const getToggleBtn = () =>
      parent.shadowRoot?.querySelector('[data-testid="toggle"]') as HTMLButtonElement;

    expect(getSlotContent()).toBe('Hello');

    getToggleBtn()?.click();
    expect(getSlotContent()).toBe('World');

    getToggleBtn()?.click();
    expect(getSlotContent()).toBe('Hello');
  });
});

// ============================================
// Test: Shared Signal Store
// ============================================

describe('Shared Signal Store (Cross-Component State)', () => {
  test('Multiple components react to shared signal changes', async () => {
    const countSignal = createSignal(0);

    const displayName1 = `signal-display1-${++componentCounter}`;
    const displayName2 = `signal-display2-${++componentCounter}`;
    const controllerName = `signal-controller-${++componentCounter}`;

    // Display components: Signal の値を表示
    class SignalDisplay extends HTMLElement {
      private _unsubscribe?: () => void;

      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        this.render();
        // Signal を購読
        this._unsubscribe = countSignal.subscribe(() => this.render());
      }

      disconnectedCallback() {
        this._unsubscribe?.();
      }

      private render() {
        if (this.shadowRoot) {
          this.shadowRoot.innerHTML = `<span data-testid="value">${countSignal.get()}</span>`;
        }
      }
    }

    // Controller: Signal を更新
    class SignalController extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        this.shadowRoot!.innerHTML = `
          <button data-testid="inc">+</button>
          <button data-testid="dec">-</button>
        `;
        this.shadowRoot!.querySelector('[data-testid="inc"]')!.addEventListener('click', () => {
          countSignal.set(countSignal.get() + 1);
        });
        this.shadowRoot!.querySelector('[data-testid="dec"]')!.addEventListener('click', () => {
          countSignal.set(countSignal.get() - 1);
        });
      }
    }

    if (!customElements.get(displayName1)) {
      customElements.define(displayName1, class extends SignalDisplay {});
    }
    if (!customElements.get(displayName2)) {
      customElements.define(displayName2, class extends SignalDisplay {});
    }
    if (!customElements.get(controllerName)) {
      customElements.define(controllerName, SignalController);
    }

    container.innerHTML = `
      <${displayName1}></${displayName1}>
      <${displayName2}></${displayName2}>
      <${controllerName}></${controllerName}>
    `;

    await Promise.all([
      customElements.whenDefined(displayName1),
      customElements.whenDefined(displayName2),
      customElements.whenDefined(controllerName),
    ]);

    const display1 = container.querySelector(displayName1)!;
    const display2 = container.querySelector(displayName2)!;
    const controller = container.querySelector(controllerName)!;

    const getValue1 = () => display1.shadowRoot?.querySelector('[data-testid="value"]')?.textContent;
    const getValue2 = () => display2.shadowRoot?.querySelector('[data-testid="value"]')?.textContent;
    const getIncBtn = () => controller.shadowRoot?.querySelector('[data-testid="inc"]') as HTMLButtonElement;
    const getDecBtn = () => controller.shadowRoot?.querySelector('[data-testid="dec"]') as HTMLButtonElement;

    // 初期状態
    expect(getValue1()).toBe('0');
    expect(getValue2()).toBe('0');

    // Controller でインクリメント
    getIncBtn()?.click();

    // 両方の Display が更新される
    expect(getValue1()).toBe('1');
    expect(getValue2()).toBe('1');

    getIncBtn()?.click();
    expect(getValue1()).toBe('2');
    expect(getValue2()).toBe('2');

    getDecBtn()?.click();
    expect(getValue1()).toBe('1');
    expect(getValue2()).toBe('1');
  });

  test('Nested components with shared signal', async () => {
    const nestedSignal = createSignal({ count: 0, text: 'initial' });

    const innerName = `nested-inner-${++componentCounter}`;
    const outerName = `nested-outer-${++componentCounter}`;

    // Inner: Signal の一部を表示（Outerが再レンダリングしないのでsubscriptionで更新）
    class InnerComponent extends HTMLElement {
      private _unsubscribe?: () => void;

      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        this.render();
        this._unsubscribe = nestedSignal.subscribe(() => this.render());
      }

      disconnectedCallback() {
        this._unsubscribe?.();
      }

      private render() {
        const state = nestedSignal.get();
        this.shadowRoot!.innerHTML = `
          <div data-testid="inner-count">${state.count}</div>
          <div data-testid="inner-text">${state.text}</div>
        `;
      }
    }

    // Outer: Signal を更新するが、自身は再レンダリングしない
    // ボタンは最初に1回だけレンダリングし、以降は Inner のみが更新
    class OuterComponent extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        // 初回レンダリングのみ（Innerへの変更伝搬はSignal経由）
        this.shadowRoot!.innerHTML = `
          <div data-testid="outer-count-container"></div>
          <button data-testid="inc-count">+Count</button>
          <button data-testid="change-text">Change Text</button>
          <${innerName}></${innerName}>
        `;
        this.attachListeners();
        this.updateCountDisplay();

        // count 表示だけを更新
        nestedSignal.subscribe(() => this.updateCountDisplay());
      }

      private updateCountDisplay() {
        const container = this.shadowRoot?.querySelector('[data-testid="outer-count-container"]');
        if (container) {
          container.textContent = String(nestedSignal.get().count);
        }
      }

      private attachListeners() {
        this.shadowRoot?.querySelector('[data-testid="inc-count"]')?.addEventListener('click', () => {
          const current = nestedSignal.get();
          nestedSignal.set({ ...current, count: current.count + 1 });
        });
        this.shadowRoot?.querySelector('[data-testid="change-text"]')?.addEventListener('click', () => {
          const current = nestedSignal.get();
          nestedSignal.set({ ...current, text: current.text === 'initial' ? 'changed' : 'initial' });
        });
      }
    }

    if (!customElements.get(innerName)) {
      customElements.define(innerName, InnerComponent);
    }
    if (!customElements.get(outerName)) {
      customElements.define(outerName, OuterComponent);
    }

    container.innerHTML = `<${outerName}></${outerName}>`;

    await Promise.all([
      customElements.whenDefined(outerName),
      customElements.whenDefined(innerName),
    ]);

    const outer = container.querySelector(outerName)!;

    const getOuterCount = () => outer.shadowRoot?.querySelector('[data-testid="outer-count-container"]')?.textContent;
    const getInnerCount = () => {
      const inner = outer.shadowRoot?.querySelector(innerName);
      return inner?.shadowRoot?.querySelector('[data-testid="inner-count"]')?.textContent;
    };
    const getInnerText = () => {
      const inner = outer.shadowRoot?.querySelector(innerName);
      return inner?.shadowRoot?.querySelector('[data-testid="inner-text"]')?.textContent;
    };
    const getIncCountBtn = () =>
      outer.shadowRoot?.querySelector('[data-testid="inc-count"]') as HTMLButtonElement;
    const getChangeTextBtn = () =>
      outer.shadowRoot?.querySelector('[data-testid="change-text"]') as HTMLButtonElement;

    // 初期状態
    expect(getOuterCount()).toBe('0');
    expect(getInnerCount()).toBe('0');
    expect(getInnerText()).toBe('initial');

    // count を更新
    getIncCountBtn()?.click();

    // outer と inner 両方が更新
    expect(getOuterCount()).toBe('1');
    expect(getInnerCount()).toBe('1');
    expect(getInnerText()).toBe('initial');

    // text を更新
    getChangeTextBtn()?.click();
    expect(getOuterCount()).toBe('1');
    expect(getInnerCount()).toBe('1');
    expect(getInnerText()).toBe('changed');
  });
});

// ============================================
// Test: Custom Events (Child -> Parent)
// ============================================

describe('Custom Events (Child -> Parent)', () => {
  test('Child emits custom event, parent catches it', async () => {
    const emitterName = `event-emitter-${++componentCounter}`;
    const listenerName = `event-listener-${++componentCounter}`;

    // Emitter: クリックでカスタムイベントを発火
    class EventEmitter extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        this.shadowRoot!.innerHTML = `<button data-testid="emit-btn">Emit</button>`;
        this.shadowRoot!.querySelector('[data-testid="emit-btn"]')!.addEventListener('click', () => {
          // composed: true で Shadow DOM を越える
          this.dispatchEvent(
            new CustomEvent('child-event', {
              bubbles: true,
              composed: true,
              detail: { value: 42 },
            })
          );
        });
      }
    }

    // Listener: カスタムイベントを受け取る
    class EventListener extends HTMLElement {
      private _received: number[] = [];

      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        this.render();
        // composed イベントは host element で受け取れる
        // @ts-expect-error - custom event type not in HTMLElementEventMap
        this.addEventListener('child-event', (e: CustomEvent) => {
          this._received.push(e.detail.value);
          this.render();
        });
      }

      private render() {
        this.shadowRoot!.innerHTML = `
          <div data-testid="received">${this._received.join(',')}</div>
          <${emitterName}></${emitterName}>
        `;
      }
    }

    if (!customElements.get(emitterName)) {
      customElements.define(emitterName, EventEmitter);
    }
    if (!customElements.get(listenerName)) {
      customElements.define(listenerName, EventListener);
    }

    container.innerHTML = `<${listenerName}></${listenerName}>`;

    await Promise.all([
      customElements.whenDefined(listenerName),
      customElements.whenDefined(emitterName),
    ]);

    const listener = container.querySelector(listenerName)!;

    const getReceived = () => listener.shadowRoot?.querySelector('[data-testid="received"]')?.textContent;
    const getEmitBtn = () => {
      const emitter = listener.shadowRoot?.querySelector(emitterName);
      return emitter?.shadowRoot?.querySelector('[data-testid="emit-btn"]') as HTMLButtonElement;
    };

    // 初期状態
    expect(getReceived()).toBe('');

    // イベント発火
    getEmitBtn()?.click();
    expect(getReceived()).toBe('42');

    getEmitBtn()?.click();
    expect(getReceived()).toBe('42,42');
  });
});

// ============================================
// Test: MutationObserver Pattern
// ============================================

describe('MutationObserver Pattern', () => {
  test('Component observes DOM mutations in light DOM', async () => {
    const observerName = `mutation-observer-${++componentCounter}`;

    class MutationObserverComponent extends HTMLElement {
      private _observer?: MutationObserver;
      private _mutations: string[] = [];

      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        this.render();

        // Light DOM の変更を監視
        this._observer = new MutationObserver((mutations) => {
          for (const mutation of mutations) {
            if (mutation.type === 'childList') {
              this._mutations.push(`added:${mutation.addedNodes.length},removed:${mutation.removedNodes.length}`);
            }
          }
          this.render();
        });

        this._observer.observe(this, {
          childList: true,
          subtree: false,
        });
      }

      disconnectedCallback() {
        this._observer?.disconnect();
      }

      private render() {
        this.shadowRoot!.innerHTML = `
          <div data-testid="mutations">${this._mutations.join(';')}</div>
          <slot></slot>
        `;
      }
    }

    if (!customElements.get(observerName)) {
      customElements.define(observerName, MutationObserverComponent);
    }

    container.innerHTML = `<${observerName}></${observerName}>`;
    await customElements.whenDefined(observerName);

    const observer = container.querySelector(observerName)!;
    const getMutations = () => observer.shadowRoot?.querySelector('[data-testid="mutations"]')?.textContent;

    expect(getMutations()).toBe('');

    // Light DOM に要素を追加
    const child = document.createElement('div');
    child.textContent = 'Dynamic child';
    observer.appendChild(child);

    // MutationObserver は非同期なので少し待つ
    await new Promise((r) => setTimeout(r, 10));

    expect(getMutations()).toBe('added:1,removed:0');

    // 要素を削除
    observer.removeChild(child);
    await new Promise((r) => setTimeout(r, 10));

    expect(getMutations()).toBe('added:1,removed:0;added:0,removed:1');
  });
});
