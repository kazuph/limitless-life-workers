/**
 * Unit tests for shiki-highlight.ts
 */

import { describe, it, expect, beforeAll } from "vitest";
import {
  type BundledLanguage,
  type BundledTheme,
  type Highlighter,
  bundledLanguages,
  createHighlighter,
} from "shiki";

// Configuration - must match shiki-highlight.ts
const THEMES: { light: BundledTheme; dark: BundledTheme } = {
  light: "github-light",
  dark: "github-dark",
};

// Language alias mapping
const LANG_ALIASES: Record<string, BundledLanguage> = {
  js: "javascript",
  ts: "typescript",
  mbt: "rust",
  moonbit: "rust",
  sh: "bash",
  shell: "bash",
  zsh: "bash",
  yml: "yaml",
  dockerfile: "docker",
};

/**
 * Regex to match code blocks with data attributes
 * Matches: <pre class="code-block" data-lang="..." ...><code ...>...</code></pre>
 */
const CODE_BLOCK_REGEX =
  /<pre\s+class="code-block"([^>]*)>\s*<code[^>]*>([\s\S]*?)<\/code>\s*<\/pre>/g;

/**
 * Extract data attributes from pre tag
 */
function extractDataAttributes(attrString: string): {
  lang: string;
  filename: string;
  meta: string;
} {
  const langMatch = attrString.match(/data-lang="([^"]*)"/);
  const filenameMatch = attrString.match(/data-filename="([^"]*)"/);
  const metaMatch = attrString.match(/data-meta="([^"]*)"/);

  return {
    lang: langMatch?.[1] || "",
    filename: filenameMatch?.[1] || "",
    meta: metaMatch?.[1] || "",
  };
}

/**
 * Decode HTML entities in code content
 */
function decodeHtmlEntities(html: string): string {
  return html
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#x27;/g, "'")
    .replace(/&#x2F;/g, "/");
}

/**
 * Check if a language is supported by Shiki
 */
function isLanguageSupported(lang: string): lang is BundledLanguage {
  const normalizedLang = LANG_ALIASES[lang] || lang;
  return normalizedLang in bundledLanguages;
}

/**
 * Get the actual language to use (resolving aliases)
 */
function resolveLanguage(lang: string): BundledLanguage {
  return (LANG_ALIASES[lang] || lang) as BundledLanguage;
}

describe("extractDataAttributes", () => {
  it("should extract lang attribute", () => {
    const attrs = extractDataAttributes(' data-lang="json"');
    expect(attrs.lang).toBe("json");
    expect(attrs.filename).toBe("");
    expect(attrs.meta).toBe("");
  });

  it("should extract all attributes", () => {
    const attrs = extractDataAttributes(
      ' data-lang="ts" data-filename="src/index.ts" data-meta="{highlight=[1,2]}"'
    );
    expect(attrs.lang).toBe("ts");
    expect(attrs.filename).toBe("src/index.ts");
    expect(attrs.meta).toBe("{highlight=[1,2]}");
  });

  it("should handle missing attributes", () => {
    const attrs = extractDataAttributes("");
    expect(attrs.lang).toBe("");
    expect(attrs.filename).toBe("");
    expect(attrs.meta).toBe("");
  });
});

describe("decodeHtmlEntities", () => {
  it("should decode basic entities", () => {
    expect(decodeHtmlEntities("&lt;div&gt;")).toBe("<div>");
    expect(decodeHtmlEntities("&amp;&amp;")).toBe("&&");
    expect(decodeHtmlEntities("&quot;test&quot;")).toBe('"test"');
  });

  it("should decode single quotes", () => {
    expect(decodeHtmlEntities("&#39;test&#39;")).toBe("'test'");
    expect(decodeHtmlEntities("&#x27;test&#x27;")).toBe("'test'");
  });

  it("should handle complex code", () => {
    const encoded =
      "function test() { return &quot;hello&quot; &amp;&amp; &#39;world&#39; }";
    const decoded = 'function test() { return "hello" && \'world\' }';
    expect(decodeHtmlEntities(encoded)).toBe(decoded);
  });
});

describe("isLanguageSupported", () => {
  it("should recognize standard languages", () => {
    expect(isLanguageSupported("json")).toBe(true);
    expect(isLanguageSupported("javascript")).toBe(true);
    expect(isLanguageSupported("typescript")).toBe(true);
    expect(isLanguageSupported("html")).toBe(true);
    expect(isLanguageSupported("css")).toBe(true);
    expect(isLanguageSupported("rust")).toBe(true);
  });

  it("should recognize aliased languages", () => {
    expect(isLanguageSupported("js")).toBe(true);
    expect(isLanguageSupported("ts")).toBe(true);
    expect(isLanguageSupported("mbt")).toBe(true);
    expect(isLanguageSupported("moonbit")).toBe(true);
    expect(isLanguageSupported("sh")).toBe(true);
  });

  it("should return false for unknown languages", () => {
    expect(isLanguageSupported("foobar")).toBe(false);
    expect(isLanguageSupported("xyz123")).toBe(false);
  });
});

describe("resolveLanguage", () => {
  it("should resolve aliases", () => {
    expect(resolveLanguage("js")).toBe("javascript");
    expect(resolveLanguage("ts")).toBe("typescript");
    expect(resolveLanguage("mbt")).toBe("rust");
    expect(resolveLanguage("moonbit")).toBe("rust");
  });

  it("should pass through standard languages", () => {
    expect(resolveLanguage("json")).toBe("json");
    expect(resolveLanguage("html")).toBe("html");
    expect(resolveLanguage("css")).toBe("css");
  });
});

describe("CODE_BLOCK_REGEX", () => {
  it("should match simple code block", () => {
    const html =
      '<pre class="code-block" data-lang="json"><code class="language-json">{"key": "value"}</code></pre>';
    const matches = [...html.matchAll(CODE_BLOCK_REGEX)];
    expect(matches).toHaveLength(1);
    expect(matches[0][1]).toContain('data-lang="json"');
    expect(matches[0][2]).toBe('{"key": "value"}');
  });

  it("should match code block with filename", () => {
    const html =
      '<pre class="code-block" data-lang="ts" data-filename="index.ts"><code class="language-ts">const x = 1;</code></pre>';
    const matches = [...html.matchAll(CODE_BLOCK_REGEX)];
    expect(matches).toHaveLength(1);
    const attrs = extractDataAttributes(matches[0][1]);
    expect(attrs.lang).toBe("ts");
    expect(attrs.filename).toBe("index.ts");
  });

  it("should match multiline code", () => {
    const html = `<pre class="code-block" data-lang="javascript"><code class="language-javascript">function hello() {
  return "world";
}
</code></pre>`;
    const matches = [...html.matchAll(CODE_BLOCK_REGEX)];
    expect(matches).toHaveLength(1);
    expect(matches[0][2]).toContain("function hello()");
    expect(matches[0][2]).toContain('return "world"');
  });

  it("should match multiple code blocks", () => {
    const html = `
<pre class="code-block" data-lang="json"><code class="language-json">{"a": 1}</code></pre>
<p>Some text</p>
<pre class="code-block" data-lang="html"><code class="language-html">&lt;div&gt;test&lt;/div&gt;</code></pre>
`;
    const matches = [...html.matchAll(CODE_BLOCK_REGEX)];
    expect(matches).toHaveLength(2);
    expect(extractDataAttributes(matches[0][1]).lang).toBe("json");
    expect(extractDataAttributes(matches[1][1]).lang).toBe("html");
  });

  it("should not match non-code-block pre tags", () => {
    const html =
      '<pre class="other"><code>const x = 1;</code></pre>';
    const matches = [...html.matchAll(CODE_BLOCK_REGEX)];
    expect(matches).toHaveLength(0);
  });
});

describe("Shiki highlighting integration", () => {
  let highlighter: Highlighter;

  beforeAll(async () => {
    highlighter = await createHighlighter({
      themes: [THEMES.light, THEMES.dark],
      langs: ["json", "javascript", "typescript", "html", "css", "rust"],
    });
  });

  it("should tokenize JSON code", async () => {
    const code = '{\n  "name": "test",\n  "version": "1.0.0"\n}';
    const result = highlighter.codeToHtml(code, {
      lang: "json",
      themes: THEMES,
      defaultColor: false,
    });

    expect(result).toContain("class=\"shiki");
    expect(result).toContain("--shiki-light:");
    expect(result).toContain("--shiki-dark:");
    // Should have syntax-highlighted spans
    expect(result).toContain("<span");
  });

  it("should tokenize JavaScript code", async () => {
    const code = 'function hello() {\n  return "world";\n}';
    const result = highlighter.codeToHtml(code, {
      lang: "javascript",
      themes: THEMES,
      defaultColor: false,
    });

    expect(result).toContain("class=\"shiki");
    expect(result).toContain("<span");
    // Keywords should be styled
    expect(result).toContain("function");
    expect(result).toContain("return");
  });

  it("should tokenize TypeScript code", async () => {
    const code = "interface User {\n  name: string;\n  age: number;\n}";
    const result = highlighter.codeToHtml(code, {
      lang: "typescript",
      themes: THEMES,
      defaultColor: false,
    });

    expect(result).toContain("class=\"shiki");
    expect(result).toContain("interface");
    expect(result).toContain("string");
    expect(result).toContain("number");
  });

  it("should tokenize HTML code", async () => {
    const code = "<div class=\"container\">\n  <p>Hello</p>\n</div>";
    const result = highlighter.codeToHtml(code, {
      lang: "html",
      themes: THEMES,
      defaultColor: false,
    });

    expect(result).toContain("class=\"shiki");
    expect(result).toContain("div");
    expect(result).toContain("class");
    expect(result).toContain("container");
  });

  it("should tokenize CSS code", async () => {
    const code =
      ".container {\n  color: red;\n  background: var(--bg);\n}";
    const result = highlighter.codeToHtml(code, {
      lang: "css",
      themes: THEMES,
      defaultColor: false,
    });

    expect(result).toContain("class=\"shiki");
    expect(result).toContain("container");
    expect(result).toContain("color");
    expect(result).toContain("red");
  });

  it("should tokenize Rust code (for MoonBit)", async () => {
    const code = "fn main() {\n  let x = 42;\n  println!(\"x = {}\", x);\n}";
    const result = highlighter.codeToHtml(code, {
      lang: "rust",
      themes: THEMES,
      defaultColor: false,
    });

    expect(result).toContain("class=\"shiki");
    expect(result).toContain("fn");
    expect(result).toContain("let");
    expect(result).toContain("main");
  });
});

describe("Full HTML processing", () => {
  let highlighter: Highlighter;

  beforeAll(async () => {
    highlighter = await createHighlighter({
      themes: [THEMES.light, THEMES.dark],
      langs: ["json"],
    });
  });

  async function highlightCode(
    code: string,
    lang: string,
    filename: string,
    meta: string
  ): Promise<string> {
    const decodedCode = decodeHtmlEntities(code);
    const resolvedLang = resolveLanguage(lang);

    if (!isLanguageSupported(lang)) {
      const filenameAttr = filename ? ` data-filename="${filename}"` : "";
      const metaAttr = meta ? ` data-meta="${meta}"` : "";
      return `<pre class="shiki" data-lang="${lang}"${filenameAttr}${metaAttr}><code>${code}</code></pre>`;
    }

    try {
      const loadedLangs = highlighter.getLoadedLanguages();
      if (!loadedLangs.includes(resolvedLang)) {
        await highlighter.loadLanguage(resolvedLang);
      }

      const highlighted = highlighter.codeToHtml(decodedCode, {
        lang: resolvedLang,
        themes: THEMES,
        defaultColor: false,
      });

      if (filename) {
        return `<div class="code-block-wrapper" data-lang="${lang}">
  <div class="code-block-header">
    <span class="code-block-filename">${filename}</span>
    <span class="code-block-lang">${lang}</span>
  </div>
  ${highlighted}
</div>`;
      }

      return highlighted;
    } catch (error) {
      return `<pre class="shiki" data-lang="${lang}"><code>${code}</code></pre>`;
    }
  }

  async function processHtml(html: string): Promise<string> {
    const matches = [...html.matchAll(CODE_BLOCK_REGEX)];

    if (matches.length === 0) {
      return html;
    }

    let result = html;

    for (let i = matches.length - 1; i >= 0; i--) {
      const match = matches[i];
      const [fullMatch, attrString, codeContent] = match;
      const { lang, filename, meta } = extractDataAttributes(attrString);

      if (!lang) {
        continue;
      }

      const highlighted = await highlightCode(codeContent, lang, filename, meta);
      result =
        result.slice(0, match.index!) +
        highlighted +
        result.slice(match.index! + fullMatch.length);
    }

    return result;
  }

  it("should process HTML and replace code blocks with shiki output", async () => {
    const input = `<!DOCTYPE html>
<html>
<body>
<pre class="code-block" data-lang="json"><code class="language-json">{
  &quot;name&quot;: &quot;test&quot;
}</code></pre>
</body>
</html>`;

    const result = await processHtml(input);

    // Should no longer have code-block class
    expect(result).not.toContain('class="code-block"');
    // Should have shiki classes
    expect(result).toContain('class="shiki');
    // Should have CSS variables for theming
    expect(result).toContain("--shiki-light:");
    expect(result).toContain("--shiki-dark:");
    // HTML structure should be preserved
    expect(result).toContain("<!DOCTYPE html>");
    expect(result).toContain("<html>");
    expect(result).toContain("</body>");
  });

  it("should handle code block with filename", async () => {
    const input = `<pre class="code-block" data-lang="json" data-filename="package.json"><code class="language-json">{"a": 1}</code></pre>`;

    const result = await processHtml(input);

    expect(result).toContain("code-block-wrapper");
    expect(result).toContain("code-block-header");
    expect(result).toContain("code-block-filename");
    expect(result).toContain("package.json");
  });

  it("should handle unsupported language", async () => {
    const input = `<pre class="code-block" data-lang="foobar"><code class="language-foobar">some code</code></pre>`;

    const result = await processHtml(input);

    // Should fall back to plain shiki wrapper
    expect(result).toContain('class="shiki"');
    expect(result).toContain('data-lang="foobar"');
    expect(result).toContain("some code");
  });

  it("should preserve non-code content", async () => {
    const input = `<h1>Title</h1>
<p>Some paragraph</p>
<pre class="code-block" data-lang="json"><code class="language-json">{}</code></pre>
<p>Another paragraph</p>`;

    const result = await processHtml(input);

    expect(result).toContain("<h1>Title</h1>");
    expect(result).toContain("<p>Some paragraph</p>");
    expect(result).toContain("<p>Another paragraph</p>");
    expect(result).toContain('class="shiki');
  });
});
