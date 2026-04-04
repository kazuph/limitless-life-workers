import { test, expect, type Page } from "@playwright/test";

/**
 * E2E tests for Web Components SSR CSS injection and hydration
 *
 * Tests that:
 * 1. CSS is correctly embedded in Declarative Shadow DOM during SSR
 * 2. CSS styles are applied and preserved after hydration
 * 3. Multiple Web Components maintain style isolation
 */

// Helper to wait for WC to be ready
async function waitForWcCounter(page: Page) {
  await page.waitForSelector("wc-counter");
  // Wait for Shadow DOM to be available
  await page.waitForFunction(() => {
    const wc = document.querySelector("wc-counter");
    return wc && wc.shadowRoot;
  }, { timeout: 10000 });
}

test.describe("WC SSR CSS Injection", () => {
  test.describe("SSR CSS embedding", () => {
    test("SSR generates Declarative Shadow DOM with <style> tag", async ({ page }) => {
      // Fetch page HTML directly (before JS runs)
      const response = await page.request.get("/wc-counter");
      const html = await response.text();

      // Verify SSR structure includes Declarative Shadow DOM
      expect(html).toContain('<template shadowrootmode="open">');
      // Style tag has hash ID for deduplication
      expect(html).toMatch(/<style id="style-\d+">/);
      expect(html).toContain(":host");
      expect(html).toContain(".count-display");
      expect(html).toContain("</template>");
    });

    test("SSR CSS includes all expected selectors", async ({ page }) => {
      const response = await page.request.get("/wc-counter");
      const html = await response.text();

      // Verify CSS content (minified: spaces around {} : ; are removed)
      expect(html).toContain(":host{display:block;}");
      expect(html).toContain(".counter{");
      expect(html).toContain(".count-display{");
      expect(html).toContain(".buttons button{");
    });

    test("SSR renders counter content inside Shadow DOM template", async ({ page }) => {
      const response = await page.request.get("/wc-counter");
      const html = await response.text();

      // Verify content is inside template
      expect(html).toContain('<div class="counter">');
      expect(html).toContain('<span class="count-display">');
      expect(html).toContain("</template></wc-counter>");
    });
  });

  test.describe("Hydration CSS preservation", () => {
    test("CSS styles are applied after hydration", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      await expect(wcCounter).toBeVisible();

      // Check that CSS is applied to Shadow DOM content
      const countDisplay = wcCounter.locator(".count-display");

      // Verify the element is styled (from wc_counter_css)
      await expect(countDisplay).toHaveCSS("font-size", "32px"); // 2rem
      await expect(countDisplay).toHaveCSS("font-weight", "700"); // bold
    });

    test("Shadow DOM has <style> element after hydration", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const result = await page.evaluate(() => {
        const wcCounter = document.querySelector("wc-counter");
        if (!wcCounter || !wcCounter.shadowRoot) {
          return { error: "No wc-counter or shadowRoot" };
        }

        const styleElement = wcCounter.shadowRoot.querySelector("style");
        return {
          hasStyleElement: !!styleElement,
          styleContent: styleElement?.textContent?.substring(0, 200) || "",
        };
      });

      expect(result).not.toHaveProperty("error");
      expect(result.hasStyleElement).toBe(true);
      expect(result.styleContent).toContain(":host");
    });

    test("CSS is not excessively duplicated after hydration", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const result = await page.evaluate(() => {
        const wcCounter = document.querySelector("wc-counter");
        if (!wcCounter || !wcCounter.shadowRoot) {
          return { error: "No wc-counter or shadowRoot" };
        }

        const styleElements = wcCounter.shadowRoot.querySelectorAll("style");
        return {
          styleCount: styleElements.length,
        };
      });

      expect(result).not.toHaveProperty("error");
      // Should have at most 2 style elements (SSR style + possibly hydration style)
      expect(result.styleCount).toBeLessThanOrEqual(2);
    });

    test("Interactive functionality works after hydration with CSS intact", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");
      const incButton = wcCounter.locator("button.inc");

      // Check initial state
      await expect(countDisplay).toContainText("0");

      // CSS should be applied
      await expect(countDisplay).toHaveCSS("font-size", "32px");

      // Click increment
      await incButton.click();
      await expect(countDisplay).toContainText("1");

      // CSS should still be applied after state change
      await expect(countDisplay).toHaveCSS("font-size", "32px");
      await expect(countDisplay).toHaveCSS("font-weight", "700");
    });
  });

  test.describe("CSS isolation", () => {
    test("WC CSS does not leak to document.head", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const result = await page.evaluate(() => {
        const headStyles = document.head.querySelectorAll("style");
        const leakedStyles: string[] = [];

        headStyles.forEach(style => {
          const content = style.textContent || "";
          // WC-specific selectors that should only be in shadowRoot
          if (content.includes(":host") && content.includes(".count-display {")) {
            leakedStyles.push(content.substring(0, 100));
          }
        });

        return {
          totalHeadStyles: headStyles.length,
          leakedCount: leakedStyles.length,
          leakedStyles,
        };
      });

      // WC CSS should NOT be in document.head
      expect(result.leakedCount).toBe(0);
    });

    test("External element with same class name is not affected by WC CSS", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const result = await page.evaluate(() => {
        // Create external element with same class
        const externalDiv = document.createElement("div");
        externalDiv.className = "count-display";
        externalDiv.textContent = "External";
        document.body.appendChild(externalDiv);

        const styles = window.getComputedStyle(externalDiv);
        const fontSize = styles.fontSize;
        const fontWeight = styles.fontWeight;

        externalDiv.remove();

        return { fontSize, fontWeight };
      });

      // External element should NOT have WC styles (32px, 700)
      expect(result.fontSize).not.toBe("32px");
      expect(result.fontWeight).not.toBe("700");
    });
  });

  test.describe("Page navigation CSS handling", () => {
    test("WC CSS is properly scoped during navigation", async ({ page }) => {
      // Start at home page
      await page.goto("/");
      await page.waitForTimeout(300);

      // Navigate to wc-counter page
      const wcCounterLink = page.locator('a[href="/wc-counter"]');
      if (await wcCounterLink.count() > 0) {
        await wcCounterLink.click();
        await waitForWcCounter(page);

        const wcCounter = page.locator("wc-counter");
        const countDisplay = wcCounter.locator(".count-display");
        await expect(countDisplay).toHaveCSS("font-size", "32px");

        // Navigate back
        const homeLink = page.locator('a[href="/"]');
        if (await homeLink.count() > 0) {
          await homeLink.click();
          await page.waitForTimeout(500);

          // Check that document.head doesn't have leaked WC styles
          const leakedCheck = await page.evaluate(() => {
            const headStyles = document.head.querySelectorAll("style");
            let hasWcStyles = false;

            headStyles.forEach(style => {
              const content = style.textContent || "";
              if (content.includes(":host") && content.includes(".count-display")) {
                hasWcStyles = true;
              }
            });

            return { hasWcStyles };
          });

          expect(leakedCheck.hasWcStyles).toBe(false);
        }
      }
    });
  });

  test.describe("Multiple instances style deduplication", () => {
    test("SSR generates separate Shadow DOM for each WC instance", async ({ page }) => {
      const response = await page.request.get("/wc-multiple");
      const html = await response.text();

      // Count occurrences of <template shadowrootmode="open">
      const templateCount = (html.match(/<template shadowrootmode="open">/g) || []).length;

      // Should have 3 separate Shadow DOMs for 3 WC instances
      expect(templateCount).toBe(3);
    });

    test("Each WC instance has style elements with proper selectors", async ({ page }) => {
      await page.goto("/wc-multiple");

      // Wait for all WC instances to be ready
      await page.waitForFunction(() => {
        const counters = document.querySelectorAll("wc-counter");
        return counters.length === 3 && Array.from(counters).every(wc => wc.shadowRoot);
      }, { timeout: 10000 });

      const result = await page.evaluate(() => {
        const counters = document.querySelectorAll("wc-counter");
        const styleInfo: { index: number; styleCount: number; hasHostSelector: boolean; hasSSRStyle: boolean }[] = [];

        counters.forEach((wc, index) => {
          const shadowRoot = wc.shadowRoot;
          if (shadowRoot) {
            const styles = shadowRoot.querySelectorAll("style");
            const hasHost = Array.from(styles).some(s =>
              s.textContent?.includes(":host")
            );
            // Check if SSR-generated style exists (has style-* id pattern)
            const hasSSRStyle = Array.from(styles).some(s => /^style-\d+$/.test(s.id));
            styleInfo.push({
              index,
              styleCount: styles.length,
              hasHostSelector: hasHost,
              hasSSRStyle,
            });
          }
        });

        return {
          wcCount: counters.length,
          styleInfo,
        };
      });

      expect(result.wcCount).toBe(3);

      // Each WC should have styles with :host selector
      // May have 1-2 styles (SSR + possibly client-injected)
      for (const info of result.styleInfo) {
        expect(info.styleCount).toBeGreaterThanOrEqual(1);
        expect(info.styleCount).toBeLessThanOrEqual(2);
        expect(info.hasHostSelector).toBe(true);
        // SSR style with hash ID should be present
        expect(info.hasSSRStyle).toBe(true);
      }
    });

    test("WC styles do not leak to document.head with multiple instances", async ({ page }) => {
      await page.goto("/wc-multiple");

      await page.waitForFunction(() => {
        const counters = document.querySelectorAll("wc-counter");
        return counters.length === 3 && Array.from(counters).every(wc => wc.shadowRoot);
      }, { timeout: 10000 });

      const result = await page.evaluate(() => {
        const headStyles = document.head.querySelectorAll("style");
        let wcStylesInHead = 0;

        headStyles.forEach(style => {
          const content = style.textContent || "";
          if (content.includes(":host") && content.includes(".count-display")) {
            wcStylesInHead++;
          }
        });

        return { wcStylesInHead };
      });

      // No WC styles should leak to document.head
      expect(result.wcStylesInHead).toBe(0);
    });

    test("All WC instances have styles with required selectors", async ({ page }) => {
      await page.goto("/wc-multiple");

      await page.waitForFunction(() => {
        const counters = document.querySelectorAll("wc-counter");
        return counters.length === 3 && Array.from(counters).every(wc => wc.shadowRoot);
      }, { timeout: 10000 });

      const result = await page.evaluate(() => {
        const counters = document.querySelectorAll("wc-counter");
        const styleInfo: { hasHost: boolean; hasCounterClass: boolean; hasButtonStyles: boolean }[] = [];

        counters.forEach(wc => {
          const shadowRoot = wc.shadowRoot;
          if (shadowRoot) {
            const styles = shadowRoot.querySelectorAll("style");
            const allCss = Array.from(styles).map(s => s.textContent || "").join("");
            styleInfo.push({
              hasHost: allCss.includes(":host"),
              hasCounterClass: allCss.includes(".counter"),
              hasButtonStyles: allCss.includes(".buttons button"),
            });
          }
        });

        return { styleInfo };
      });

      expect(result.styleInfo.length).toBe(3);

      // All WC instances should have the required CSS selectors
      for (const info of result.styleInfo) {
        expect(info.hasHost).toBe(true);
        expect(info.hasCounterClass).toBe(true);
        expect(info.hasButtonStyles).toBe(true);
      }
    });

    test("Each WC instance works independently with its own state", async ({ page }) => {
      await page.goto("/wc-multiple");

      await page.waitForFunction(() => {
        const counters = document.querySelectorAll("wc-counter");
        return counters.length === 3 && Array.from(counters).every(wc => wc.shadowRoot);
      }, { timeout: 10000 });

      const wcCounters = page.locator("wc-counter");

      // Get initial values
      const counter1Display = wcCounters.nth(0).locator(".count-display");
      const counter2Display = wcCounters.nth(1).locator(".count-display");
      const counter3Display = wcCounters.nth(2).locator(".count-display");

      await expect(counter1Display).toContainText("0");
      await expect(counter2Display).toContainText("10");
      await expect(counter3Display).toContainText("100");

      // Click increment on counter 1 only
      await wcCounters.nth(0).locator("button.inc").click();

      // Only counter 1 should change
      await expect(counter1Display).toContainText("1");
      await expect(counter2Display).toContainText("10");
      await expect(counter3Display).toContainText("100");

      // All should still have proper CSS
      await expect(counter1Display).toHaveCSS("font-size", "32px");
      await expect(counter2Display).toHaveCSS("font-size", "32px");
      await expect(counter3Display).toHaveCSS("font-size", "32px");
    });
  });

  test.describe("Error handling", () => {
    test("No console errors during SSR + hydration", async ({ page }) => {
      const errors: string[] = [];
      page.on("console", msg => {
        if (msg.type() === "error") {
          errors.push(msg.text());
        }
      });

      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      // Interact with the component
      const wcCounter = page.locator("wc-counter");
      const incButton = wcCounter.locator("button.inc");
      await incButton.click();

      // Wait for any async errors
      await page.waitForTimeout(300);

      // Filter out non-critical errors
      const criticalErrors = errors.filter(e =>
        !e.includes("favicon") && !e.includes("404")
      );

      expect(criticalErrors).toEqual([]);
    });
  });

  test.describe("State serialization", () => {
    test("Initial state from SSR is correctly parsed by client", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");

      // Initial state should be 0 (from SSR)
      await expect(countDisplay).toContainText("0");

      // Increment should work (proves state was correctly initialized)
      const incButton = wcCounter.locator("button.inc");
      await incButton.click();
      await expect(countDisplay).toContainText("1");
    });

    test("luna:wc-state attribute contains valid JSON", async ({ page }) => {
      const response = await page.request.get("/wc-counter");
      const html = await response.text();

      // Extract luna:wc-state value
      const stateMatch = html.match(/luna:wc-state="([^"]+)"/);
      expect(stateMatch).not.toBeNull();

      // Decode HTML entities and parse JSON
      const stateStr = stateMatch![1]
        .replace(/&quot;/g, '"')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&amp;/g, '&');

      const state = JSON.parse(stateStr);
      expect(state).toHaveProperty("initial_count");
      expect(typeof state.initial_count).toBe("number");
    });

    test("Multiple WC instances have different states", async ({ page }) => {
      await page.goto("/wc-multiple");

      await page.waitForFunction(() => {
        const counters = document.querySelectorAll("wc-counter");
        return counters.length === 3 && Array.from(counters).every(wc => wc.shadowRoot);
      }, { timeout: 10000 });

      const result = await page.evaluate(() => {
        const counters = document.querySelectorAll("wc-counter");
        return Array.from(counters).map(wc => {
          const stateAttr = wc.getAttribute("luna:wc-state") || "{}";
          try {
            return JSON.parse(stateAttr);
          } catch {
            return null;
          }
        });
      });

      // Each counter should have different initial_count
      expect(result[0]?.initial_count).toBe(0);
      expect(result[1]?.initial_count).toBe(10);
      expect(result[2]?.initial_count).toBe(100);
    });
  });

  test.describe("Hydration timing", () => {
    test("SSR content is visible before hydration completes", async ({ page }) => {
      // Disable JavaScript to see pure SSR content
      await page.route("**/*.js", route => route.abort());

      await page.goto("/wc-counter", { waitUntil: "domcontentloaded" });

      // SSR content should be visible even without JS
      const wcCounter = page.locator("wc-counter");
      await expect(wcCounter).toBeVisible();

      // Shadow DOM content should be rendered by Declarative Shadow DOM
      const countDisplay = wcCounter.locator(".count-display");
      await expect(countDisplay).toContainText("0");
    });

    test("Hydration preserves SSR DOM structure", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const result = await page.evaluate(() => {
        const wc = document.querySelector("wc-counter");
        if (!wc?.shadowRoot) return null;

        return {
          hasCounterDiv: !!wc.shadowRoot.querySelector(".counter"),
          hasCountDisplay: !!wc.shadowRoot.querySelector(".count-display"),
          hasButtons: !!wc.shadowRoot.querySelector(".buttons"),
          hasIncButton: !!wc.shadowRoot.querySelector("button.inc"),
          hasDecButton: !!wc.shadowRoot.querySelector("button.dec"),
        };
      });

      expect(result).not.toBeNull();
      expect(result!.hasCounterDiv).toBe(true);
      expect(result!.hasCountDisplay).toBe(true);
      expect(result!.hasButtons).toBe(true);
      expect(result!.hasIncButton).toBe(true);
      expect(result!.hasDecButton).toBe(true);
    });

    test("Hydration attaches event handlers to existing elements", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");

      // Initial value
      await expect(countDisplay).toContainText("0");

      // Click increment - this only works if handlers are attached
      await wcCounter.locator("button.inc").click();
      await expect(countDisplay).toContainText("1");

      // Click decrement
      await wcCounter.locator("button.dec").click();
      await expect(countDisplay).toContainText("0");

      // Multiple clicks
      await wcCounter.locator("button.inc").click();
      await wcCounter.locator("button.inc").click();
      await wcCounter.locator("button.inc").click();
      await expect(countDisplay).toContainText("3");
    });
  });

  test.describe("Reactivity after hydration", () => {
    test("Signal updates correctly reflect in DOM", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");
      const incButton = wcCounter.locator("button.inc");

      // Rapid clicks should all be captured
      for (let i = 0; i < 10; i++) {
        await incButton.click();
      }

      await expect(countDisplay).toContainText("10");
    });

    test("Negative values work correctly", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");
      const decButton = wcCounter.locator("button.dec");

      // Go negative
      await decButton.click();
      await decButton.click();
      await decButton.click();

      await expect(countDisplay).toContainText("-3");
    });

    test("State changes are reflected immediately", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");
      const incButton = wcCounter.locator("button.inc");

      // Each click should immediately update
      await incButton.click();
      await expect(countDisplay).toContainText("1");

      await incButton.click();
      await expect(countDisplay).toContainText("2");

      await incButton.click();
      await expect(countDisplay).toContainText("3");
    });
  });

  test.describe("DOM integrity", () => {
    test("Shadow DOM boundary is maintained after hydration", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const result = await page.evaluate(() => {
        const wc = document.querySelector("wc-counter");
        if (!wc) return { error: "wc-counter not found" };

        // These should NOT find elements inside shadow DOM
        const directCountDisplay = document.querySelector(".count-display");
        const directButtons = document.querySelector(".buttons");

        return {
          hasShadowRoot: !!wc.shadowRoot,
          directCountDisplayFound: !!directCountDisplay,
          directButtonsFound: !!directButtons,
        };
      });

      expect(result.hasShadowRoot).toBe(true);
      // Shadow DOM encapsulation: direct queries should NOT find internal elements
      expect(result.directCountDisplayFound).toBe(false);
      expect(result.directButtonsFound).toBe(false);
    });

    test("Declarative Shadow DOM template is removed after parsing", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const result = await page.evaluate(() => {
        const wc = document.querySelector("wc-counter");
        if (!wc) return { error: "wc-counter not found" };

        // Template should be consumed by the browser
        const template = wc.querySelector("template");
        return {
          templateExists: !!template,
          hasShadowRoot: !!wc.shadowRoot,
        };
      });

      // Declarative Shadow DOM template should be consumed
      expect(result.templateExists).toBe(false);
      expect(result.hasShadowRoot).toBe(true);
    });

    test("WC element has functional shadow DOM after hydration", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const result = await page.evaluate(() => {
        const wc = document.querySelector("wc-counter");
        if (!wc) return { error: "wc-counter not found" };

        return {
          tagName: wc.tagName,
          hasShadowRoot: !!wc.shadowRoot,
          shadowChildCount: wc.shadowRoot?.childElementCount || 0,
          hasStyle: !!wc.shadowRoot?.querySelector("style"),
          hasContent: !!wc.shadowRoot?.querySelector(".counter"),
        };
      });

      // Declarative Shadow DOM creates a functional shadow root
      // (doesn't require customElements.define())
      expect(result.tagName).toBe("WC-COUNTER");
      expect(result.hasShadowRoot).toBe(true);
      expect(result.shadowChildCount).toBeGreaterThan(0);
      expect(result.hasStyle).toBe(true);
      expect(result.hasContent).toBe(true);
    });
  });

  test.describe("Edge cases", () => {
    test("Rapid page navigation doesn't break hydration", async ({ page }) => {
      // Navigate to wc-counter
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      // Quick navigation away and back
      await page.goto("/");
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      // Should still work
      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");
      const incButton = wcCounter.locator("button.inc");

      await incButton.click();
      await expect(countDisplay).toContainText("1");
    });

    test("Multiple rapid clicks are all processed", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");
      const incButton = wcCounter.locator("button.inc");

      // Click as fast as possible
      const clicks = 20;
      const clickPromises = [];
      for (let i = 0; i < clicks; i++) {
        clickPromises.push(incButton.click());
      }
      await Promise.all(clickPromises);

      // All clicks should be counted
      await expect(countDisplay).toContainText(clicks.toString());
    });

    test("Alternating increment/decrement works correctly", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");
      const incButton = wcCounter.locator("button.inc");
      const decButton = wcCounter.locator("button.dec");

      // Alternating pattern
      await incButton.click(); // 1
      await decButton.click(); // 0
      await incButton.click(); // 1
      await incButton.click(); // 2
      await decButton.click(); // 1

      await expect(countDisplay).toContainText("1");
    });
  });

  test.describe("SSR HTML structure", () => {
    test("SSR output includes all required luna attributes", async ({ page }) => {
      const response = await page.request.get("/wc-counter");
      const html = await response.text();

      expect(html).toContain("luna:wc-url=");
      expect(html).toContain("luna:wc-state=");
      expect(html).toContain('<template shadowrootmode="open">');
    });

    test("SSR output has correct content inside shadow DOM", async ({ page }) => {
      const response = await page.request.get("/wc-counter");
      const html = await response.text();

      // Content should be inside template
      expect(html).toContain('<div class="counter">');
      expect(html).toContain('<span class="count-display">');
      expect(html).toContain('<div class="buttons">');
      expect(html).toContain('<button class="dec"');
      expect(html).toContain('<button class="inc"');
    });

    test("SSR escapes special characters in state", async ({ page }) => {
      const response = await page.request.get("/wc-counter");
      const html = await response.text();

      // State should use HTML entity encoding for quotes
      expect(html).toContain("luna:wc-state=");

      // Extract the luna:wc-state attribute value
      const stateMatch = html.match(/luna:wc-state="([^"]*)"/);
      expect(stateMatch).not.toBeNull();

      const stateValue = stateMatch![1];
      // Should contain escaped quotes (&quot;) not raw quotes
      // JSON uses quotes, so if properly escaped they become &quot;
      expect(stateValue).toContain("&quot;");
      // Should not contain raw unescaped double quotes
      expect(stateValue).not.toContain('"');
    });
  });
});
