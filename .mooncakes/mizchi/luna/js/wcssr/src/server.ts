/**
 * Web Components SSR - Server Runtime
 *
 * 純粋関数のみで構成。DOM依存なし。
 * MoonBit で同等の実装が可能な設計。
 */

import type {
  ComponentDef,
  State,
  SSROptions,
  RenderOptions,
} from './types.js';

// ============================================
// Escape Utilities
// ============================================

/**
 * HTML属性値のエスケープ
 */
export function escapeAttr(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

/**
 * HTMLコンテンツのエスケープ
 */
export function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * JSON文字列のエスケープ（script injection対策）
 */
export function escapeJson(str: string): string {
  return str
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026');
}

// ============================================
// SSR Renderer
// ============================================

/**
 * SSRレンダラーを作成
 *
 * @example
 * ```ts
 * const renderer = createSSRRenderer({ cssStrategy: 'link-preload' });
 * const html = renderer.render(Counter, { count: 5 });
 * const preloads = renderer.getPreloadTags();
 * ```
 */
export function createSSRRenderer(options: SSROptions = { cssStrategy: 'inline' }) {
  const { cssStrategy, baseUrl = '' } = options;

  // link-preload戦略用: 収集したCSS URL
  const collectedStyleUrls = new Set<string>();

  /**
   * スタイル出力を生成
   */
  function renderStyles(
    styles: string,
    stylesUrl: string | undefined
  ): string {
    switch (cssStrategy) {
      case 'inline':
        return `<style>${styles}</style>`;

      case 'link':
        if (stylesUrl) {
          return `<link rel="stylesheet" href="${baseUrl}${stylesUrl}">`;
        }
        return `<style>${styles}</style>`;

      case 'link-preload':
        if (stylesUrl) {
          const fullUrl = `${baseUrl}${stylesUrl}`;
          collectedStyleUrls.add(fullUrl);
          return `<link rel="stylesheet" href="${fullUrl}">`;
        }
        return `<style>${styles}</style>`;

      case 'adoptable':
        // Hydration時にJSで適用するため、最小限のスタイルのみ
        return `<style>:host{display:block}</style>`;

      default:
        return `<style>${styles}</style>`;
    }
  }

  /**
   * コンポーネントをHTML文字列にレンダリング
   */
  function render<S extends State>(
    component: ComponentDef<S>,
    state: S,
    options: RenderOptions = {}
  ): string {
    const { children = '' } = options;
    const { name, styles, stylesUrl, render: renderFn, serialize = JSON.stringify } = component;

    // 状態をシリアライズ
    const serializedState = escapeAttr(escapeJson(serialize(state)));

    // テンプレートをレンダリング
    const html = renderFn(state);

    // スタイル出力
    const styleOutput = renderStyles(styles, stylesUrl);

    return `<${name} data-state="${serializedState}" data-css="${cssStrategy}">
  <template shadowrootmode="open">
    ${styleOutput}
    ${html}
  </template>
  ${children}
</${name}>`;
  }

  /**
   * 収集したCSSのpreloadタグを生成
   * link-preload戦略の場合、<head>に挿入する
   */
  function getPreloadTags(): string {
    if (cssStrategy !== 'link-preload') return '';

    return Array.from(collectedStyleUrls)
      .map((url) => `<link rel="preload" href="${url}" as="style">`)
      .join('\n');
  }

  /**
   * 収集をリセット
   */
  function reset(): void {
    collectedStyleUrls.clear();
  }

  /**
   * 現在の設定を取得
   */
  function getConfig(): SSROptions {
    return { cssStrategy, baseUrl };
  }

  return {
    render,
    getPreloadTags,
    reset,
    getConfig,
  };
}

// ============================================
// Document Renderer
// ============================================

export interface DocumentOptions {
  title?: string;
  lang?: string;
  head?: string;
  body: string;
  preloadTags?: string;
  scripts?: string[];
  /** クライアントランタイムのパス */
  clientRuntime?: string;
}

/**
 * 完全なHTMLドキュメントを生成
 */
export function renderDocument(options: DocumentOptions): string {
  const {
    title = '',
    lang = 'en',
    head = '',
    body,
    preloadTags = '',
    scripts = [],
    clientRuntime,
  } = options;

  const scriptTags = [
    ...(clientRuntime ? [`<script type="module" src="${clientRuntime}"></script>`] : []),
    ...scripts.map((src) => `<script src="${src}"></script>`),
  ].join('\n  ');

  return `<!DOCTYPE html>
<html lang="${lang}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)}</title>
  ${preloadTags}
  ${head}
</head>
<body>
  ${body}
  ${scriptTags}
</body>
</html>`;
}

// ============================================
// Standalone Functions (MoonBit FFI用)
// ============================================

/**
 * 単一コンポーネントをレンダリング（オプションなし）
 * MoonBitから呼び出しやすいシンプルなインターフェース
 */
export function renderComponentInline(
  name: string,
  styles: string,
  stateJson: string,
  html: string
): string {
  const escapedState = escapeAttr(escapeJson(stateJson));

  return `<${name} data-state="${escapedState}" data-css="inline">
  <template shadowrootmode="open">
    <style>${styles}</style>
    ${html}
  </template>
</${name}>`;
}

/**
 * link戦略でレンダリング
 */
export function renderComponentLink(
  name: string,
  stylesUrl: string,
  stateJson: string,
  html: string
): string {
  const escapedState = escapeAttr(escapeJson(stateJson));

  return `<${name} data-state="${escapedState}" data-css="link">
  <template shadowrootmode="open">
    <link rel="stylesheet" href="${stylesUrl}">
    ${html}
  </template>
</${name}>`;
}
