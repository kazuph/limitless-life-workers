/**
 * DOM Parts Polyfill Tests
 *
 * WICG DOM Parts 仕様に基づいた実装のテスト
 */

import { describe, test, expect, beforeEach, afterEach } from 'vitest';
import {
  NodePart,
  AttributePart,
  ChildNodePart,
  PropertyPart,
  PartGroup,
  hydratePartsFromElement,
} from '../src/parts.js';

// ============================================
// Test Utilities
// ============================================

let container: HTMLDivElement;

beforeEach(() => {
  container = document.createElement('div');
  container.id = 'test-container';
  document.body.appendChild(container);
});

afterEach(() => {
  container.remove();
});

// ============================================
// NodePart Tests
// ============================================

describe('NodePart', () => {
  test('creates part from text node', () => {
    const textNode = document.createTextNode('initial');
    container.appendChild(textNode);

    const part = new NodePart(textNode);
    expect(part.value).toBe('initial');
    expect(part.node).toBe(textNode);
  });

  test('commit updates text content', () => {
    const textNode = document.createTextNode('initial');
    container.appendChild(textNode);

    const part = new NodePart(textNode);
    part.value = 'updated';

    // Before commit, DOM is unchanged
    expect(textNode.textContent).toBe('initial');

    part.commit();

    // After commit, DOM is updated
    expect(textNode.textContent).toBe('updated');
  });

  test('skips commit if value unchanged', () => {
    const textNode = document.createTextNode('same');
    container.appendChild(textNode);

    const part = new NodePart(textNode);
    part.value = 'same';
    part.commit();

    expect(textNode.textContent).toBe('same');
  });

  test('handles null/undefined values', () => {
    const textNode = document.createTextNode('value');
    container.appendChild(textNode);

    const part = new NodePart(textNode);
    part.value = null;
    part.commit();

    expect(textNode.textContent).toBe('');
  });
});

// ============================================
// AttributePart Tests
// ============================================

describe('AttributePart', () => {
  test('creates part from element attribute', () => {
    container.innerHTML = '<a href="http://example.com">Link</a>';
    const link = container.querySelector('a')!;

    const part = new AttributePart(link, 'href');
    expect(part.value).toBe('http://example.com');
    expect(part.element).toBe(link);
    expect(part.localName).toBe('href');
  });

  test('commit updates attribute', () => {
    container.innerHTML = '<a href="http://old.com">Link</a>';
    const link = container.querySelector('a')!;

    const part = new AttributePart(link, 'href');
    part.value = 'http://new.com';
    part.commit();

    expect(link.getAttribute('href')).toBe('http://new.com');
  });

  test('removes attribute when value is null', () => {
    container.innerHTML = '<button disabled>Click</button>';
    const button = container.querySelector('button')!;

    const part = new AttributePart(button, 'disabled');
    part.value = null;
    part.commit();

    expect(button.hasAttribute('disabled')).toBe(false);
  });

  test('handles boolean true as empty string', () => {
    container.innerHTML = '<button>Click</button>';
    const button = container.querySelector('button')!;

    const part = new AttributePart(button, 'disabled');
    part.value = true;
    part.commit();

    expect(button.hasAttribute('disabled')).toBe(true);
    expect(button.getAttribute('disabled')).toBe('');
  });

  test('parses qualified name with prefix', () => {
    container.innerHTML = '<svg><use></use></svg>';
    const use = container.querySelector('use')!;

    const part = new AttributePart(use, 'xlink:href', 'http://www.w3.org/1999/xlink');
    expect(part.prefix).toBe('xlink');
    expect(part.localName).toBe('href');
    expect(part.namespaceURI).toBe('http://www.w3.org/1999/xlink');
  });
});

// ============================================
// ChildNodePart Tests
// ============================================

describe('ChildNodePart', () => {
  test('creates markers in parent', () => {
    container.innerHTML = '<div id="parent"></div>';
    const parent = container.querySelector('#parent')!;

    const part = new ChildNodePart(parent);

    // Should have start and end comment markers
    expect(parent.childNodes.length).toBe(2);
    expect(parent.childNodes[0].nodeType).toBe(Node.COMMENT_NODE);
    expect(parent.childNodes[1].nodeType).toBe(Node.COMMENT_NODE);
  });

  test('commit inserts text content', () => {
    container.innerHTML = '<div id="parent"></div>';
    const parent = container.querySelector('#parent')!;

    const part = new ChildNodePart(parent);
    part.value = 'Hello World';
    part.commit();

    expect(parent.textContent).toBe('Hello World');
  });

  test('commit replaces content on update', () => {
    container.innerHTML = '<div id="parent"></div>';
    const parent = container.querySelector('#parent')!;

    const part = new ChildNodePart(parent);

    part.value = 'First';
    part.commit();
    expect(parent.textContent).toBe('First');

    part.value = 'Second';
    part.commit();
    expect(parent.textContent).toBe('Second');
  });

  test('commit with DOM node', () => {
    container.innerHTML = '<div id="parent"></div>';
    const parent = container.querySelector('#parent')!;

    const part = new ChildNodePart(parent);

    const span = document.createElement('span');
    span.textContent = 'Dynamic';
    span.className = 'dynamic';

    part.value = span;
    part.commit();

    const inserted = parent.querySelector('.dynamic');
    expect(inserted).toBeTruthy();
    expect(inserted?.textContent).toBe('Dynamic');
  });

  test('commit with array of nodes', () => {
    container.innerHTML = '<div id="parent"></div>';
    const parent = container.querySelector('#parent')!;

    const part = new ChildNodePart(parent);

    const items = ['A', 'B', 'C'].map((text) => {
      const li = document.createElement('li');
      li.textContent = text;
      return li;
    });

    part.value = items;
    part.commit();

    const lis = parent.querySelectorAll('li');
    expect(lis.length).toBe(3);
    expect(lis[0].textContent).toBe('A');
    expect(lis[1].textContent).toBe('B');
    expect(lis[2].textContent).toBe('C');
  });

  test('commit with null clears content', () => {
    container.innerHTML = '<div id="parent"></div>';
    const parent = container.querySelector('#parent')!;

    const part = new ChildNodePart(parent);
    part.value = 'Content';
    part.commit();

    part.value = null;
    part.commit();

    // Only markers remain
    expect(parent.childNodes.length).toBe(2);
  });
});

// ============================================
// PropertyPart Tests
// ============================================

describe('PropertyPart', () => {
  test('creates part from element property', () => {
    container.innerHTML = '<input type="text" />';
    const input = container.querySelector('input')!;
    input.value = 'initial';

    const part = new PropertyPart(input, 'value');
    expect(part.value).toBe('initial');
    expect(part.element).toBe(input);
  });

  test('commit updates property', () => {
    container.innerHTML = '<input type="text" />';
    const input = container.querySelector('input')!;

    const part = new PropertyPart(input, 'value');
    part.value = 'updated';
    part.commit();

    expect(input.value).toBe('updated');
  });

  test('works with checked property', () => {
    container.innerHTML = '<input type="checkbox" />';
    const checkbox = container.querySelector('input')!;

    const part = new PropertyPart(checkbox, 'checked');
    part.value = true;
    part.commit();

    expect(checkbox.checked).toBe(true);

    part.value = false;
    part.commit();

    expect(checkbox.checked).toBe(false);
  });
});

// ============================================
// PartGroup Tests
// ============================================

describe('PartGroup', () => {
  test('commits all parts at once', () => {
    container.innerHTML = `
      <span id="name"></span>
      <a id="link" href="">Link</a>
    `;

    const nameNode = container.querySelector('#name')!;
    const nameText = document.createTextNode('');
    nameNode.appendChild(nameText);

    const link = container.querySelector('#link')!;

    const namePart = new NodePart(nameText);
    const hrefPart = new AttributePart(link, 'href');

    const group = new PartGroup([namePart, hrefPart]);

    namePart.value = 'John Doe';
    hrefPart.value = 'mailto:john@example.com';

    // Before commit
    expect(nameText.textContent).toBe('');
    expect(link.getAttribute('href')).toBe('');

    group.commit();

    // After commit
    expect(nameText.textContent).toBe('John Doe');
    expect(link.getAttribute('href')).toBe('mailto:john@example.com');
  });

  test('add and remove parts', () => {
    const textNode = document.createTextNode('');
    container.appendChild(textNode);

    const part = new NodePart(textNode);
    const group = new PartGroup();

    group.add(part);
    expect(group.parts.length).toBe(1);

    group.remove(part);
    expect(group.parts.length).toBe(0);
  });
});

// ============================================
// Hydration Tests
// ============================================

describe('Hydration from SSR', () => {
  test('hydrates ChildNodePart from comment markers', () => {
    container.innerHTML = `
      <div id="root">
        <!--{{count}}-->42<!--/{{count}}-->
      </div>
    `;

    const root = container.querySelector('#root')!;
    const parts = hydratePartsFromElement(root);

    expect(parts.has('count')).toBe(true);

    const countPart = parts.get('count')!;
    expect(countPart.value).toBe('42');

    // Update and commit
    countPart.value = '100';
    countPart.commit();

    expect(root.textContent?.trim()).toBe('100');
  });

  test('hydrates AttributePart from data-part attribute', () => {
    container.innerHTML = `
      <div id="root">
        <a href="http://example.com" data-part="href:url">Link</a>
      </div>
    `;

    const root = container.querySelector('#root')!;
    const parts = hydratePartsFromElement(root);

    expect(parts.has('url')).toBe(true);

    const urlPart = parts.get('url')!;
    expect(urlPart.value).toBe('http://example.com');

    urlPart.value = 'http://updated.com';
    urlPart.commit();

    const link = root.querySelector('a')!;
    expect(link.getAttribute('href')).toBe('http://updated.com');
  });

  test('hydrates multiple parts', () => {
    container.innerHTML = `
      <div id="root">
        <h1><!--{{title}}-->Hello<!--/{{title}}--></h1>
        <p>Count: <!--{{count}}-->0<!--/{{count}}--></p>
        <a href="#" data-part="href:link">Link</a>
      </div>
    `;

    const root = container.querySelector('#root')!;
    const parts = hydratePartsFromElement(root);

    expect(parts.size).toBe(3);
    expect(parts.has('title')).toBe(true);
    expect(parts.has('count')).toBe(true);
    expect(parts.has('link')).toBe(true);
  });
});

// ============================================
// Integration: Signal + Parts
// ============================================

describe('Integration: Signal with Parts', () => {
  // Simple Signal implementation
  function createSignal<T>(initial: T) {
    let value = initial;
    const subscribers = new Set<(v: T) => void>();
    return {
      get: () => value,
      set: (v: T) => {
        if (value !== v) {
          value = v;
          subscribers.forEach((fn) => fn(v));
        }
      },
      subscribe: (fn: (v: T) => void) => {
        subscribers.add(fn);
        return () => subscribers.delete(fn);
      },
    };
  }

  test('Signal updates Part which updates DOM', () => {
    container.innerHTML = '<span id="value"></span>';
    const span = container.querySelector('#value')!;
    const textNode = document.createTextNode('0');
    span.appendChild(textNode);

    const part = new NodePart(textNode);
    const signal = createSignal(0);

    // Subscribe: Signal -> Part -> DOM
    signal.subscribe((v) => {
      part.value = String(v);
      part.commit();
    });

    signal.set(42);
    expect(textNode.textContent).toBe('42');

    signal.set(100);
    expect(textNode.textContent).toBe('100');
  });

  test('Multiple Parts react to same Signal', () => {
    container.innerHTML = `
      <div>
        <span id="display1"></span>
        <span id="display2"></span>
      </div>
    `;

    const span1 = container.querySelector('#display1')!;
    const span2 = container.querySelector('#display2')!;

    const text1 = document.createTextNode('');
    const text2 = document.createTextNode('');
    span1.appendChild(text1);
    span2.appendChild(text2);

    const part1 = new NodePart(text1);
    const part2 = new NodePart(text2);
    const group = new PartGroup([part1, part2]);

    const signal = createSignal('initial');

    signal.subscribe((v) => {
      part1.value = v;
      part2.value = v;
      group.commit();
    });

    signal.set('updated');

    expect(text1.textContent).toBe('updated');
    expect(text2.textContent).toBe('updated');
  });

  test('Batched updates with PartGroup', () => {
    container.innerHTML = `
      <div id="card">
        <h2 id="title"></h2>
        <p id="content"></p>
        <a id="link" href="">Read more</a>
      </div>
    `;

    const titleNode = document.createTextNode('');
    const contentNode = document.createTextNode('');
    container.querySelector('#title')!.appendChild(titleNode);
    container.querySelector('#content')!.appendChild(contentNode);
    const link = container.querySelector('#link')!;

    const titlePart = new NodePart(titleNode);
    const contentPart = new NodePart(contentNode);
    const linkPart = new AttributePart(link, 'href');

    const group = new PartGroup([titlePart, contentPart, linkPart]);

    // State object
    const state = createSignal({
      title: 'Initial Title',
      content: 'Initial content',
      url: 'http://initial.com',
    });

    state.subscribe((s) => {
      titlePart.value = s.title;
      contentPart.value = s.content;
      linkPart.value = s.url;
      group.commit(); // Single batch commit
    });

    state.set({
      title: 'New Title',
      content: 'New content here',
      url: 'http://new.com',
    });

    expect(titleNode.textContent).toBe('New Title');
    expect(contentNode.textContent).toBe('New content here');
    expect(link.getAttribute('href')).toBe('http://new.com');
  });
});

// ============================================
// Web Component Integration
// ============================================

describe('Web Component with Parts', () => {
  let componentCounter = 0;

  test('Parts work inside Shadow DOM', async () => {
    const name = `parts-shadow-${++componentCounter}`;

    class PartsComponent extends HTMLElement {
      private _countPart?: NodePart;
      private _count = 0;

      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        this.shadowRoot!.innerHTML = `
          <div>Count: <span id="count">0</span></div>
          <button id="inc">+</button>
        `;

        const countSpan = this.shadowRoot!.querySelector('#count')!;
        const textNode = document.createTextNode('0');
        countSpan.textContent = '';
        countSpan.appendChild(textNode);

        this._countPart = new NodePart(textNode);

        this.shadowRoot!.querySelector('#inc')!.addEventListener('click', () => {
          this._count++;
          this._countPart!.value = String(this._count);
          this._countPart!.commit();
        });
      }
    }

    if (!customElements.get(name)) {
      customElements.define(name, PartsComponent);
    }

    container.innerHTML = `<${name}></${name}>`;
    await customElements.whenDefined(name);

    const el = container.querySelector(name)!;
    const getCount = () => el.shadowRoot?.querySelector('#count')?.textContent;
    const getBtn = () => el.shadowRoot?.querySelector('#inc') as HTMLButtonElement;

    expect(getCount()).toBe('0');

    getBtn().click();
    expect(getCount()).toBe('1');

    getBtn().click();
    getBtn().click();
    expect(getCount()).toBe('3');
  });

  test('Parts propagate across Shadow DOM boundaries with shared signal', async () => {
    const signal = { value: 0, subscribers: new Set<() => void>() };
    const notify = () => signal.subscribers.forEach((fn) => fn());

    const parentName = `parts-parent-${++componentCounter}`;
    const childName = `parts-child-${++componentCounter}`;

    // Child: displays signal value using Part
    class ChildComponent extends HTMLElement {
      private _part?: NodePart;
      private _unsubscribe?: () => void;

      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        this.shadowRoot!.innerHTML = '<span id="value">0</span>';
        const span = this.shadowRoot!.querySelector('#value')!;
        const textNode = document.createTextNode(String(signal.value));
        span.textContent = '';
        span.appendChild(textNode);

        this._part = new NodePart(textNode);

        const update = () => {
          this._part!.value = String(signal.value);
          this._part!.commit();
        };

        signal.subscribers.add(update);
        this._unsubscribe = () => signal.subscribers.delete(update);
      }

      disconnectedCallback() {
        this._unsubscribe?.();
      }
    }

    // Parent: updates signal, contains child
    class ParentComponent extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        this.shadowRoot!.innerHTML = `
          <button id="inc">Increment</button>
          <${childName}></${childName}>
        `;

        this.shadowRoot!.querySelector('#inc')!.addEventListener('click', () => {
          signal.value++;
          notify();
        });
      }
    }

    if (!customElements.get(childName)) {
      customElements.define(childName, ChildComponent);
    }
    if (!customElements.get(parentName)) {
      customElements.define(parentName, ParentComponent);
    }

    container.innerHTML = `<${parentName}></${parentName}>`;
    await customElements.whenDefined(parentName);
    await customElements.whenDefined(childName);

    const parent = container.querySelector(parentName)!;
    const getChildValue = () => {
      const child = parent.shadowRoot?.querySelector(childName);
      return child?.shadowRoot?.querySelector('#value')?.textContent;
    };
    const getBtn = () => parent.shadowRoot?.querySelector('#inc') as HTMLButtonElement;

    expect(getChildValue()).toBe('0');

    getBtn().click();
    expect(getChildValue()).toBe('1');

    getBtn().click();
    getBtn().click();
    expect(getChildValue()).toBe('3');
  });
});
