import { test, expect } from "@playwright/test";

/**
 * E2E tests for SolRoutes::Layout functionality
 * Verifies that layouts wrap pages correctly and CSR navigation works
 */
test.describe("Layout Functionality", () => {
  const BASE_URL = "http://localhost:3457";

  test.describe("Layout Structure", () => {
    test("layout wraps home page with navigation", async ({ page }) => {
      await page.goto(BASE_URL);

      // Layout should have container
      const container = page.locator(".container");
      await expect(container).toBeVisible();

      // Layout should have nav with links
      const nav = page.locator("nav");
      await expect(nav).toBeVisible();

      // Nav should contain all expected links
      await expect(page.locator('nav a[href="/"]')).toBeVisible();
      await expect(page.locator('nav a[href="/about"]')).toBeVisible();
      await expect(page.locator('nav a[href="/form"]')).toBeVisible();
      await expect(page.locator('nav a[href="/wc-counter"]')).toBeVisible();
      await expect(page.locator('nav a[href="/docs/intro"]')).toBeVisible();
      await expect(page.locator('nav a[href="/blog"]')).toBeVisible();

      // Layout should have outlet
      const outlet = page.locator('[data-sol-outlet="main"]');
      await expect(outlet).toBeVisible();

      // Content should be inside outlet
      const h1 = page.locator('[data-sol-outlet="main"] h1');
      await expect(h1).toContainText("Welcome to Sol");
    });

    test("layout wraps about page correctly", async ({ page }) => {
      await page.goto(`${BASE_URL}/about`);

      // Same layout structure
      await expect(page.locator(".container")).toBeVisible();
      await expect(page.locator("nav")).toBeVisible();
      await expect(page.locator('[data-sol-outlet="main"]')).toBeVisible();

      // Different content
      const h1 = page.locator('[data-sol-outlet="main"] h1');
      await expect(h1).toContainText("About");
    });

    test("layout is NOT duplicated (single nav element)", async ({ page }) => {
      await page.goto(BASE_URL);

      // Should have exactly one nav
      const navCount = await page.locator("nav").count();
      expect(navCount).toBe(1);

      // Should have exactly one container
      const containerCount = await page.locator(".container").count();
      expect(containerCount).toBe(1);

      // Should have exactly one outlet
      const outletCount = await page.locator('[data-sol-outlet="main"]').count();
      expect(outletCount).toBe(1);
    });
  });

  test.describe("Layout Preservation on CSR Navigation", () => {
    test("layout is preserved during CSR navigation", async ({ page }) => {
      await page.goto(BASE_URL);

      // Get the nav element reference
      const navHandle = await page.locator("nav").elementHandle();
      const navId = await page.evaluate((nav) => {
        // Add a unique marker to track if same DOM element
        (nav as HTMLElement).dataset.testMarker = "original-nav";
        return (nav as HTMLElement).dataset.testMarker;
      }, navHandle);

      // Navigate to about via CSR
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      // Verify content changed
      await expect(page.locator("h1")).toContainText("About");

      // Check if nav still has the marker (same DOM element preserved)
      const markerAfter = await page.locator("nav").getAttribute("data-test-marker");
      expect(markerAfter).toBe("original-nav");
    });

    test("only outlet content is replaced during CSR", async ({ page }) => {
      await page.goto(BASE_URL);

      // Capture initial state
      const initialContent = await page.locator('[data-sol-outlet="main"]').innerHTML();

      // Navigate to about
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      // Outlet content should be different
      const newContent = await page.locator('[data-sol-outlet="main"]').innerHTML();
      expect(newContent).not.toBe(initialContent);

      // But nav should still be there
      await expect(page.locator("nav")).toBeVisible();
    });

    test("nav count stays 1 after multiple navigations", async ({ page }) => {
      await page.goto(BASE_URL);
      expect(await page.locator("nav").count()).toBe(1);

      // Navigate through multiple pages
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);
      expect(await page.locator("nav").count()).toBe(1);

      await page.click('[data-sol-link][href="/form"]');
      await page.waitForURL(`${BASE_URL}/form`);
      expect(await page.locator("nav").count()).toBe(1);

      await page.click('[data-sol-link][href="/wc-counter"]');
      await page.waitForURL(`${BASE_URL}/wc-counter`);
      expect(await page.locator("nav").count()).toBe(1);

      await page.click('[data-sol-link][href="/"]');
      await page.waitForURL(`${BASE_URL}/`);
      expect(await page.locator("nav").count()).toBe(1);
    });
  });

  test.describe("Layout with Dynamic Routes", () => {
    test("layout wraps docs catch-all route", async ({ page }) => {
      await page.goto(`${BASE_URL}/docs/intro`);

      // Layout should be present
      await expect(page.locator(".container")).toBeVisible();
      await expect(page.locator("nav")).toBeVisible();
      await expect(page.locator('[data-sol-outlet="main"]')).toBeVisible();

      // Content should be docs page
      await expect(page.locator("h1")).toContainText("Documentation");
    });

    test("layout wraps blog optional catch-all route", async ({ page }) => {
      await page.goto(`${BASE_URL}/blog`);

      // Layout should be present
      await expect(page.locator(".container")).toBeVisible();
      await expect(page.locator("nav")).toBeVisible();

      // Content should be blog index
      await expect(page.locator("h1")).toContainText("Blog");
    });

    test("CSR navigation to catch-all route preserves layout", async ({ page }) => {
      await page.goto(BASE_URL);
      expect(await page.locator("nav").count()).toBe(1);

      // Navigate to docs via CSR
      await page.click('[data-sol-link][href="/docs/intro"]');
      await page.waitForURL(`${BASE_URL}/docs/intro`);

      // Layout still intact
      expect(await page.locator("nav").count()).toBe(1);
      await expect(page.locator('[data-sol-outlet="main"]')).toBeVisible();
    });
  });
});
