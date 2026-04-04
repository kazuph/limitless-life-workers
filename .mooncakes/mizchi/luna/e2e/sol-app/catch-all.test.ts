import { test, expect } from "@playwright/test";

/**
 * E2E tests for catch-all routes in examples/sol-app
 * Tests [...slug] and [[...path]] patterns
 */
test.describe("Catch-All Routes", () => {
  const BASE_URL = "http://localhost:3457";

  test.describe("Required Catch-All [...slug]", () => {
    test("renders docs page with single segment", async ({ page }) => {
      await page.goto(`${BASE_URL}/docs/intro`);
      await expect(page.locator("h1")).toContainText("Documentation");
      await expect(page.locator("body")).toContainText("Current path: /docs/intro");
    });

    test("renders docs page with multiple segments", async ({ page }) => {
      await page.goto(`${BASE_URL}/docs/guide/getting-started`);
      await expect(page.locator("h1")).toContainText("Documentation");
      await expect(page.locator("body")).toContainText("Current path: /docs/guide/getting-started");
    });

    test("renders docs page with deep nested path", async ({ page }) => {
      await page.goto(`${BASE_URL}/docs/api/v1/users/create`);
      await expect(page.locator("h1")).toContainText("Documentation");
      await expect(page.locator("body")).toContainText("Current path: /docs/api/v1/users/create");
    });

    test("shows breadcrumbs for docs path", async ({ page }) => {
      await page.goto(`${BASE_URL}/docs/guide/getting-started`);
      const breadcrumbs = page.locator(".breadcrumbs");
      await expect(breadcrumbs).toContainText("docs");
      await expect(breadcrumbs).toContainText("guide");
      await expect(breadcrumbs).toContainText("getting-started");
    });
  });

  test.describe("Optional Catch-All [[...path]]", () => {
    test("renders blog index without path", async ({ page }) => {
      await page.goto(`${BASE_URL}/blog`);
      await expect(page.locator("h1")).toContainText("Blog");
      await expect(page.locator("body")).toContainText("Welcome to the blog!");
      await expect(page.locator("body")).toContainText("Recent posts:");
    });

    test("renders blog post with path", async ({ page }) => {
      await page.goto(`${BASE_URL}/blog/2024/12/hello-world`);
      await expect(page.locator("h1")).toContainText("Blog Post");
      await expect(page.locator("body")).toContainText("Path: 2024/12/hello-world");
    });

    test("renders blog post with deep nested path", async ({ page }) => {
      await page.goto(`${BASE_URL}/blog/tutorials/getting-started/chapter-1`);
      await expect(page.locator("h1")).toContainText("Blog Post");
      await expect(page.locator("body")).toContainText("Path: tutorials/getting-started/chapter-1");
    });

    test("has back link to blog index", async ({ page }) => {
      await page.goto(`${BASE_URL}/blog/2024/12/hello-world`);
      // Use more specific locator since nav also has a /blog link
      const backLink = page.locator('.post-meta a[href="/blog"]');
      await expect(backLink).toBeVisible();
      await backLink.click();
      await expect(page).toHaveURL(`${BASE_URL}/blog`);
      await expect(page.locator("h1")).toContainText("Blog");
    });
  });

  test.describe("Navigation", () => {
    test("navigates from home to docs", async ({ page }) => {
      await page.goto(BASE_URL);
      await page.click('a[href="/docs/intro"]');
      await expect(page).toHaveURL(`${BASE_URL}/docs/intro`);
      await expect(page.locator("h1")).toContainText("Documentation");
    });

    test("navigates from home to blog", async ({ page }) => {
      await page.goto(BASE_URL);
      await page.click('a[href="/blog"]');
      await expect(page).toHaveURL(`${BASE_URL}/blog`);
      await expect(page.locator("h1")).toContainText("Blog");
    });

    test("navigates between docs pages", async ({ page }) => {
      await page.goto(`${BASE_URL}/docs/intro`);
      await page.click('a[href="/docs/guide/getting-started"]');
      await expect(page).toHaveURL(`${BASE_URL}/docs/guide/getting-started`);
      await expect(page.locator("body")).toContainText("Current path: /docs/guide/getting-started");
    });

    test("navigates from blog index to post", async ({ page }) => {
      await page.goto(`${BASE_URL}/blog`);
      await page.click('a[href="/blog/2024/12/hello-world"]');
      await expect(page).toHaveURL(`${BASE_URL}/blog/2024/12/hello-world`);
      await expect(page.locator("h1")).toContainText("Blog Post");
    });
  });
});
