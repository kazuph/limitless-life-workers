import { env } from "cloudflare:test";
import { describe, it, expect, beforeEach } from "vitest";
import { get_r2_handler } from "../../target/js/release/build/examples/cfw/cfw.js";

describe("Cloudflare Worker R2 - MoonBit", () => {
  const handler = get_r2_handler();
  const ctx = { waitUntil: () => {}, passThroughOnException: () => {} };
  const TEST_R2 = env.TEST_R2 as R2Bucket;

  beforeEach(async () => {
    // Clean up test data
    try {
      const objects = await TEST_R2.list();
      for (const obj of objects.objects) {
        await TEST_R2.delete(obj.key);
      }
    } catch (error) {
      // Ignore cleanup errors
    }
  });

  it("should return help/endpoints at root", async () => {
    const request = new Request("http://localhost/");
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.json();
    expect(body.endpoints).toBeDefined();
    expect(Array.isArray(body.endpoints)).toBe(true);
  });

  it("should put and get an object", async () => {
    // Put an object
    const putRequest = new Request(
      "http://localhost/r2/put?key=test.txt&value=Hello, R2!",
    );
    const putResponse = await handler(putRequest, env, ctx);
    expect(putResponse.status).toBe(200);

    const putBody = await putResponse.json();
    expect(putBody.success).toBe(true);
    expect(putBody.key).toBe("test.txt");
    expect(putBody.size).toBeGreaterThan(0);

    // Get the object back
    const getRequest = new Request("http://localhost/r2/get?key=test.txt");
    const getResponse = await handler(getRequest, env, ctx);
    expect(getResponse.status).toBe(200);

    const getBody = await getResponse.json();
    expect(getBody.key).toBe("test.txt");
    expect(getBody.value).toBe("Hello, R2!");
  });

  it("should return 404 for non-existent object", async () => {
    const request = new Request("http://localhost/r2/get?key=nonexistent.txt");
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(404);

    const body = await response.json();
    expect(body.error).toBe("Object not found");
  });

  it("should get object metadata with head", async () => {
    // First put an object
    const putRequest = new Request(
      "http://localhost/r2/put?key=meta.txt&value=content",
    );
    await handler(putRequest, env, ctx);

    // Then get its metadata
    const headRequest = new Request("http://localhost/r2/head?key=meta.txt");
    const headResponse = await handler(headRequest, env, ctx);
    expect(headResponse.status).toBe(200);

    const body = await headResponse.json();
    expect(body.key).toBe("meta.txt");
    expect(body.size).toBeGreaterThan(0);
    expect(body.etag).toBeDefined();
    expect(body.version).toBeDefined();
  });

  it("should return 404 for head on non-existent object", async () => {
    const request = new Request(
      "http://localhost/r2/head?key=nonexistent.txt",
    );
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(404);
  });

  it("should delete an object", async () => {
    // First put an object
    const putRequest = new Request(
      "http://localhost/r2/put?key=todelete.txt&value=temporary",
    );
    await handler(putRequest, env, ctx);

    // Delete it
    const deleteRequest = new Request(
      "http://localhost/r2/delete?key=todelete.txt",
    );
    const deleteResponse = await handler(deleteRequest, env, ctx);
    expect(deleteResponse.status).toBe(200);

    const deleteBody = await deleteResponse.json();
    expect(deleteBody.success).toBe(true);

    // Verify it's deleted
    const getRequest = new Request("http://localhost/r2/get?key=todelete.txt");
    const getResponse = await handler(getRequest, env, ctx);
    expect(getResponse.status).toBe(404);
  });

  it("should list objects", async () => {
    // Put some objects
    await handler(
      new Request("http://localhost/r2/put?key=file1.txt&value=content1"),
      env,
      ctx,
    );
    await handler(
      new Request("http://localhost/r2/put?key=file2.txt&value=content2"),
      env,
      ctx,
    );
    await handler(
      new Request("http://localhost/r2/put?key=file3.txt&value=content3"),
      env,
      ctx,
    );

    const listRequest = new Request("http://localhost/r2/list");
    const listResponse = await handler(listRequest, env, ctx);
    expect(listResponse.status).toBe(200);

    const body = await listResponse.json();
    expect(body.count).toBe(3);
    expect(body.objects).toHaveLength(3);

    const keys = body.objects.map((o: { key: string }) => o.key);
    expect(keys).toContain("file1.txt");
    expect(keys).toContain("file2.txt");
    expect(keys).toContain("file3.txt");
  });

  it("should list objects with prefix", async () => {
    // Put objects with different prefixes
    await handler(
      new Request("http://localhost/r2/put?key=docs/readme.txt&value=readme"),
      env,
      ctx,
    );
    await handler(
      new Request("http://localhost/r2/put?key=docs/guide.txt&value=guide"),
      env,
      ctx,
    );
    await handler(
      new Request("http://localhost/r2/put?key=images/logo.png&value=logo"),
      env,
      ctx,
    );

    // List only docs/
    const listRequest = new Request("http://localhost/r2/list?prefix=docs/");
    const listResponse = await handler(listRequest, env, ctx);
    expect(listResponse.status).toBe(200);

    const body = await listResponse.json();
    expect(body.count).toBe(2);
    expect(body.objects.every((o: { key: string }) => o.key.startsWith("docs/"))).toBe(true);
  });

  it("should return 400 for missing key parameter", async () => {
    // Get without key
    const getRequest = new Request("http://localhost/r2/get");
    const getResponse = await handler(getRequest, env, ctx);
    expect(getResponse.status).toBe(400);

    // Head without key
    const headRequest = new Request("http://localhost/r2/head");
    const headResponse = await handler(headRequest, env, ctx);
    expect(headResponse.status).toBe(400);

    // Delete without key
    const deleteRequest = new Request("http://localhost/r2/delete");
    const deleteResponse = await handler(deleteRequest, env, ctx);
    expect(deleteResponse.status).toBe(400);

    // Put without key
    const putRequest = new Request("http://localhost/r2/put?value=test");
    const putResponse = await handler(putRequest, env, ctx);
    expect(putResponse.status).toBe(400);

    // Put without value
    const putRequest2 = new Request("http://localhost/r2/put?key=test");
    const putResponse2 = await handler(putRequest2, env, ctx);
    expect(putResponse2.status).toBe(400);
  });

  it("should handle unicode content", async () => {
    const unicodeContent = encodeURIComponent("Hello, 世界! 🌍");
    const putRequest = new Request(
      `http://localhost/r2/put?key=unicode.txt&value=${unicodeContent}`,
    );
    const putResponse = await handler(putRequest, env, ctx);
    expect(putResponse.status).toBe(200);

    const getRequest = new Request("http://localhost/r2/get?key=unicode.txt");
    const getResponse = await handler(getRequest, env, ctx);
    expect(getResponse.status).toBe(200);

    const body = await getResponse.json();
    expect(body.value).toBe("Hello, 世界! 🌍");
  });

  it("should overwrite existing object", async () => {
    // Put initial value
    await handler(
      new Request("http://localhost/r2/put?key=overwrite.txt&value=version1"),
      env,
      ctx,
    );

    // Overwrite with new value
    await handler(
      new Request("http://localhost/r2/put?key=overwrite.txt&value=version2"),
      env,
      ctx,
    );

    // Get should return new value
    const getRequest = new Request(
      "http://localhost/r2/get?key=overwrite.txt",
    );
    const getResponse = await handler(getRequest, env, ctx);
    const body = await getResponse.json();
    expect(body.value).toBe("version2");
  });
});
