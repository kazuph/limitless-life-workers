/**
 * Web Components SSR - Browser Tests
 *
 * Vitest Browser Mode で実行
 * 実際のブラウザで Declarative Shadow DOM と Hydration をテスト
 */

import { describe, test, expect, beforeEach, afterEach } from 'vitest';
import {
  registerComponent,
  defineComponent,
  clearStyleSheetCache,
} from '../src/client.js';
import { renderComponentInline } from '../src/server.js';
import type { ComponentDef, EventPayload } from '../src/types.js';

// ============================================
// Test Utilities
// ============================================

let container: HTMLDivElement;

beforeEach(() => {
  container = document.createElement('div');
  container.id = 'test-container';
  document.body.appendChild(container);
  clearStyleSheetCache();
});

afterEach(() => {
  container.remove();
  // カスタム要素の登録は解除できないので、テストごとにユニークな名前を使う
});

/**
 * Declarative Shadow DOM を持つ HTML を挿入
 */
function insertDeclarativeShadowDOM(html: string): void {
  // innerHTML では Declarative Shadow DOM は解析されないので、
  // DOMParser + adoptNode を使用
  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html', {
    includeShadowRoots: true,
  } as DOMParserOptions);

  // body の子要素を container に移動
  while (doc.body.firstChild) {
    container.appendChild(document.adoptNode(doc.body.firstChild));
  }
}

// DOMParser の型拡張
interface DOMParserOptions {
  includeShadowRoots?: boolean;
}

// Extend DOMParser to support options argument (newer browser API)
declare global {
  interface DOMParser {
    parseFromString(string: string, type: DOMParserSupportedType, options?: DOMParserOptions): Document;
  }
}

// ============================================
// Test Components
// ============================================

let componentCounter = 0;

function createCounterComponent(): ComponentDef<{ count: number }> {
  const name = `test-counter-${++componentCounter}`;
  return defineComponent({
    name,
    styles: `
      :host { display: block; padding: 8px; border: 1px solid #ccc; }
      .count { font-size: 1.5rem; }
    `,
    initialState: { count: 0 },
    render: (state) => `
      <div class="count" data-testid="count">${state.count}</div>
      <button data-on-click="decrement" data-testid="dec">-</button>
      <button data-on-click="increment" data-testid="inc">+</button>
    `,
    handlers: {
      increment: (state) => ({ count: state.count + 1 }),
      decrement: (state) => ({ count: state.count - 1 }),
    },
  });
}

function createInputComponent(): ComponentDef<{ value: string }> {
  const name = `test-input-${++componentCounter}`;
  return defineComponent({
    name,
    styles: ':host { display: block; }',
    initialState: { value: '' },
    render: (state) => `
      <input type="text" value="${state.value}" data-on-input="updateValue" data-testid="input" />
      <span data-testid="display">${state.value}</span>
    `,
    handlers: {
      updateValue: (state, payload: EventPayload) => ({
        value: payload.target?.value || '',
      }),
    },
  });
}

// ============================================
// Tests: CSR (Client-Side Rendering)
// ============================================

describe('CSR (Client-Side Rendering)', () => {
  test('registerComponent creates custom element', async () => {
    const Counter = createCounterComponent();
    registerComponent(Counter);

    container.innerHTML = `<${Counter.name}></${Counter.name}>`;

    // カスタム要素がアップグレードされるのを待つ
    await customElements.whenDefined(Counter.name);

    const el = container.querySelector(Counter.name);
    expect(el).toBeTruthy();
    expect(el?.shadowRoot).toBeTruthy();
  });

  test('CSR renders initial state', async () => {
    const Counter = createCounterComponent();
    registerComponent(Counter);

    container.innerHTML = `<${Counter.name}></${Counter.name}>`;
    await customElements.whenDefined(Counter.name);

    const el = container.querySelector(Counter.name);
    const countEl = el?.shadowRoot?.querySelector('[data-testid="count"]');
    expect(countEl?.textContent).toBe('0');
  });

  test('CSR handles click events', async () => {
    const Counter = createCounterComponent();
    registerComponent(Counter);

    container.innerHTML = `<${Counter.name}></${Counter.name}>`;
    await customElements.whenDefined(Counter.name);

    const el = container.querySelector(Counter.name)!;
    const getCount = () => el.shadowRoot?.querySelector('[data-testid="count"]')?.textContent;
    const getIncBtn = () => el.shadowRoot?.querySelector('[data-testid="inc"]') as HTMLButtonElement;

    expect(getCount()).toBe('0');

    getIncBtn()?.click();
    expect(getCount()).toBe('1');

    getIncBtn()?.click();
    expect(getCount()).toBe('2');
  });

  test('CSR handles input events', async () => {
    const Input = createInputComponent();
    registerComponent(Input);

    container.innerHTML = `<${Input.name}></${Input.name}>`;
    await customElements.whenDefined(Input.name);

    const el = container.querySelector(Input.name)!;
    const getDisplay = () => el.shadowRoot?.querySelector('[data-testid="display"]')?.textContent;
    const getInput = () => el.shadowRoot?.querySelector('[data-testid="input"]') as HTMLInputElement;

    expect(getDisplay()).toBe('');

    // input イベントをシミュレート
    const inputEl = getInput();
    inputEl.value = 'hello';
    inputEl.dispatchEvent(new Event('input', { bubbles: true }));

    expect(getDisplay()).toBe('hello');
  });
});

// ============================================
// Tests: SSR + Hydration
// ============================================

describe('SSR + Hydration', () => {
  test('Declarative Shadow DOM is parsed correctly', async () => {
    const Counter = createCounterComponent();
    registerComponent(Counter);

    // SSR HTML を生成
    const ssrHtml = renderComponentInline(
      Counter.name,
      Counter.styles,
      JSON.stringify({ count: 5 }),
      Counter.render({ count: 5 })
    );

    // Declarative Shadow DOM を挿入
    insertDeclarativeShadowDOM(ssrHtml);

    const el = container.querySelector(Counter.name);

    // Declarative Shadow DOM が解析されていることを確認
    expect(el?.shadowRoot).toBeTruthy();
  });

  test('Hydration restores state from data-state', async () => {
    const Counter = createCounterComponent();
    registerComponent(Counter);

    const ssrHtml = renderComponentInline(
      Counter.name,
      Counter.styles,
      JSON.stringify({ count: 10 }),
      Counter.render({ count: 10 })
    );

    insertDeclarativeShadowDOM(ssrHtml);
    await customElements.whenDefined(Counter.name);

    const el = container.querySelector(Counter.name);
    const countEl = el?.shadowRoot?.querySelector('[data-testid="count"]');

    // SSR時の値が表示されている
    expect(countEl?.textContent).toBe('10');
  });

  test('Hydration attaches event listeners', async () => {
    const Counter = createCounterComponent();
    registerComponent(Counter);

    const ssrHtml = renderComponentInline(
      Counter.name,
      Counter.styles,
      JSON.stringify({ count: 3 }),
      Counter.render({ count: 3 })
    );

    insertDeclarativeShadowDOM(ssrHtml);
    await customElements.whenDefined(Counter.name);

    const el = container.querySelector(Counter.name)!;
    const getCount = () => el.shadowRoot?.querySelector('[data-testid="count"]')?.textContent;
    const getIncBtn = () => el.shadowRoot?.querySelector('[data-testid="inc"]') as HTMLButtonElement;
    const getDecBtn = () => el.shadowRoot?.querySelector('[data-testid="dec"]') as HTMLButtonElement;

    expect(getCount()).toBe('3');

    // Hydration 後はイベントが動作する
    getIncBtn()?.click();
    expect(getCount()).toBe('4');

    getDecBtn()?.click();
    getDecBtn()?.click();
    expect(getCount()).toBe('2');
  });

  test('Hydration with escaped state', async () => {
    const name = `test-text-${++componentCounter}`;
    const TextComponent = defineComponent({
      name,
      styles: ':host { display: block; }',
      initialState: { text: '' },
      render: (state) => `<p data-testid="text">${state.text}</p>`,
      handlers: {},
    });

    registerComponent(TextComponent);

    // スクリプトタグを含む状態
    const state = { text: 'Hello <script>alert(1)</script> World' };
    const ssrHtml = renderComponentInline(
      name,
      TextComponent.styles,
      JSON.stringify(state),
      TextComponent.render(state)
    );

    insertDeclarativeShadowDOM(ssrHtml);
    await customElements.whenDefined(name);

    const el = container.querySelector(name) as HTMLElement;

    // 状態が正しく復元される（XSS攻撃は防がれる）
    expect((el as any)?.getState?.()?.text).toBe('Hello <script>alert(1)</script> World');
  });
});

// ============================================
// Tests: Multiple Components
// ============================================

describe('Multiple Components', () => {
  test('Multiple instances work independently', async () => {
    const Counter = createCounterComponent();
    registerComponent(Counter);

    container.innerHTML = `
      <${Counter.name} id="c1"></${Counter.name}>
      <${Counter.name} id="c2"></${Counter.name}>
    `;
    await customElements.whenDefined(Counter.name);

    const c1 = container.querySelector('#c1')!;
    const c2 = container.querySelector('#c2')!;

    const getInc1 = () => c1.shadowRoot?.querySelector('[data-testid="inc"]') as HTMLButtonElement;
    const getCount1 = () => c1.shadowRoot?.querySelector('[data-testid="count"]')?.textContent;
    const getCount2 = () => c2.shadowRoot?.querySelector('[data-testid="count"]')?.textContent;

    // 最初は両方0
    expect(getCount1()).toBe('0');
    expect(getCount2()).toBe('0');

    // c1だけインクリメント
    getInc1()?.click();
    getInc1()?.click();

    expect(getCount1()).toBe('2');
    expect(getCount2()).toBe('0'); // c2は変わらない
  });

  test('SSR + CSR mixed works', async () => {
    const Counter = createCounterComponent();
    registerComponent(Counter);

    // SSR コンポーネント
    const ssrHtml = renderComponentInline(
      Counter.name,
      Counter.styles,
      JSON.stringify({ count: 100 }),
      Counter.render({ count: 100 })
    );

    insertDeclarativeShadowDOM(ssrHtml);

    // CSR コンポーネントを追加
    const csrEl = document.createElement(Counter.name);
    container.appendChild(csrEl);

    await customElements.whenDefined(Counter.name);

    const ssrEl = container.querySelector(`${Counter.name}[data-state]`);
    const ssrCount = ssrEl?.shadowRoot?.querySelector('[data-testid="count"]');
    const csrCount = csrEl.shadowRoot?.querySelector('[data-testid="count"]');

    expect(ssrCount?.textContent).toBe('100');
    expect(csrCount?.textContent).toBe('0');
  });
});

// ============================================
// Tests: Adoptable Stylesheets
// ============================================

describe('Adoptable Stylesheets', () => {
  test('Stylesheets are shared between instances', async () => {
    const name = `test-adopt-${++componentCounter}`;
    const Component = defineComponent({
      name,
      styles: ':host { display: block; color: red; }',
      initialState: {},
      render: () => '<div>content</div>',
      handlers: {},
    });

    registerComponent(Component, { cssStrategy: 'adoptable' });

    container.innerHTML = `
      <${name}></${name}>
      <${name}></${name}>
      <${name}></${name}>
    `;
    await customElements.whenDefined(name);

    const elements = container.querySelectorAll(name);
    const sheets = new Set<CSSStyleSheet>();

    elements.forEach((el) => {
      el.shadowRoot?.adoptedStyleSheets.forEach((sheet) => sheets.add(sheet));
    });

    // 同じ CSSStyleSheet オブジェクトが共有されている
    expect(sheets.size).toBe(1);
  });
});
