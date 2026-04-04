import { test, expect } from "@playwright/test";

/**
 * E2E tests for examples/sol-app
 * Tests SSR, hydration, and navigation
 */
test.describe("Sol App E2E", () => {
  const BASE_URL = "http://localhost:3457";

  test.describe("SSR Rendering", () => {
    test("renders home page with title", async ({ page }) => {
      await page.goto(BASE_URL);
      await expect(page.locator("h1")).toContainText("Welcome to Sol");
    });

    test("renders counter island with correct attributes", async ({ page }) => {
      await page.goto(BASE_URL);

      // Island ID is generated from the component path
      const counter = page.locator('[luna\\:id="_static/counter_js"]');
      await expect(counter).toBeVisible();

      // Verify hydration attributes
      const url = await counter.getAttribute("luna:url");
      expect(url).toBe("/static/counter.js");

      const state = await counter.getAttribute("luna:state");
      expect(state).toContain("initial_count");
    });

    test("renders about page", async ({ page }) => {
      await page.goto(`${BASE_URL}/about`);
      await expect(page.locator("h1")).toContainText("About");
    });
  });

  test.describe("Hydration", () => {
    test("counter increments on click", async ({ page }) => {
      await page.goto(BASE_URL);

      // Wait for automatic hydration by loader.js
      await page.waitForTimeout(1500);

      const display = page.locator(".count-display");
      const incButton = page.locator("button.inc");

      // Get initial value (server-generated random number)
      const initial = await display.textContent();
      const initialNum = parseInt(initial || "0", 10);

      // Click increment
      await incButton.click();
      await page.waitForTimeout(100);

      const afterClick = await display.textContent();
      expect(parseInt(afterClick || "0", 10)).toBe(initialNum + 1);
    });

    test("counter decrements on click", async ({ page }) => {
      await page.goto(BASE_URL);

      // Wait for automatic hydration
      await page.waitForTimeout(1500);

      const display = page.locator(".count-display");
      const decButton = page.locator("button.dec");

      // Get initial value
      const initial = await display.textContent();
      const initialNum = parseInt(initial || "0", 10);

      // Click decrement
      await decButton.click();
      await page.waitForTimeout(100);

      const afterClick = await display.textContent();
      expect(parseInt(afterClick || "0", 10)).toBe(initialNum - 1);
    });

    test("multiple clicks work correctly", async ({ page }) => {
      await page.goto(BASE_URL);

      // Wait for automatic hydration
      await page.waitForTimeout(1500);

      const display = page.locator(".count-display");
      const incButton = page.locator("button.inc");

      // Get initial value
      const initial = await display.textContent();
      const initialNum = parseInt(initial || "0", 10);

      // Click 5 times
      for (let i = 0; i < 5; i++) {
        await incButton.click();
        await page.waitForTimeout(50);
      }
      await page.waitForTimeout(100);

      const finalValue = await display.textContent();
      expect(parseInt(finalValue || "0", 10)).toBe(initialNum + 5);
    });
  });

  test.describe("Navigation", () => {
    test("navigates from home to about", async ({ page }) => {
      await page.goto(BASE_URL);
      await page.click('a[href="/about"]');
      await expect(page).toHaveURL(`${BASE_URL}/about`);
      await expect(page.locator("h1")).toContainText("About");
    });

    test("navigates from about to home", async ({ page }) => {
      await page.goto(`${BASE_URL}/about`);
      await page.click('a[href="/"]');
      await expect(page).toHaveURL(`${BASE_URL}/`);
      await expect(page.locator("h1")).toContainText("Welcome to Sol");
    });
  });

  test.describe("API", () => {
    test("health endpoint returns response", async ({ request }) => {
      const response = await request.get(`${BASE_URL}/api/health`);
      expect(response.ok()).toBeTruthy();
    });
  });

  test.describe("Static Files", () => {
    test("loader.js is served", async ({ request }) => {
      const response = await request.get(`${BASE_URL}/static/loader.js`);
      expect(response.ok()).toBeTruthy();
      const content = await response.text();
      expect(content).toContain("luna loader");
    });

    test("island bundle is served", async ({ request }) => {
      const response = await request.get(`${BASE_URL}/static/counter.js`);
      expect(response.ok()).toBeTruthy();
      const content = await response.text();
      expect(content.length).toBeGreaterThan(100);
    });
  });
});
