/**
 * Web Components SSR - Snapshot Tests
 *
 * SSR only と Hydration 後で同じ表示になることを保証
 */

import { describe, test, expect, beforeEach, afterEach } from 'vitest';
import {
  registerComponent,
  defineComponent,
  clearStyleSheetCache,
} from '../src/client.js';
import { renderComponentInline } from '../src/server.js';
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

/**
 * Declarative Shadow DOM を持つ HTML を挿入
 * setHTMLUnsafe を使用（Chrome 124+, Firefox 129+）
 */
function insertDeclarativeShadowDOM(html: string, append = false): void {
  // Use type assertion to handle setHTMLUnsafe which may not exist at runtime in older browsers
  type MaybeSetHTMLUnsafe = { setHTMLUnsafe?: (html: string) => void };

  if (append) {
    // 既存のコンテンツに追加する場合
    const wrapper = document.createElement('div');
    const wrapperWithMethod = wrapper as unknown as MaybeSetHTMLUnsafe;
    if (wrapperWithMethod.setHTMLUnsafe) {
      wrapperWithMethod.setHTMLUnsafe(html);
    } else {
      wrapper.innerHTML = html;
    }
    while (wrapper.firstChild) {
      container.appendChild(wrapper.firstChild);
    }
  } else {
    // 上書きする場合
    const containerWithMethod = container as unknown as MaybeSetHTMLUnsafe;
    if (containerWithMethod.setHTMLUnsafe) {
      containerWithMethod.setHTMLUnsafe(html);
    } else {
      container.innerHTML = html;
    }
  }
}

/**
 * Shadow DOM 内のコンテンツを取得（スタイルを除く）
 */
function getShadowContent(el: Element): string {
  if (!el.shadowRoot) return '';

  // ShadowRootはcloneできないので、innerHTMLを使用してstyle/linkを除去
  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = el.shadowRoot.innerHTML;

  // style要素を除去（CSSは比較対象外）
  tempDiv.querySelectorAll('style').forEach((s) => s.remove());
  tempDiv.querySelectorAll('link').forEach((l) => l.remove());

  // 空白を正規化
  return tempDiv.innerHTML.replace(/\s+/g, ' ').trim();
}

/**
 * 要素の視覚的なスタイルを取得
 */
function getComputedStyles(el: Element): Record<string, string> {
  const computed = window.getComputedStyle(el);
  return {
    display: computed.display,
    padding: computed.padding,
    border: computed.border,
    color: computed.color,
    backgroundColor: computed.backgroundColor,
  };
}

// ============================================
// Test Components
// ============================================

function createStyledCounter(): ComponentDef<{ count: number }> {
  const name = `snap-counter-${++componentCounter}`;
  return defineComponent({
    name,
    styles: `
      :host {
        display: block;
        padding: 16px;
        border: 2px solid #3498db;
        border-radius: 8px;
        background: #f0f7ff;
        font-family: system-ui, sans-serif;
      }
      .count {
        font-size: 2rem;
        font-weight: bold;
        text-align: center;
        color: #2c3e50;
        margin: 8px 0;
      }
      .buttons {
        display: flex;
        gap: 8px;
        justify-content: center;
      }
      button {
        padding: 8px 16px;
        font-size: 1rem;
        border: none;
        border-radius: 4px;
        cursor: pointer;
      }
      .dec { background: #e74c3c; color: white; }
      .inc { background: #27ae60; color: white; }
    `,
    initialState: { count: 0 },
    render: (state) => `
      <div class="count">${state.count}</div>
      <div class="buttons">
        <button class="dec" data-on-click="decrement">-</button>
        <button class="inc" data-on-click="increment">+</button>
      </div>
    `,
    handlers: {
      increment: (state) => ({ count: state.count + 1 }),
      decrement: (state) => ({ count: state.count - 1 }),
    },
  });
}

function createCard(): ComponentDef<{ title: string; content: string }> {
  const name = `snap-card-${++componentCounter}`;
  return defineComponent({
    name,
    styles: `
      :host {
        display: block;
        border: 1px solid #e0e0e0;
        border-radius: 12px;
        overflow: hidden;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      }
      .header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 16px;
        font-weight: bold;
      }
      .body {
        padding: 16px;
        background: white;
        color: #333;
      }
    `,
    initialState: { title: '', content: '' },
    render: (state) => `
      <div class="header">${state.title}</div>
      <div class="body">${state.content}</div>
    `,
    handlers: {},
  });
}

function createList(): ComponentDef<{ items: string[] }> {
  const name = `snap-list-${++componentCounter}`;
  return defineComponent({
    name,
    styles: `
      :host { display: block; }
      ul {
        list-style: none;
        padding: 0;
        margin: 0;
        border: 1px solid #ddd;
        border-radius: 8px;
        overflow: hidden;
      }
      li {
        padding: 12px 16px;
        border-bottom: 1px solid #eee;
        background: white;
      }
      li:last-child { border-bottom: none; }
      li:hover { background: #f9f9f9; }
    `,
    initialState: { items: [] as string[] },
    render: (state) => `
      <ul>
        ${state.items.map((item) => `<li>${item}</li>`).join('')}
      </ul>
    `,
    handlers: {},
  });
}

// ============================================
// Snapshot Tests: DOM Content
// ============================================

describe('Snapshot: DOM Content', () => {
  test('Counter: SSR content matches Hydrated content', async () => {
    const Counter = createStyledCounter();
    const state = { count: 42 };

    // SSR HTML を生成
    const ssrHtml = renderComponentInline(
      Counter.name,
      Counter.styles,
      JSON.stringify(state),
      Counter.render(state)
    );

    // SSR only: JS登録前にHTMLを挿入
    insertDeclarativeShadowDOM(ssrHtml);
    const ssrEl = container.querySelector(Counter.name)!;
    const ssrContent = getShadowContent(ssrEl);

    // Hydration: コンポーネントを登録
    registerComponent(Counter);
    await customElements.whenDefined(Counter.name);

    const hydratedContent = getShadowContent(ssrEl);

    // SSR と Hydration 後で同じコンテンツ
    expect(hydratedContent).toBe(ssrContent);
  });

  test('Card: SSR content matches Hydrated content', async () => {
    const Card = createCard();
    const state = { title: 'Hello World', content: 'This is a card component.' };

    const ssrHtml = renderComponentInline(
      Card.name,
      Card.styles,
      JSON.stringify(state),
      Card.render(state)
    );

    insertDeclarativeShadowDOM(ssrHtml);
    const ssrEl = container.querySelector(Card.name)!;
    const ssrContent = getShadowContent(ssrEl);

    registerComponent(Card);
    await customElements.whenDefined(Card.name);

    const hydratedContent = getShadowContent(ssrEl);
    expect(hydratedContent).toBe(ssrContent);
  });

  test('List: SSR content matches Hydrated content', async () => {
    const List = createList();
    const state = { items: ['Apple', 'Banana', 'Cherry', 'Date'] };

    const ssrHtml = renderComponentInline(
      List.name,
      List.styles,
      JSON.stringify(state),
      List.render(state)
    );

    insertDeclarativeShadowDOM(ssrHtml);
    const ssrEl = container.querySelector(List.name)!;
    const ssrContent = getShadowContent(ssrEl);

    registerComponent(List);
    await customElements.whenDefined(List.name);

    const hydratedContent = getShadowContent(ssrEl);
    expect(hydratedContent).toBe(ssrContent);
  });
});

// ============================================
// Snapshot Tests: Visual Appearance
// ============================================

describe('Snapshot: Visual Appearance', () => {
  test('Counter: SSR renders content immediately', async () => {
    const Counter = createStyledCounter();
    const state = { count: 100 };

    const ssrHtml = renderComponentInline(
      Counter.name,
      Counter.styles,
      JSON.stringify(state),
      Counter.render(state)
    );

    // SSR HTML を挿入（JS登録前）
    insertDeclarativeShadowDOM(ssrHtml);
    const el = container.querySelector(Counter.name)!;

    // JS 登録前でもShadow DOM内のコンテンツは表示されている
    expect(el.shadowRoot).toBeTruthy();
    expect(el.shadowRoot?.innerHTML).toContain('100');

    // Hydration
    registerComponent(Counter);
    await customElements.whenDefined(Counter.name);

    // Hydration 後もコンテンツは同じ
    expect(el.shadowRoot?.innerHTML).toContain('100');

    // :host スタイルは upgrade 後に適用される
    const hydratedStyles = getComputedStyles(el);
    expect(hydratedStyles.display).toBe('block');
  });

  test('Counter: Inline snapshot of rendered HTML', async () => {
    const Counter = createStyledCounter();
    const state = { count: 5 };

    const ssrHtml = renderComponentInline(
      Counter.name,
      Counter.styles,
      JSON.stringify(state),
      Counter.render(state)
    );

    insertDeclarativeShadowDOM(ssrHtml);
    registerComponent(Counter);
    await customElements.whenDefined(Counter.name);

    const el = container.querySelector(Counter.name)!;
    const content = getShadowContent(el);

    // インラインスナップショット
    expect(content).toMatchInlineSnapshot(`"<div class="count">5</div> <div class="buttons"> <button class="dec" data-on-click="decrement">-</button> <button class="inc" data-on-click="increment">+</button> </div>"`);
  });

  test('Card: Inline snapshot of rendered HTML', async () => {
    const Card = createCard();
    const state = { title: 'Test Card', content: 'Card content here.' };

    const ssrHtml = renderComponentInline(
      Card.name,
      Card.styles,
      JSON.stringify(state),
      Card.render(state)
    );

    insertDeclarativeShadowDOM(ssrHtml);
    registerComponent(Card);
    await customElements.whenDefined(Card.name);

    const el = container.querySelector(Card.name)!;
    const content = getShadowContent(el);

    expect(content).toMatchInlineSnapshot(`"<div class="header">Test Card</div> <div class="body">Card content here.</div>"`);
  });
});

// ============================================
// Snapshot Tests: State Integrity
// ============================================

describe('Snapshot: State Integrity', () => {
  test('State is preserved exactly after hydration', async () => {
    const Counter = createStyledCounter();
    const originalState = { count: 999 };

    const ssrHtml = renderComponentInline(
      Counter.name,
      Counter.styles,
      JSON.stringify(originalState),
      Counter.render(originalState)
    );

    insertDeclarativeShadowDOM(ssrHtml);
    registerComponent(Counter);
    await customElements.whenDefined(Counter.name);

    const el = container.querySelector(Counter.name) as any;
    const restoredState = el.getState();

    expect(restoredState).toEqual(originalState);
  });

  test('Complex state with special characters is preserved', async () => {
    const name = `snap-text-${++componentCounter}`;
    const TextComponent = defineComponent({
      name,
      styles: ':host { display: block; }',
      initialState: { text: '' },
      render: (state) => `<p>${state.text}</p>`,
      handlers: {},
    });

    const originalState = {
      text: 'Special chars: <>&"\' and unicode: 日本語 🎉',
    };

    const ssrHtml = renderComponentInline(
      name,
      TextComponent.styles,
      JSON.stringify(originalState),
      TextComponent.render(originalState)
    );

    insertDeclarativeShadowDOM(ssrHtml);
    registerComponent(TextComponent);
    await customElements.whenDefined(name);

    const el = container.querySelector(name) as any;
    const restoredState = el.getState();

    expect(restoredState).toEqual(originalState);
  });
});

// ============================================
// Snapshot Tests: Multiple Components
// ============================================

describe('Snapshot: Multiple Components', () => {
  test('Multiple SSR components maintain consistency', async () => {
    const Counter1 = createStyledCounter();
    const Counter2 = createStyledCounter();
    const Card = createCard();

    const state1 = { count: 10 };
    const state2 = { count: 20 };
    const cardState = { title: 'Title', content: 'Content' };

    // 全てSSRでレンダリング
    const html1 = renderComponentInline(Counter1.name, Counter1.styles, JSON.stringify(state1), Counter1.render(state1));
    const html2 = renderComponentInline(Counter2.name, Counter2.styles, JSON.stringify(state2), Counter2.render(state2));
    const htmlCard = renderComponentInline(Card.name, Card.styles, JSON.stringify(cardState), Card.render(cardState));

    // append=true で追加
    insertDeclarativeShadowDOM(html1);
    insertDeclarativeShadowDOM(html2, true);
    insertDeclarativeShadowDOM(htmlCard, true);

    // SSR状態のコンテンツを記録
    const el1 = container.querySelector(Counter1.name)!;
    const el2 = container.querySelector(Counter2.name)!;
    const elCard = container.querySelector(Card.name)!;

    expect(el1).toBeTruthy();
    expect(el2).toBeTruthy();
    expect(elCard).toBeTruthy();

    const ssrContent1 = getShadowContent(el1);
    const ssrContent2 = getShadowContent(el2);
    const ssrContentCard = getShadowContent(elCard);

    // 全てHydration
    registerComponent(Counter1);
    registerComponent(Counter2);
    registerComponent(Card);

    await Promise.all([
      customElements.whenDefined(Counter1.name),
      customElements.whenDefined(Counter2.name),
      customElements.whenDefined(Card.name),
    ]);

    // Hydration後も同じ
    expect(getShadowContent(el1)).toBe(ssrContent1);
    expect(getShadowContent(el2)).toBe(ssrContent2);
    expect(getShadowContent(elCard)).toBe(ssrContentCard);
  });
});
