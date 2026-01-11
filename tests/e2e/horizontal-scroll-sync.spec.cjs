/**
 * E2E Test: Horizontal Scroll Sync
 *
 * Tests that the purple timeline bar stays visible when scrolling vertically.
 * As the user scrolls through entries from different hours, the horizontal
 * scroll should automatically adjust to keep the purple bar centered.
 */

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const FEATURE = 'fix-timeline-display';
const BASE_DIR = path.join(process.cwd(), '.artifacts', FEATURE);
const IMAGES_DIR = path.join(BASE_DIR, 'images');
const VIDEOS_DIR = path.join(BASE_DIR, 'videos');
const BASE_URL = process.env.BASE_URL || 'http://localhost:8788/';

async function runTest() {
  // Ensure directories exist
  fs.mkdirSync(IMAGES_DIR, { recursive: true });
  fs.mkdirSync(VIDEOS_DIR, { recursive: true });

  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({
    httpCredentials: { username: 'kazuph', password: 'lifelog' },
    viewport: { width: 1440, height: 900 },
    recordVideo: { dir: VIDEOS_DIR, size: { width: 1440, height: 900 } }
  });
  const page = await context.newPage();

  console.log('=== Horizontal Scroll Sync Test ===\n');
  console.log('Navigating to:', BASE_URL);
  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  const timestamp = new Date().toISOString().slice(0, 10).replace(/-/g, '');

  // Find the first day group with enough entries
  const dayGroupCount = await page.evaluate(() => {
    let count = 0;
    while (document.getElementById(`left-scroll-${count}`)) count++;
    return count;
  });
  console.log(`Found ${dayGroupCount} day groups\n`);

  // Test scroll sync on the first day group that has scrollable content
  let testGroupIdx = -1;
  for (let i = 0; i < dayGroupCount; i++) {
    const scrollInfo = await page.evaluate((idx) => {
      const el = document.getElementById(`left-scroll-${idx}`);
      if (!el) return null;
      return {
        scrollHeight: el.scrollHeight,
        clientHeight: el.clientHeight,
        canScroll: el.scrollHeight > el.clientHeight * 1.5 // Need significant scroll
      };
    }, i);

    if (scrollInfo && scrollInfo.canScroll) {
      testGroupIdx = i;
      console.log(`Using day group ${i} for test (scrollHeight: ${scrollInfo.scrollHeight}px)`);
      break;
    }
  }

  if (testGroupIdx < 0) {
    console.error('No day group found with enough scrollable content');
    await browser.close();
    process.exit(1);
  }

  const leftScrollId = `left-scroll-${testGroupIdx}`;
  const rightScrollId = `right-scroll-${testGroupIdx}`;

  // Scroll day group into view
  await page.evaluate((idx) => {
    const el = document.getElementById(`left-scroll-${idx}`);
    if (el) {
      const card = el.parentElement?.parentElement?.parentElement;
      if (card) card.scrollIntoView({ behavior: 'instant', block: 'start' });
    }
  }, testGroupIdx);
  await page.waitForTimeout(500);

  // Reset scroll to top
  await page.evaluate((id) => {
    const el = document.getElementById(id);
    if (el) el.scrollTo({ top: 0, behavior: 'instant' });
  }, leftScrollId);
  await page.waitForTimeout(500);

  // Get entry times for verification
  const entryTimes = await page.evaluate((id) => {
    const left = document.getElementById(id);
    if (!left) return [];
    const entries = left.querySelectorAll('[data-entry-id]');
    return Array.from(entries).map(entry => {
      const timeText = entry.querySelector('.text-sm')?.textContent || '';
      return timeText.slice(0, 5); // Get HH:MM
    });
  }, leftScrollId);
  console.log(`\nEntry times: ${entryTimes.slice(0, 5).join(', ')}... (${entryTimes.length} total)`);

  // Helper to check if purple bar is visible
  async function isPurpleBarVisible() {
    return await page.evaluate((rightId) => {
      const right = document.getElementById(rightId);
      if (!right) return { visible: false, reason: 'no right panel' };

      const viewport = right.getBoundingClientRect();
      const scrollLeft = right.scrollLeft;
      const viewportLeft = scrollLeft;
      const viewportRight = scrollLeft + viewport.width;

      // Find visible entry's bar
      const bars = right.querySelectorAll('[data-gantt-entry]');
      let visibleBars = 0;
      let hiddenBars = 0;

      bars.forEach(bar => {
        const rect = bar.getBoundingClientRect();
        const barAbsLeft = rect.left - viewport.left + scrollLeft;
        const barAbsRight = barAbsLeft + rect.width;

        // Check if bar overlaps with viewport
        const isVisible = barAbsRight > viewportLeft && barAbsLeft < viewportRight;
        if (isVisible) visibleBars++;
        else hiddenBars++;
      });

      // Get the most centered entry's bar position
      const left = document.getElementById(rightId.replace('right', 'left'));
      if (!left) return { visible: visibleBars > 0, visibleBars, hiddenBars };

      const containerRect = left.getBoundingClientRect();
      const containerCenter = containerRect.top + (containerRect.height / 2);
      let centerEntry = null;
      let minDist = Infinity;

      left.querySelectorAll('[data-entry-id]').forEach(entry => {
        const rect = entry.getBoundingClientRect();
        if (rect.bottom > containerRect.top && rect.top < containerRect.bottom) {
          const entryCenter = rect.top + (rect.height / 2);
          const dist = Math.abs(entryCenter - containerCenter);
          if (dist < minDist) {
            minDist = dist;
            centerEntry = entry;
          }
        }
      });

      if (!centerEntry) return { visible: visibleBars > 0, visibleBars, hiddenBars };

      const entryId = centerEntry.getAttribute('data-entry-id');
      const bar = right.querySelector(`[data-gantt-entry="${entryId}"]`);
      if (!bar) return { visible: visibleBars > 0, visibleBars, hiddenBars, centerEntry: 'no bar' };

      const barRect = bar.getBoundingClientRect();
      const barAbsLeft = barRect.left - viewport.left + scrollLeft;
      const barAbsRight = barAbsLeft + barRect.width;
      const centerBarVisible = barAbsRight > viewportLeft && barAbsLeft < viewportRight;

      return {
        visible: centerBarVisible,
        scrollLeft: Math.round(scrollLeft),
        barLeft: Math.round(barAbsLeft),
        barRight: Math.round(barAbsRight),
        viewportLeft: Math.round(viewportLeft),
        viewportRight: Math.round(viewportRight),
        visibleBars,
        hiddenBars
      };
    }, rightScrollId);
  }

  // Test scroll positions
  const scrollPositions = [0, 0.25, 0.5, 0.75, 1.0];
  const results = [];

  console.log('\n--- Scroll Sync Test Results ---\n');
  console.log('Position | Scroll Y | H-Scroll | Bar Visible | Status');
  console.log('---------|----------|----------|-------------|-------');

  for (const ratio of scrollPositions) {
    // Scroll to position
    await page.evaluate(({ id, ratio }) => {
      const el = document.getElementById(id);
      if (el) {
        const targetY = (el.scrollHeight - el.clientHeight) * ratio;
        el.scrollTo({ top: targetY, behavior: 'instant' });
      }
    }, { id: leftScrollId, ratio });

    // Wait for horizontal scroll sync
    await page.waitForTimeout(300);

    // Get scroll state
    const scrollState = await page.evaluate((id) => {
      const el = document.getElementById(id);
      const right = document.getElementById(id.replace('left', 'right'));
      return {
        scrollTop: Math.round(el?.scrollTop || 0),
        scrollLeft: Math.round(right?.scrollLeft || 0)
      };
    }, leftScrollId);

    // Check if bar is visible
    const barState = await isPurpleBarVisible();
    const status = barState.visible ? '✅ PASS' : '❌ FAIL';

    console.log(
      `${(ratio * 100).toFixed(0).padStart(6)}%  | ${String(scrollState.scrollTop).padStart(8)} | ${String(scrollState.scrollLeft).padStart(8)} | ${String(barState.visible).padStart(11)} | ${status}`
    );

    results.push({
      ratio,
      scrollTop: scrollState.scrollTop,
      scrollLeft: scrollState.scrollLeft,
      barVisible: barState.visible,
      details: barState
    });

    // Take screenshot
    await page.screenshot({
      path: path.join(IMAGES_DIR, `${timestamp}-hsync-${(ratio * 100).toFixed(0).padStart(3, '0')}.png`)
    });
  }

  // Overall result
  const passCount = results.filter(r => r.barVisible).length;
  const totalCount = results.length;
  const allPassed = passCount === totalCount;

  console.log('\n--- Summary ---');
  console.log(`Passed: ${passCount}/${totalCount} positions`);
  console.log(`Overall: ${allPassed ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'}`);

  // Save results to JSON
  fs.writeFileSync(
    path.join(BASE_DIR, 'horizontal-scroll-sync-results.json'),
    JSON.stringify({ timestamp, results, passed: allPassed }, null, 2)
  );

  // Close browser
  await context.close();
  await browser.close();

  console.log('\nScreenshots saved to:', IMAGES_DIR);
  console.log('Video saved to:', VIDEOS_DIR);

  process.exit(allPassed ? 0 : 1);
}

runTest().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
