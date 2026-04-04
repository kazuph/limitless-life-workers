/**
 * SSG Post-processor: Syntax highlighting with Shiki
 *
 * Transforms <pre class="code-block" data-lang="..."> elements in HTML files
 * to syntax-highlighted code using Shiki with CSS variables.
 *
 * Usage:
 *   npx tsx scripts/shiki-highlight.ts <directory>
 *   npx tsx scripts/shiki-highlight.ts dist-ssg
 *
 * This generates:
 *   - HTML with CSS class-based syntax highlighting
 *   - assets/shiki.css with theme definitions
 */

import * as fs from "node:fs";
import * as path from "node:path";
import * as crypto from "node:crypto";
import {
  type BundledLanguage,
  type BundledTheme,
  type Highlighter,
  bundledLanguages,
  createHighlighter,
} from "shiki";

// Configuration - using dual themes for light/dark mode
const THEMES: { light: BundledTheme; dark: BundledTheme } = {
  light: "github-light",
  dark: "github-dark",
};

// Cached highlighter instance
let highlighterInstance: Highlighter | null = null;

// Content hash cache: hash -> highlighted HTML
const highlightCache = new Map<string, string>();

// Cache directory for persistent storage
const CACHE_DIR = path.join(process.cwd(), "node_modules/.cache/shiki-highlight");
const CACHE_VERSION = "v1"; // Bump when shiki config changes

/**
 * Get or create highlighter instance (singleton)
 */
async function getHighlighter(): Promise<Highlighter> {
  if (!highlighterInstance) {
    highlighterInstance = await createHighlighter({
      themes: [THEMES.light, THEMES.dark],
      langs: [], // Load languages on demand
    });
  }
  return highlighterInstance;
}

/**
 * Generate content hash for cache key
 */
function hashContent(code: string, lang: string, meta: string): string {
  return crypto
    .createHash("md5")
    .update(`${CACHE_VERSION}:${lang}:${meta}:${code}`)
    .digest("hex");
}

/**
 * Load persistent cache from disk
 */
function loadPersistentCache(): void {
  const cacheFile = path.join(CACHE_DIR, "cache.json");
  if (fs.existsSync(cacheFile)) {
    try {
      const data = JSON.parse(fs.readFileSync(cacheFile, "utf-8"));
      if (data.version === CACHE_VERSION) {
        for (const [key, value] of Object.entries(data.entries)) {
          highlightCache.set(key, value as string);
        }
        console.log(`  ✓ Loaded ${highlightCache.size} cached highlights`);
      }
    } catch {
      // Invalid cache, ignore
    }
  }
}

/**
 * Save persistent cache to disk
 */
function savePersistentCache(): void {
  if (!fs.existsSync(CACHE_DIR)) {
    fs.mkdirSync(CACHE_DIR, { recursive: true });
  }
  const cacheFile = path.join(CACHE_DIR, "cache.json");
  const data = {
    version: CACHE_VERSION,
    entries: Object.fromEntries(highlightCache),
  };
  fs.writeFileSync(cacheFile, JSON.stringify(data), "utf-8");
}

// Language alias mapping
const LANG_ALIASES: Record<string, BundledLanguage> = {
  js: "javascript",
  ts: "typescript",
  mbt: "rust", // MoonBit syntax is similar to Rust
  moonbit: "rust",
  sh: "bash",
  shell: "bash",
  zsh: "bash",
  yml: "yaml",
  dockerfile: "docker",
};

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

// Track if we need shiki (lazy initialization)
let needsShiki = false;

/**
 * Highlight code using Shiki with dual themes (CSS variables)
 * Uses caching to avoid re-highlighting identical code blocks
 */
async function highlightCode(
  code: string,
  lang: string,
  filename: string,
  meta: string
): Promise<string> {
  const decodedCode = decodeHtmlEntities(code);
  const resolvedLang = resolveLanguage(lang);

  if (!isLanguageSupported(lang)) {
    // Return plain code block for unsupported languages
    const filenameAttr = filename ? ` data-filename="${filename}"` : "";
    const metaAttr = meta ? ` data-meta="${meta}"` : "";
    return `<pre class="shiki" data-lang="${lang}"${filenameAttr}${metaAttr}><code>${code}</code></pre>`;
  }

  // Check cache first (before initializing shiki)
  const cacheKey = hashContent(decodedCode, lang, meta);
  const cached = highlightCache.get(cacheKey);
  if (cached) {
    // Add filename wrapper if needed
    if (filename) {
      return `<div class="code-block-wrapper" data-lang="${lang}">
  <div class="code-block-header">
    <span class="code-block-filename">${filename}</span>
    <span class="code-block-lang">${lang}</span>
  </div>
  ${cached}
</div>`;
    }
    return cached;
  }

  // Mark that we need shiki for this run
  needsShiki = true;

  try {
    const highlighter = await getHighlighter();

    // Load language on demand if not already loaded
    const loadedLangs = highlighter.getLoadedLanguages();
    if (!loadedLangs.includes(resolvedLang)) {
      await highlighter.loadLanguage(resolvedLang);
    }

    // Use dual themes with CSS variables for light/dark mode switching
    const highlighted = highlighter.codeToHtml(decodedCode, {
      lang: resolvedLang,
      themes: THEMES,
      defaultColor: false, // Use CSS variables instead of inline colors
    });

    // Cache the result (without filename wrapper)
    highlightCache.set(cacheKey, highlighted);

    // Add filename header if present
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
    console.warn(`Warning: Failed to highlight ${lang} code:`, error);
    return `<pre class="shiki" data-lang="${lang}"><code>${code}</code></pre>`;
  }
}

/**
 * Process HTML content and highlight code blocks
 */
async function processHtml(html: string): Promise<string> {
  const matches = [...html.matchAll(CODE_BLOCK_REGEX)];

  if (matches.length === 0) {
    return html;
  }

  let result = html;

  // Process matches in reverse order to maintain positions
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

/**
 * Process a single HTML file
 */
async function processFile(filePath: string): Promise<boolean> {
  const content = fs.readFileSync(filePath, "utf-8");
  const processed = await processHtml(content);

  if (content !== processed) {
    fs.writeFileSync(filePath, processed, "utf-8");
    return true;
  }

  return false;
}

/**
 * Recursively find all HTML files in a directory
 */
function findHtmlFiles(dir: string): string[] {
  const files: string[] = [];

  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...findHtmlFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith(".html")) {
      files.push(fullPath);
    }
  }

  return files;
}

/**
 * Generate shiki CSS for dual theme support
 * Uses CSS variables for light/dark mode switching
 */
function generateShikiCss(): string {
  return `/* Shiki syntax highlighting - dual theme support */
/* Light theme (default) */
.shiki,
.shiki span {
  color: var(--shiki-light);
  background-color: var(--shiki-light-bg);
}

/* Dark theme */
@media (prefers-color-scheme: dark) {
  .shiki,
  .shiki span {
    color: var(--shiki-dark);
    background-color: var(--shiki-dark-bg);
  }
}

/* Manual dark mode class */
.dark .shiki,
.dark .shiki span {
  color: var(--shiki-dark);
  background-color: var(--shiki-dark-bg);
}

/* Code block styling */
.shiki {
  padding: 1rem;
  border-radius: 6px;
  overflow-x: auto;
  font-size: 0.875rem;
  line-height: 1.6;
}

.shiki code {
  background: none;
  padding: 0;
  font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace;
}

/* Code block with filename header */
.code-block-wrapper {
  margin: 1rem 0;
  border-radius: 6px;
  overflow: hidden;
  border: 1px solid var(--color-border-default, #d0d7de);
}

@media (prefers-color-scheme: dark) {
  .code-block-wrapper {
    border-color: var(--color-border-default, #30363d);
  }
}

.code-block-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 1rem;
  background: var(--color-canvas-subtle, #f6f8fa);
  border-bottom: 1px solid var(--color-border-default, #d0d7de);
  font-size: 0.75rem;
}

@media (prefers-color-scheme: dark) {
  .code-block-header {
    background: var(--color-canvas-subtle, #161b22);
    border-bottom-color: var(--color-border-default, #30363d);
  }
}

.code-block-filename {
  font-weight: 600;
  font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
}

.code-block-lang {
  color: var(--color-fg-muted, #656d76);
  text-transform: uppercase;
  font-size: 0.625rem;
  letter-spacing: 0.05em;
}

.code-block-wrapper .shiki {
  margin: 0;
  border-radius: 0;
}
`;
}

/**
 * Write shiki CSS to assets directory
 */
function writeShikiCss(targetDir: string): void {
  const assetsDir = path.join(targetDir, "assets");
  if (!fs.existsSync(assetsDir)) {
    fs.mkdirSync(assetsDir, { recursive: true });
  }

  const cssPath = path.join(assetsDir, "shiki.css");
  fs.writeFileSync(cssPath, generateShikiCss(), "utf-8");
  console.log(`  ✓ Generated assets/shiki.css`);
}

/**
 * Copy github-markdown-css to assets directory with patches
 */
function copyGithubMarkdownCss(targetDir: string): void {
  const assetsDir = path.join(targetDir, "assets");
  if (!fs.existsSync(assetsDir)) {
    fs.mkdirSync(assetsDir, { recursive: true });
  }

  // Try to find github-markdown-css in node_modules
  const possiblePaths = [
    path.join(process.cwd(), "node_modules/github-markdown-css/github-markdown.css"),
    path.join(process.cwd(), "node_modules/github-markdown-css/github-markdown-light.css"),
  ];

  for (const srcPath of possiblePaths) {
    if (fs.existsSync(srcPath)) {
      const destPath = path.join(assetsDir, "github-markdown.css");
      // Read, patch, and write
      let css = fs.readFileSync(srcPath, "utf-8");
      // Remove .markdown-body background-color to allow parent styling
      css = css.replace(
        /\.markdown-body\s*\{([^}]*?)background-color:\s*var\(--bgColor-default\);/g,
        ".markdown-body {$1/* background-color removed for shiki compatibility */"
      );
      fs.writeFileSync(destPath, css);
      console.log(`  ✓ Copied github-markdown.css (patched)`);
      return;
    }
  }

  console.warn("  ⚠ github-markdown-css not found in node_modules");
}

/**
 * Main function
 */
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    console.log(`
Usage: npx tsx scripts/shiki-highlight.ts <directory>

Processes HTML files in the specified directory and applies
syntax highlighting to code blocks using Shiki.

Output:
  - Transforms code blocks in HTML files
  - Generates assets/shiki.css for theme support

Options:
  -h, --help    Show this help message

Examples:
  npx tsx scripts/shiki-highlight.ts dist-ssg
  npx tsx scripts/shiki-highlight.ts src/sol/ssg/dist
`);
    process.exit(0);
  }

  const targetDir = args[0];

  if (!fs.existsSync(targetDir)) {
    console.error(`Error: Directory not found: ${targetDir}`);
    process.exit(1);
  }

  console.log(`Processing HTML files in: ${targetDir}`);
  const startTime = Date.now();

  // Load persistent cache
  loadPersistentCache();
  const cacheHitsBefore = highlightCache.size;

  // Generate CSS files
  writeShikiCss(targetDir);
  copyGithubMarkdownCss(targetDir);

  const htmlFiles = findHtmlFiles(targetDir);
  console.log(`Found ${htmlFiles.length} HTML files`);

  let processedCount = 0;

  for (const file of htmlFiles) {
    const relativePath = path.relative(targetDir, file);
    const modified = await processFile(file);
    if (modified) {
      console.log(`  ✓ ${relativePath}`);
      processedCount++;
    }
  }

  // Save persistent cache
  savePersistentCache();

  const elapsed = Date.now() - startTime;
  const newCacheEntries = highlightCache.size - cacheHitsBefore;
  console.log(`\nProcessed ${processedCount} files with code blocks`);
  console.log(`Cache: ${cacheHitsBefore} hits, ${newCacheEntries} new entries`);
  console.log(`Time: ${elapsed}ms`);
}

main().catch((error) => {
  console.error("Error:", error);
  process.exit(1);
});
