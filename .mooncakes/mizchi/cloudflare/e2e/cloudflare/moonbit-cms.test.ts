import { env } from "cloudflare:test";
import { describe, it, expect, beforeAll } from "vitest";
import { get_cms_handler } from "../../target/js/release/build/examples/cfw/cfw.js";

describe("Cloudflare Worker CMS - MoonBit", () => {
  const handler = get_cms_handler();
  const ctx = { waitUntil: () => {}, passThroughOnException: () => {} };

  // Use unique slugs/keys per test to avoid conflicts
  let testId = 0;
  const uniqueSlug = () => `slug-${Date.now()}-${++testId}`;
  const uniqueKey = () => `key-${Date.now()}-${++testId}.png`;

  beforeAll(async () => {
    // Initialize the database schema
    const request = new Request("http://localhost/cms/init", { method: "POST" });
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);
  });

  describe("Help Endpoint", () => {
    it("should return API documentation at root", async () => {
      const request = new Request("http://localhost/");
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(200);

      const body = await response.json();
      expect(body.endpoints).toBeDefined();
      expect(body.endpoints.articles).toBeDefined();
      expect(body.endpoints.images).toBeDefined();
      expect(body.endpoints.render).toBeDefined();
    });
  });

  describe("Articles CRUD", () => {
    it("should create an article", async () => {
      const slug = uniqueSlug();
      const request = new Request("http://localhost/cms/articles", {
        method: "POST",
        body: JSON.stringify({
          title: "First Post",
          content: "<p>Hello World</p>",
          slug,
        }),
        headers: { "Content-Type": "application/json" },
      });
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(201);

      const body = await response.json();
      expect(body.success).toBe(true);
      expect(body.slug).toBe(slug);
    });

    it("should list articles", async () => {
      const slug1 = uniqueSlug();
      const slug2 = uniqueSlug();

      // Create some articles first
      await handler(
        new Request("http://localhost/cms/articles", {
          method: "POST",
          body: JSON.stringify({ title: "Post 1", content: "Content 1", slug: slug1 }),
        }),
        env,
        ctx
      );
      await handler(
        new Request("http://localhost/cms/articles", {
          method: "POST",
          body: JSON.stringify({ title: "Post 2", content: "Content 2", slug: slug2 }),
        }),
        env,
        ctx
      );

      const request = new Request("http://localhost/cms/articles");
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(200);

      const body = await response.json();
      expect(body.count).toBeGreaterThanOrEqual(2);
      expect(body.articles.length).toBeGreaterThanOrEqual(2);
    });

    it("should get a single article", async () => {
      const slug = uniqueSlug();

      // Create an article
      await handler(
        new Request("http://localhost/cms/articles", {
          method: "POST",
          body: JSON.stringify({ title: "Test Article", content: "<p>Test Content</p>", slug }),
        }),
        env,
        ctx
      );

      const request = new Request(`http://localhost/cms/articles/${slug}`);
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(200);

      const body = await response.json();
      expect(body.title).toBe("Test Article");
      expect(body.content).toBe("<p>Test Content</p>");
      expect(body.slug).toBe(slug);
    });

    it("should return 404 for non-existent article", async () => {
      const request = new Request("http://localhost/cms/articles/non-existent-article-12345");
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(404);

      const body = await response.json();
      expect(body.error).toBe("Article not found");
    });

    it("should update an article", async () => {
      const slug = uniqueSlug();

      // Create an article
      await handler(
        new Request("http://localhost/cms/articles", {
          method: "POST",
          body: JSON.stringify({ title: "Original Title", content: "Original Content", slug }),
        }),
        env,
        ctx
      );

      // Update it
      const updateRequest = new Request(`http://localhost/cms/articles/${slug}`, {
        method: "PUT",
        body: JSON.stringify({ title: "Updated Title", content: "Updated Content" }),
      });
      const updateResponse = await handler(updateRequest, env, ctx);
      expect(updateResponse.status).toBe(200);

      // Verify the update
      const getRequest = new Request(`http://localhost/cms/articles/${slug}`);
      const getResponse = await handler(getRequest, env, ctx);
      const body = await getResponse.json();
      expect(body.title).toBe("Updated Title");
      expect(body.content).toBe("Updated Content");
    });

    it("should delete an article", async () => {
      const slug = uniqueSlug();

      // Create an article
      await handler(
        new Request("http://localhost/cms/articles", {
          method: "POST",
          body: JSON.stringify({ title: "To Delete", content: "Content", slug }),
        }),
        env,
        ctx
      );

      // Delete it
      const deleteRequest = new Request(`http://localhost/cms/articles/${slug}`, {
        method: "DELETE",
      });
      const deleteResponse = await handler(deleteRequest, env, ctx);
      expect(deleteResponse.status).toBe(200);

      // Verify deletion
      const getRequest = new Request(`http://localhost/cms/articles/${slug}`);
      const getResponse = await handler(getRequest, env, ctx);
      expect(getResponse.status).toBe(404);
    });

    it("should return 404 when updating non-existent article", async () => {
      const request = new Request("http://localhost/cms/articles/non-existent-update-12345", {
        method: "PUT",
        body: JSON.stringify({ title: "Title", content: "Content" }),
      });
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(404);
    });

    it("should return 404 when deleting non-existent article", async () => {
      const request = new Request("http://localhost/cms/articles/non-existent-delete-12345", {
        method: "DELETE",
      });
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(404);
    });
  });

  describe("Images (R2)", () => {
    it("should upload an image", async () => {
      const key = uniqueKey();
      const request = new Request(`http://localhost/cms/images?key=${key}`, {
        method: "POST",
        body: "fake-image-data",
      });
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(201);

      const body = await response.json();
      expect(body.success).toBe(true);
      expect(body.key).toBe(key);
      expect(body.size).toBeGreaterThan(0);
    });

    it("should get an image", async () => {
      const key = uniqueKey();

      // Upload first
      await handler(
        new Request(`http://localhost/cms/images?key=${key}`, {
          method: "POST",
          body: "image-content",
        }),
        env,
        ctx
      );

      // Get the image
      const request = new Request(`http://localhost/cms/images/${key}`);
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(200);

      const body = await response.text();
      expect(body).toBe("image-content");
    });

    it("should return 404 for non-existent image", async () => {
      const request = new Request("http://localhost/cms/images/non-existent-image-12345.png");
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(404);

      const body = await response.json();
      expect(body.error).toBe("Image not found");
    });

    it("should delete an image", async () => {
      const key = uniqueKey();

      // Upload first
      await handler(
        new Request(`http://localhost/cms/images?key=${key}`, {
          method: "POST",
          body: "delete-me",
        }),
        env,
        ctx
      );

      // Delete
      const deleteRequest = new Request(`http://localhost/cms/images/${key}`, {
        method: "DELETE",
      });
      const deleteResponse = await handler(deleteRequest, env, ctx);
      expect(deleteResponse.status).toBe(200);

      // Verify deletion
      const getRequest = new Request(`http://localhost/cms/images/${key}`);
      const getResponse = await handler(getRequest, env, ctx);
      expect(getResponse.status).toBe(404);
    });

    it("should list images", async () => {
      const key1 = uniqueKey();
      const key2 = uniqueKey();

      // Upload some images
      await handler(
        new Request(`http://localhost/cms/images?key=${key1}`, {
          method: "POST",
          body: "data1",
        }),
        env,
        ctx
      );
      await handler(
        new Request(`http://localhost/cms/images?key=${key2}`, {
          method: "POST",
          body: "data2",
        }),
        env,
        ctx
      );

      const request = new Request("http://localhost/cms/images");
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(200);

      const body = await response.json();
      expect(body.count).toBeGreaterThanOrEqual(2);
    });

    it("should return 400 when uploading without key", async () => {
      const request = new Request("http://localhost/cms/images", {
        method: "POST",
        body: "data",
      });
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(400);

      const body = await response.json();
      expect(body.error).toBe("Missing key parameter");
    });
  });

  describe("Render with HTMLRewriter", () => {
    it("should render article with HTML template", async () => {
      const slug = uniqueSlug();

      // Create an article
      await handler(
        new Request("http://localhost/cms/articles", {
          method: "POST",
          body: JSON.stringify({
            title: "Rendered Article",
            content: "<p>This is the rendered content.</p>",
            slug,
          }),
        }),
        env,
        ctx
      );

      const request = new Request(`http://localhost/cms/render/${slug}`);
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(200);
      expect(response.headers.get("content-type")).toContain("text/html");

      const body = await response.text();
      expect(body).toContain("<title>Rendered Article - CMS</title>");
      expect(body).toContain('<h1 class="title">Rendered Article</h1>');
      expect(body).toContain("<p>This is the rendered content.</p>");
    });

    it("should return 404 when rendering non-existent article", async () => {
      const request = new Request("http://localhost/cms/render/non-existent-render-12345");
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(404);

      const body = await response.json();
      expect(body.error).toBe("Article not found");
    });

    it("should handle HTML content in article", async () => {
      const slug = uniqueSlug();

      // Create an article with rich HTML
      await handler(
        new Request("http://localhost/cms/articles", {
          method: "POST",
          body: JSON.stringify({
            title: "Rich Content",
            content: "<h2>Subtitle</h2><ul><li>Item 1</li><li>Item 2</li></ul><p>Paragraph</p>",
            slug,
          }),
        }),
        env,
        ctx
      );

      const request = new Request(`http://localhost/cms/render/${slug}`);
      const response = await handler(request, env, ctx);
      expect(response.status).toBe(200);

      const body = await response.text();
      expect(body).toContain("<h2>Subtitle</h2>");
      expect(body).toContain("<li>Item 1</li>");
      expect(body).toContain("<li>Item 2</li>");
    });
  });

  describe("Integration Scenarios", () => {
    it("should handle complete article lifecycle", async () => {
      const slug = uniqueSlug();

      // Create
      const createResponse = await handler(
        new Request("http://localhost/cms/articles", {
          method: "POST",
          body: JSON.stringify({
            title: "Lifecycle Test",
            content: "Initial content",
            slug,
          }),
        }),
        env,
        ctx
      );
      expect(createResponse.status).toBe(201);

      // Read
      const getResponse = await handler(
        new Request(`http://localhost/cms/articles/${slug}`),
        env,
        ctx
      );
      expect(getResponse.status).toBe(200);

      // Update
      const updateResponse = await handler(
        new Request(`http://localhost/cms/articles/${slug}`, {
          method: "PUT",
          body: JSON.stringify({
            title: "Updated Lifecycle",
            content: "Updated content",
          }),
        }),
        env,
        ctx
      );
      expect(updateResponse.status).toBe(200);

      // Render
      const renderResponse = await handler(
        new Request(`http://localhost/cms/render/${slug}`),
        env,
        ctx
      );
      expect(renderResponse.status).toBe(200);
      const html = await renderResponse.text();
      expect(html).toContain("Updated Lifecycle");
      expect(html).toContain("Updated content");

      // Delete
      const deleteResponse = await handler(
        new Request(`http://localhost/cms/articles/${slug}`, {
          method: "DELETE",
        }),
        env,
        ctx
      );
      expect(deleteResponse.status).toBe(200);

      // Verify deleted
      const verifyResponse = await handler(
        new Request(`http://localhost/cms/articles/${slug}`),
        env,
        ctx
      );
      expect(verifyResponse.status).toBe(404);
    });

    // Note: Skipping combined D1+R2 test due to vitest-pool-workers isolated storage limitation
    // See: https://developers.cloudflare.com/workers/testing/vitest-integration/known-issues/#isolated-storage
  });
});
