import { env } from "cloudflare:test";
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { get_d1_handler } from "../../target/js/release/build/examples/cfw/cfw.js";

describe("Cloudflare Worker D1 - MoonBit", () => {
  const handler = get_d1_handler();
  const ctx = { waitUntil: () => {}, passThroughOnException: () => {} };

  beforeEach(async () => {
    // Initialize the users table
    const initRequest = new Request("http://localhost/d1/init");
    const initResponse = await handler(initRequest, env, ctx);
    expect(initResponse.status).toBe(200);
  });

  afterEach(async () => {
    // Clean up - drop the table
    const cleanupRequest = new Request("http://localhost/d1/cleanup");
    await handler(cleanupRequest, env, ctx);
  });

  it("should return help/endpoints at root", async () => {
    const request = new Request("http://localhost/");
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.json();
    expect(body.endpoints).toBeDefined();
    expect(Array.isArray(body.endpoints)).toBe(true);
  });

  it("should initialize the users table", async () => {
    // Already initialized in beforeEach, just verify it worked
    const listRequest = new Request("http://localhost/d1/users/list");
    const listResponse = await handler(listRequest, env, ctx);
    expect(listResponse.status).toBe(200);

    const body = await listResponse.json();
    expect(body.users).toBeDefined();
    expect(body.count).toBe(0);
  });

  it("should create a new user", async () => {
    const request = new Request(
      "http://localhost/d1/users/create?name=Alice&email=alice@example.com&age=30",
    );
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.json();
    expect(body.success).toBe(true);
    expect(body.id).toBeDefined();
    expect(body.id).toBeGreaterThan(0);
  });

  it("should get a user by ID", async () => {
    // First create a user
    const createRequest = new Request(
      "http://localhost/d1/users/create?name=Bob&email=bob@example.com&age=25",
    );
    const createResponse = await handler(createRequest, env, ctx);
    const createBody = await createResponse.json();
    const userId = createBody.id;

    // Then get the user
    const getRequest = new Request(`http://localhost/d1/users/get?id=${userId}`);
    const getResponse = await handler(getRequest, env, ctx);
    expect(getResponse.status).toBe(200);

    const getBody = await getResponse.json();
    expect(getBody.name).toBe("Bob");
    expect(getBody.email).toBe("bob@example.com");
    expect(getBody.age).toBe(25);
  });

  it("should return 404 for non-existent user", async () => {
    const request = new Request("http://localhost/d1/users/get?id=99999");
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(404);

    const body = await response.json();
    expect(body.error).toBe("User not found");
  });

  it("should list all users", async () => {
    // Create some users
    await handler(
      new Request(
        "http://localhost/d1/users/create?name=User1&email=user1@example.com&age=20",
      ),
      env,
      ctx,
    );
    await handler(
      new Request(
        "http://localhost/d1/users/create?name=User2&email=user2@example.com&age=30",
      ),
      env,
      ctx,
    );
    await handler(
      new Request(
        "http://localhost/d1/users/create?name=User3&email=user3@example.com&age=40",
      ),
      env,
      ctx,
    );

    const request = new Request("http://localhost/d1/users/list");
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.json();
    expect(body.count).toBe(3);
    expect(body.users).toHaveLength(3);
  });

  it("should update a user", async () => {
    // Create a user
    const createRequest = new Request(
      "http://localhost/d1/users/create?name=Original&email=update@example.com&age=20",
    );
    const createResponse = await handler(createRequest, env, ctx);
    const createBody = await createResponse.json();
    const userId = createBody.id;

    // Update the user
    const updateRequest = new Request(
      `http://localhost/d1/users/update?id=${userId}&name=Updated&age=25`,
    );
    const updateResponse = await handler(updateRequest, env, ctx);
    expect(updateResponse.status).toBe(200);

    const updateBody = await updateResponse.json();
    expect(updateBody.success).toBe(true);

    // Verify the update
    const getRequest = new Request(`http://localhost/d1/users/get?id=${userId}`);
    const getResponse = await handler(getRequest, env, ctx);
    const getBody = await getResponse.json();
    expect(getBody.name).toBe("Updated");
    expect(getBody.age).toBe(25);
  });

  it("should delete a user", async () => {
    // Create a user
    const createRequest = new Request(
      "http://localhost/d1/users/create?name=ToDelete&email=delete@example.com&age=30",
    );
    const createResponse = await handler(createRequest, env, ctx);
    const createBody = await createResponse.json();
    const userId = createBody.id;

    // Delete the user
    const deleteRequest = new Request(
      `http://localhost/d1/users/delete?id=${userId}`,
    );
    const deleteResponse = await handler(deleteRequest, env, ctx);
    expect(deleteResponse.status).toBe(200);

    const deleteBody = await deleteResponse.json();
    expect(deleteBody.success).toBe(true);

    // Verify deletion
    const getRequest = new Request(`http://localhost/d1/users/get?id=${userId}`);
    const getResponse = await handler(getRequest, env, ctx);
    expect(getResponse.status).toBe(404);
  });

  it("should count users", async () => {
    // Create some users
    await handler(
      new Request(
        "http://localhost/d1/users/create?name=Count1&email=count1@example.com&age=20",
      ),
      env,
      ctx,
    );
    await handler(
      new Request(
        "http://localhost/d1/users/create?name=Count2&email=count2@example.com&age=30",
      ),
      env,
      ctx,
    );

    const request = new Request("http://localhost/d1/users/count");
    const response = await handler(request, env, ctx);
    expect(response.status).toBe(200);

    const body = await response.json();
    expect(body.count).toBe(2);
  });

  it("should return 400 for missing parameters", async () => {
    // Create without name
    const createNoName = new Request(
      "http://localhost/d1/users/create?email=test@example.com",
    );
    const createNoNameResp = await handler(createNoName, env, ctx);
    expect(createNoNameResp.status).toBe(400);

    // Create without email
    const createNoEmail = new Request(
      "http://localhost/d1/users/create?name=Test",
    );
    const createNoEmailResp = await handler(createNoEmail, env, ctx);
    expect(createNoEmailResp.status).toBe(400);

    // Get without id
    const getNoId = new Request("http://localhost/d1/users/get");
    const getNoIdResp = await handler(getNoId, env, ctx);
    expect(getNoIdResp.status).toBe(400);

    // Update without id
    const updateNoId = new Request(
      "http://localhost/d1/users/update?name=Test",
    );
    const updateNoIdResp = await handler(updateNoId, env, ctx);
    expect(updateNoIdResp.status).toBe(400);

    // Delete without id
    const deleteNoId = new Request("http://localhost/d1/users/delete");
    const deleteNoIdResp = await handler(deleteNoId, env, ctx);
    expect(deleteNoIdResp.status).toBe(400);
  });

  it("should handle cleanup correctly", async () => {
    // Create a user
    await handler(
      new Request(
        "http://localhost/d1/users/create?name=Cleanup&email=cleanup@example.com&age=30",
      ),
      env,
      ctx,
    );

    // Cleanup (drop table)
    const cleanupRequest = new Request("http://localhost/d1/cleanup");
    const cleanupResponse = await handler(cleanupRequest, env, ctx);
    expect(cleanupResponse.status).toBe(200);

    // Re-initialize
    const initRequest = new Request("http://localhost/d1/init");
    await handler(initRequest, env, ctx);

    // Verify table is empty
    const listRequest = new Request("http://localhost/d1/users/list");
    const listResponse = await handler(listRequest, env, ctx);
    const body = await listResponse.json();
    expect(body.count).toBe(0);
  });
});
