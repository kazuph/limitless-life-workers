import { describe, it, expect, beforeEach } from 'vitest';
import {
  escapeAttr,
  escapeHtml,
  escapeJson,
  createSSRRenderer,
  renderDocument,
  renderComponentInline,
  renderComponentLink,
} from './server.js';
import type { ComponentDef } from './types.js';

// Test component definition
const Counter: ComponentDef<{ count: number }> = {
  name: 'my-counter',
  styles: ':host { display: block; }',
  stylesUrl: 'components/counter.css',
  initialState: { count: 0 },
  render: (state) => `<div class="count">${state.count}</div>`,
  handlers: {
    increment: (state) => ({ count: state.count + 1 }),
  },
};

describe('escapeAttr', () => {
  it('should escape special characters', () => {
    expect(escapeAttr('a&b')).toBe('a&amp;b');
    expect(escapeAttr('a"b')).toBe('a&quot;b');
    expect(escapeAttr('a<b')).toBe('a&lt;b');
    expect(escapeAttr('a>b')).toBe('a&gt;b');
  });

  it('should handle multiple special characters', () => {
    expect(escapeAttr('<"&">')).toBe('&lt;&quot;&amp;&quot;&gt;');
  });
});

describe('escapeHtml', () => {
  it('should escape HTML special characters', () => {
    expect(escapeHtml('<script>')).toBe('&lt;script&gt;');
    expect(escapeHtml("it's")).toBe('it&#39;s');
  });
});

describe('escapeJson', () => {
  it('should escape for script injection prevention', () => {
    expect(escapeJson('</script>')).toBe('\\u003c/script\\u003e');
    expect(escapeJson('a&b')).toBe('a\\u0026b');
  });
});

describe('createSSRRenderer', () => {
  describe('inline strategy', () => {
    it('should render with inline styles', () => {
      const renderer = createSSRRenderer({ cssStrategy: 'inline' });
      const html = renderer.render(Counter, { count: 5 });

      expect(html).toContain('<my-counter');
      expect(html).toContain('data-state=');
      expect(html).toContain('data-css="inline"');
      expect(html).toContain('<style>:host { display: block; }</style>');
      expect(html).toContain('<template shadowrootmode="open">');
      expect(html).toContain('<div class="count">5</div>');
    });
  });

  describe('link strategy', () => {
    it('should render with link tag when stylesUrl is provided', () => {
      const renderer = createSSRRenderer({ cssStrategy: 'link', baseUrl: '/assets/' });
      const html = renderer.render(Counter, { count: 3 });

      expect(html).toContain('data-css="link"');
      expect(html).toContain('<link rel="stylesheet" href="/assets/components/counter.css">');
      expect(html).not.toContain('<style>:host');
    });

    it('should fallback to inline when stylesUrl is not provided', () => {
      const NoUrlComponent: ComponentDef<{ value: string }> = {
        name: 'no-url',
        styles: ':host { color: red; }',
        initialState: { value: '' },
        render: (state) => `<span>${state.value}</span>`,
        handlers: {},
      };

      const renderer = createSSRRenderer({ cssStrategy: 'link' });
      const html = renderer.render(NoUrlComponent, { value: 'test' });

      expect(html).toContain('<style>:host { color: red; }</style>');
    });
  });

  describe('link-preload strategy', () => {
    let renderer: ReturnType<typeof createSSRRenderer>;

    beforeEach(() => {
      renderer = createSSRRenderer({ cssStrategy: 'link-preload', baseUrl: '/css/' });
      renderer.reset();
    });

    it('should collect CSS URLs', () => {
      renderer.render(Counter, { count: 1 });
      const preloads = renderer.getPreloadTags();

      expect(preloads).toContain('<link rel="preload" href="/css/components/counter.css" as="style">');
    });

    it('should not duplicate preload tags for same URL', () => {
      renderer.render(Counter, { count: 1 });
      renderer.render(Counter, { count: 2 });
      const preloads = renderer.getPreloadTags();

      const matches = preloads.match(/rel="preload"/g);
      expect(matches?.length).toBe(1);
    });

    it('should reset collected URLs', () => {
      renderer.render(Counter, { count: 1 });
      renderer.reset();
      const preloads = renderer.getPreloadTags();

      expect(preloads).toBe('');
    });
  });

  describe('adoptable strategy', () => {
    it('should render minimal styles', () => {
      const renderer = createSSRRenderer({ cssStrategy: 'adoptable' });
      const html = renderer.render(Counter, { count: 0 });

      expect(html).toContain('data-css="adoptable"');
      expect(html).toContain('<style>:host{display:block}</style>');
      expect(html).not.toContain(':host { display: block; }');
    });
  });

  describe('state serialization', () => {
    it('should escape special characters in data-state attribute', () => {
      const TextComponent: ComponentDef<{ text: string }> = {
        name: 'text-comp',
        styles: '',
        initialState: { text: '' },
        render: (state) => `<p>${state.text}</p>`,
        handlers: {},
      };

      const renderer = createSSRRenderer({ cssStrategy: 'inline' });
      const html = renderer.render(TextComponent, { text: '<script>alert(1)</script>' });

      // data-state attribute should have escaped script tags
      expect(html).toContain('data-state=');
      expect(html).toContain('\\u003cscript\\u003e');

      // Note: render function output is NOT escaped (user's responsibility)
      // This test verifies that state serialization is safe
    });
  });

  describe('children (slots)', () => {
    it('should include children in light DOM', () => {
      const renderer = createSSRRenderer({ cssStrategy: 'inline' });
      const html = renderer.render(Counter, { count: 0 }, {
        children: '<span slot="label">Count Label</span>',
      });

      expect(html).toContain('<span slot="label">Count Label</span>');
      expect(html).toContain('</my-counter>');
    });
  });
});

describe('renderDocument', () => {
  it('should render a complete HTML document', () => {
    const html = renderDocument({
      title: 'Test Page',
      body: '<main>Content</main>',
    });

    expect(html).toContain('<!DOCTYPE html>');
    expect(html).toContain('<title>Test Page</title>');
    expect(html).toContain('<main>Content</main>');
  });

  it('should include preload tags', () => {
    const html = renderDocument({
      title: 'Test',
      body: '',
      preloadTags: '<link rel="preload" href="/app.css" as="style">',
    });

    expect(html).toContain('<link rel="preload" href="/app.css" as="style">');
  });

  it('should include client runtime', () => {
    const html = renderDocument({
      title: 'Test',
      body: '',
      clientRuntime: '/wcssr-client.js',
    });

    expect(html).toContain('<script type="module" src="/wcssr-client.js"></script>');
  });
});

describe('renderComponentInline', () => {
  it('should render inline component', () => {
    const html = renderComponentInline(
      'my-comp',
      ':host { color: red; }',
      '{"value":42}',
      '<span>42</span>'
    );

    expect(html).toContain('<my-comp');
    expect(html).toContain('data-css="inline"');
    expect(html).toContain('<style>:host { color: red; }</style>');
    expect(html).toContain('<span>42</span>');
  });
});

describe('renderComponentLink', () => {
  it('should render link component', () => {
    const html = renderComponentLink(
      'my-comp',
      '/styles/comp.css',
      '{"value":42}',
      '<span>42</span>'
    );

    expect(html).toContain('<my-comp');
    expect(html).toContain('data-css="link"');
    expect(html).toContain('<link rel="stylesheet" href="/styles/comp.css">');
  });
});
