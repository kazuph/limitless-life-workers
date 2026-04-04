import { env } from "cloudflare:test";
import { describe, it, expect } from "vitest";
import { get_html_rewriter_handler } from "../../target/js/release/build/examples/cfw/cfw.js";

describe("Cloudflare Worker HTMLRewriter - MoonBit", () => {
  const handler = get_html_rewriter_handler();
  const ctx = { waitUntil: () => {}, passThroughOnException: () => {} };

  it("should return help/endpoints at root", async () => {
    const request = new Request("http://localhost/");
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.json();
    expect(body.endpoints).toBeDefined();
    expect(Array.isArray(body.endpoints)).toBe(true);
  });

  it("should rewrite title tag content", async () => {
    const html = encodeURIComponent("<html><head><title>Old Title</title></head><body></body></html>");
    const newTitle = encodeURIComponent("New Title");
    const request = new Request(`http://localhost/rewrite/title?html=${html}&title=${newTitle}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain("<title>New Title</title>");
    expect(body).not.toContain("Old Title");
  });

  it("should add class to elements", async () => {
    const html = encodeURIComponent('<div id="test">Content</div>');
    const selector = encodeURIComponent("div");
    const className = encodeURIComponent("new-class");
    const request = new Request(`http://localhost/rewrite/add-class?html=${html}&selector=${selector}&class=${className}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain('class="new-class"');
  });

  it("should append to existing class", async () => {
    const html = encodeURIComponent('<div class="existing">Content</div>');
    const selector = encodeURIComponent("div");
    const className = encodeURIComponent("added");
    const request = new Request(`http://localhost/rewrite/add-class?html=${html}&selector=${selector}&class=${className}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain('class="existing added"');
  });

  it("should remove elements", async () => {
    const html = encodeURIComponent('<div><span class="remove-me">Gone</span><p>Keep</p></div>');
    const selector = encodeURIComponent(".remove-me");
    const request = new Request(`http://localhost/rewrite/remove?html=${html}&selector=${selector}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).not.toContain("Gone");
    expect(body).not.toContain("remove-me");
    expect(body).toContain("<p>Keep</p>");
  });

  it("should replace element content", async () => {
    const html = encodeURIComponent('<div id="target">Old Content</div>');
    const selector = encodeURIComponent("#target");
    const content = encodeURIComponent("New Content");
    const request = new Request(`http://localhost/rewrite/replace?html=${html}&selector=${selector}&content=${content}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain("New Content");
    expect(body).not.toContain("Old Content");
  });

  it("should append content to elements", async () => {
    const html = encodeURIComponent('<ul><li>Item 1</li></ul>');
    const selector = encodeURIComponent("ul");
    const content = encodeURIComponent("<li>Item 2</li>");
    const request = new Request(`http://localhost/rewrite/append?html=${html}&selector=${selector}&content=${content}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain("<li>Item 1</li><li>Item 2</li>");
  });

  it("should prepend content to elements", async () => {
    const html = encodeURIComponent('<ul><li>Item 2</li></ul>');
    const selector = encodeURIComponent("ul");
    const content = encodeURIComponent("<li>Item 1</li>");
    const request = new Request(`http://localhost/rewrite/prepend?html=${html}&selector=${selector}&content=${content}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain("<li>Item 1</li><li>Item 2</li>");
  });

  it("should set attribute on elements", async () => {
    const html = encodeURIComponent('<a href="#">Link</a>');
    const selector = encodeURIComponent("a");
    const attr = encodeURIComponent("target");
    const value = encodeURIComponent("_blank");
    const request = new Request(`http://localhost/rewrite/set-attribute?html=${html}&selector=${selector}&attr=${attr}&value=${value}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain('target="_blank"');
  });

  it("should remove attribute from elements", async () => {
    const html = encodeURIComponent('<div data-remove="yes" id="keep">Content</div>');
    const selector = encodeURIComponent("div");
    const attr = encodeURIComponent("data-remove");
    const request = new Request(`http://localhost/rewrite/remove-attribute?html=${html}&selector=${selector}&attr=${attr}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).not.toContain("data-remove");
    expect(body).toContain('id="keep"');
  });

  it("should wrap elements with before/after content", async () => {
    const html = encodeURIComponent('<p>Content</p>');
    const selector = encodeURIComponent("p");
    const before = encodeURIComponent("<div>");
    const after = encodeURIComponent("</div>");
    const request = new Request(`http://localhost/rewrite/wrap?html=${html}&selector=${selector}&before=${before}&after=${after}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain("<div><p>Content</p></div>");
  });

  it("should change tag name", async () => {
    const html = encodeURIComponent('<div class="heading">Title</div>');
    const selector = encodeURIComponent(".heading");
    const tag = encodeURIComponent("h1");
    const request = new Request(`http://localhost/rewrite/change-tag?html=${html}&selector=${selector}&tag=${tag}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain('<h1 class="heading">Title</h1>');
    expect(body).not.toContain("<div");
  });

  it("should replace text content", async () => {
    const html = encodeURIComponent('<p>Hello World</p>');
    const selector = encodeURIComponent("p");
    const find = encodeURIComponent("World");
    const replace = encodeURIComponent("MoonBit");
    const request = new Request(`http://localhost/rewrite/text?html=${html}&selector=${selector}&find=${find}&replace=${replace}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain("Hello MoonBit");
    expect(body).not.toContain("World");
  });

  it("should append content at document end", async () => {
    const html = encodeURIComponent('<html><body><p>Content</p></body></html>');
    const content = encodeURIComponent("<!-- Footer -->");
    const request = new Request(`http://localhost/rewrite/document-end?html=${html}&content=${content}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain("<!-- Footer -->");
    expect(body.indexOf("<!-- Footer -->")).toBeGreaterThan(body.indexOf("</html>") - 1);
  });

  it("should return 400 for missing parameters", async () => {
    // Missing title
    const request1 = new Request("http://localhost/rewrite/title?html=test");
    const response1 = await handler(request1, env, ctx);
    expect(response1.status).toBe(400);

    // Missing html
    const request2 = new Request("http://localhost/rewrite/title?title=test");
    const response2 = await handler(request2, env, ctx);
    expect(response2.status).toBe(400);

    // Missing selector for remove
    const request3 = new Request("http://localhost/rewrite/remove?html=test");
    const response3 = await handler(request3, env, ctx);
    expect(response3.status).toBe(400);
  });

  it("should handle multiple elements with same selector", async () => {
    const html = encodeURIComponent('<div><p>First</p><p>Second</p><p>Third</p></div>');
    const selector = encodeURIComponent("p");
    const className = encodeURIComponent("paragraph");
    const request = new Request(`http://localhost/rewrite/add-class?html=${html}&selector=${selector}&class=${className}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    // Count occurrences of class="paragraph"
    const matches = body.match(/class="paragraph"/g);
    expect(matches).toHaveLength(3);
  });

  it("should handle nested selectors", async () => {
    const html = encodeURIComponent('<div class="container"><div class="inner"><span>Text</span></div></div>');
    const selector = encodeURIComponent(".container .inner span");
    const content = encodeURIComponent("Modified");
    const request = new Request(`http://localhost/rewrite/replace?html=${html}&selector=${selector}&content=${content}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    expect(body).toContain("<span>Modified</span>");
    expect(body).not.toContain("Text");
  });

  it("should handle special characters in content", async () => {
    const html = encodeURIComponent('<div id="test">Original</div>');
    const selector = encodeURIComponent("#test");
    const content = encodeURIComponent("Special <chars> & \"quotes\"");
    const request = new Request(`http://localhost/rewrite/replace?html=${html}&selector=${selector}&content=${content}`);
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.text();
    // Content is inserted as text, so special chars should be escaped or preserved
    expect(body).toContain("Special");
  });
});
