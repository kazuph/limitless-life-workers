/**
 * Final Scroll State Diagnostic
 *
 * Scrolls with mouse wheel, waits for scroll snap to settle,
 * then checks if entries are cut off at the FINAL position.
 */

const { chromium } = require('playwright');

const BASE_URL = process.env.BASE_URL || 'http://localhost:8787/';

async function runDiagnostics() {
  console.log('=== Final Scroll State Diagnostic ===\n');
  console.log('Testing if scroll snap makes entries fully visible after scrolling settles\n');

  const browser = await chromium.launch({ headless: false, slowMo: 50 });
  const context = await browser.newContext({
    httpCredentials: { username: 'kazuph', password: 'lifelog' },
    viewport: { width: 1440, height: 900 }
  });
  const page = await context.newPage();

  console.log('Navigating to:', BASE_URL);
  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  const dayIndex = 1;
  const leftScrollId = `left-scroll-${dayIndex}`;

  // Scroll day into view
  await page.evaluate((idx) => {
    const el = document.getElementById(`left-scroll-${idx}`);
    if (el) {
      const card = el.parentElement?.parentElement?.parentElement;
      if (card) card.scrollIntoView({ behavior: 'instant', block: 'start' });
    }
  }, dayIndex);
  await page.waitForTimeout(500);

  // Get container info
  const info = await page.evaluate((id) => {
    const left = document.getElementById(id);
    if (!left) return null;
    return {
      maxScroll: left.scrollHeight - left.clientHeight,
      clientHeight: left.clientHeight
    };
  }, leftScrollId);

  console.log('Container info:', info);

  // Get scroll container position
  const leftBox = await page.evaluate((id) => {
    const el = document.getElementById(id);
    if (!el) return null;
    const rect = el.getBoundingClientRect();
    return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 };
  }, leftScrollId);

  // Move mouse to container
  await page.mouse.move(leftBox.x, leftBox.y);
  await page.waitForTimeout(300);

  // Test several wheel scroll amounts
  const testCases = [128, 256, 384, 512, 640, info.maxScroll];

  for (const targetScroll of testCases) {
    console.log(`\n--- Testing scroll to ~${targetScroll}px ---`);

    // Reset to top
    await page.evaluate((id) => {
      const el = document.getElementById(id);
      if (el) el.scrollTo({ top: 0, behavior: 'instant' });
    }, leftScrollId);
    await page.waitForTimeout(300);

    // Scroll with wheel
    await page.mouse.wheel(0, targetScroll);

    // Wait for scroll snap to settle (important!)
    await page.waitForTimeout(500);

    // Check final state
    const state = await page.evaluate((id) => {
      const left = document.getElementById(id);
      if (!left) return { error: 'not found' };

      const leftRect = left.getBoundingClientRect();
      const entries = left.querySelectorAll('[data-entry-id]');

      // Find all entries that are at least partially visible
      const visibleEntries = [];
      entries.forEach((entry, idx) => {
        const rect = entry.getBoundingClientRect();
        if (rect.bottom > leftRect.top && rect.top < leftRect.bottom) {
          const titleEl = entry.querySelector('.font-semibold');
          const titleRect = titleEl ? titleEl.getBoundingClientRect() : null;

          visibleEntries.push({
            index: idx,
            entryTop: Math.round(rect.top - leftRect.top),
            entryBottom: Math.round(rect.bottom - leftRect.top),
            titleTop: titleRect ? Math.round(titleRect.top - leftRect.top) : null,
            titleBottom: titleRect ? Math.round(titleRect.bottom - leftRect.top) : null,
            titleCutOff: titleRect ? Math.max(0, Math.round(titleRect.bottom - leftRect.bottom)) : null,
            isTitleCutOff: titleRect ? titleRect.bottom > leftRect.bottom : null,
            text: titleEl ? titleEl.textContent.trim().slice(0, 30) : 'N/A'
          });
        }
      });

      return {
        scrollTop: Math.round(left.scrollTop),
        containerHeight: Math.round(leftRect.height),
        visibleEntries
      };
    }, leftScrollId);

    console.log('Final scrollTop:', state.scrollTop);
    console.log('Visible entries:');
    for (const e of state.visibleEntries) {
      const status = e.isTitleCutOff ? `❌ TITLE CUT OFF by ${e.titleCutOff}px` : '✅ OK';
      console.log(`  Entry ${e.index}: "${e.text}" - ${status}`);
    }

    // Count cut-off entries
    const cutOff = state.visibleEntries.filter(e => e.isTitleCutOff).length;
    if (cutOff > 0) {
      console.log(`RESULT: ${cutOff} entries with cut-off titles`);
    } else {
      console.log('RESULT: All visible entries fully shown');
    }
  }

  console.log('\n\nBrowser staying open for 10 seconds...');
  await page.waitForTimeout(10000);

  await browser.close();
}

runDiagnostics().catch(err => {
  console.error('Diagnostic failed:', err);
  process.exit(1);
});
