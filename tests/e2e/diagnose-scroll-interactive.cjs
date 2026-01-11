/**
 * Interactive Scroll Diagnostic Tool
 *
 * Runs in headed mode with mouse wheel simulation to match real user behavior.
 * Also injects console logging into the page to monitor scroll events.
 */

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const FEATURE = 'fix-timeline-display';
const BASE_DIR = path.join(process.cwd(), '.artifacts', FEATURE);
const IMAGES_DIR = path.join(BASE_DIR, 'images');
const BASE_URL = process.env.BASE_URL || 'http://localhost:8788/';

async function runDiagnostics() {
  fs.mkdirSync(IMAGES_DIR, { recursive: true });

  console.log('=== Interactive Scroll Diagnostic Tool ===\n');

  const browser = await chromium.launch({ headless: false, slowMo: 100 });
  const context = await browser.newContext({
    httpCredentials: { username: 'kazuph', password: 'lifelog' },
    viewport: { width: 1440, height: 900 }
  });
  const page = await context.newPage();

  // Capture console logs from the page
  const pageLogs = [];
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('[SCROLL]')) {
      pageLogs.push(text);
      console.log('  PAGE:', text);
    }
  });

  console.log('Navigating to:', BASE_URL);
  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  // Inject scroll monitoring
  await page.evaluate(() => {
    // Monitor all scroll containers
    for (let i = 0; i < 10; i++) {
      const leftId = `left-scroll-${i}`;
      const rightId = `right-scroll-${i}`;
      const left = document.getElementById(leftId);
      const right = document.getElementById(rightId);

      if (!left || !right) continue;

      let lastLeftScroll = left.scrollTop;
      let lastRightScroll = right.scrollLeft;

      left.addEventListener('scroll', () => {
        const newLeft = left.scrollTop;
        const newRight = right.scrollLeft;
        if (newLeft !== lastLeftScroll) {
          console.log(`[SCROLL] Day${i} LEFT: ${lastLeftScroll} -> ${newLeft} (H: ${lastRightScroll} -> ${newRight})`);
          lastLeftScroll = newLeft;
          lastRightScroll = newRight;
        }
      });

      right.addEventListener('scroll', () => {
        const newRight = right.scrollLeft;
        if (newRight !== lastRightScroll) {
          console.log(`[SCROLL] Day${i} RIGHT H-scroll: ${lastRightScroll} -> ${newRight}`);
          lastRightScroll = newRight;
        }
      });
    }
    console.log('[SCROLL] Monitoring initialized');
  });

  await page.waitForTimeout(500);

  // Get day group count
  const dayGroupCount = await page.evaluate(() => {
    let count = 0;
    while (document.getElementById(`left-scroll-${count}`)) count++;
    return count;
  });
  console.log(`Found ${dayGroupCount} day groups\n`);

  const timestamp = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const issues = [];

  // Test each day group with realistic mouse wheel scrolling
  for (let i = 0; i < dayGroupCount; i++) {
    console.log(`\n=== Testing Day Group ${i} ===`);

    const leftScrollId = `left-scroll-${i}`;
    const rightScrollId = `right-scroll-${i}`;

    // Scroll day group into view
    await page.evaluate((idx) => {
      const el = document.getElementById(`left-scroll-${idx}`);
      if (el) {
        const card = el.parentElement?.parentElement?.parentElement;
        if (card) card.scrollIntoView({ behavior: 'instant', block: 'start' });
      }
    }, i);
    await page.waitForTimeout(300);

    // Get initial state
    const initialState = await page.evaluate(({ leftId, rightId }) => {
      const left = document.getElementById(leftId);
      const right = document.getElementById(rightId);
      if (!left || !right) return null;

      const card = left.parentElement?.parentElement?.parentElement;
      const header = card?.querySelector('.text-lg');
      const dateText = header?.textContent?.trim() || `Day ${leftId}`;

      return {
        dateText,
        entryCount: left.querySelectorAll('[data-entry-id]').length,
        scrollHeight: left.scrollHeight,
        clientHeight: left.clientHeight,
        maxScrollTop: left.scrollHeight - left.clientHeight,
        initialScrollLeft: right.scrollLeft
      };
    }, { leftId: leftScrollId, rightId: rightScrollId });

    if (!initialState) {
      issues.push({ day: i, issue: 'Could not get state' });
      continue;
    }

    console.log(`  Date: ${initialState.dateText}`);
    console.log(`  Entries: ${initialState.entryCount}`);
    console.log(`  Max scroll: ${initialState.maxScrollTop}px`);
    console.log(`  Initial H-scroll: ${initialState.initialScrollLeft}`);

    if (initialState.maxScrollTop <= 0) {
      console.log('  No scroll needed');
      continue;
    }

    // Reset to top
    await page.evaluate((id) => {
      const el = document.getElementById(id);
      if (el) el.scrollTo({ top: 0, behavior: 'instant' });
    }, leftScrollId);
    await page.waitForTimeout(300);

    // Take screenshot at top
    await page.screenshot({
      path: path.join(IMAGES_DIR, `${timestamp}-day${i}-top.png`)
    });

    // Get element bounding box for mouse wheel
    const leftBox = await page.evaluate((id) => {
      const el = document.getElementById(id);
      if (!el) return null;
      const rect = el.getBoundingClientRect();
      return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 };
    }, leftScrollId);

    if (!leftBox) {
      issues.push({ day: i, issue: 'Could not get element position' });
      continue;
    }

    // Move mouse to the scroll container
    await page.mouse.move(leftBox.x, leftBox.y);
    await page.waitForTimeout(100);

    // Scroll down using mouse wheel (realistic user behavior)
    const scrollSteps = 20;
    const deltaY = initialState.maxScrollTop / scrollSteps;

    console.log(`  Scrolling with mouse wheel (${scrollSteps} steps, delta=${Math.round(deltaY)})`);

    for (let step = 0; step < scrollSteps; step++) {
      await page.mouse.wheel(0, deltaY);
      await page.waitForTimeout(50);
    }

    await page.waitForTimeout(500);

    // Get final state
    const finalState = await page.evaluate(({ leftId, rightId }) => {
      const left = document.getElementById(leftId);
      const right = document.getElementById(rightId);
      if (!left || !right) return null;

      const maxScroll = left.scrollHeight - left.clientHeight;
      const currentScroll = left.scrollTop;
      const reachedBottom = currentScroll >= maxScroll - 5;

      // Check purple bar visibility
      const containerRect = left.getBoundingClientRect();
      const containerCenter = containerRect.top + containerRect.height / 2;
      let centerEntry = null;
      let minDist = Infinity;

      left.querySelectorAll('[data-entry-id]').forEach(entry => {
        const rect = entry.getBoundingClientRect();
        if (rect.bottom > containerRect.top && rect.top < containerRect.bottom) {
          const entryCenter = rect.top + rect.height / 2;
          const dist = Math.abs(entryCenter - containerCenter);
          if (dist < minDist) {
            minDist = dist;
            centerEntry = entry;
          }
        }
      });

      let barVisible = false;
      let barInfo = null;

      if (centerEntry) {
        const entryId = centerEntry.getAttribute('data-entry-id');
        const bar = right.querySelector(`[data-gantt-entry="${entryId}"]`);
        if (bar) {
          const rightRect = right.getBoundingClientRect();
          const barRect = bar.getBoundingClientRect();
          barVisible = barRect.right > rightRect.left && barRect.left < rightRect.right;
          barInfo = {
            entryId,
            barLeft: Math.round(barRect.left - rightRect.left + right.scrollLeft),
            barRight: Math.round(barRect.right - rightRect.left + right.scrollLeft),
            viewportLeft: Math.round(right.scrollLeft),
            viewportRight: Math.round(right.scrollLeft + rightRect.width)
          };
        }
      }

      return {
        scrollTop: currentScroll,
        maxScrollTop: maxScroll,
        reachedBottom,
        scrollLeft: right.scrollLeft,
        barVisible,
        barInfo
      };
    }, { leftId: leftScrollId, rightId: rightScrollId });

    if (!finalState) {
      issues.push({ day: i, issue: 'Could not get final state' });
      continue;
    }

    console.log(`  Final scroll: ${finalState.scrollTop}/${finalState.maxScrollTop}`);
    console.log(`  Reached bottom: ${finalState.reachedBottom ? 'YES' : 'NO'}`);
    console.log(`  H-scroll: ${initialState.initialScrollLeft} -> ${finalState.scrollLeft} (changed: ${initialState.initialScrollLeft !== finalState.scrollLeft ? 'YES' : 'NO'})`);
    console.log(`  Purple bar visible: ${finalState.barVisible ? 'YES' : 'NO'}`);

    if (finalState.barInfo) {
      console.log(`    Bar: ${finalState.barInfo.barLeft}-${finalState.barInfo.barRight}, Viewport: ${finalState.barInfo.viewportLeft}-${finalState.barInfo.viewportRight}`);
    }

    // Take screenshot at bottom
    await page.screenshot({
      path: path.join(IMAGES_DIR, `${timestamp}-day${i}-bottom.png`)
    });

    // Record issues
    if (!finalState.reachedBottom) {
      issues.push({
        day: i,
        date: initialState.dateText,
        issue: `Cannot reach bottom: ${finalState.scrollTop}/${finalState.maxScrollTop}`
      });
    }

    if (initialState.initialScrollLeft === finalState.scrollLeft && initialState.entryCount > 3) {
      issues.push({
        day: i,
        date: initialState.dateText,
        issue: `Horizontal scroll did not change: ${initialState.initialScrollLeft} -> ${finalState.scrollLeft}`
      });
    }

    if (!finalState.barVisible) {
      issues.push({
        day: i,
        date: initialState.dateText,
        issue: `Purple bar not visible`,
        barInfo: finalState.barInfo
      });
    }
  }

  // Summary
  console.log('\n\n========== SUMMARY ==========\n');

  if (issues.length > 0) {
    console.log('❌ ISSUES FOUND:\n');
    for (const issue of issues) {
      console.log(`  Day ${issue.day}${issue.date ? ` (${issue.date})` : ''}: ${issue.issue}`);
      if (issue.barInfo) {
        console.log(`    Bar position: ${issue.barInfo.barLeft}-${issue.barInfo.barRight}`);
        console.log(`    Viewport: ${issue.barInfo.viewportLeft}-${issue.barInfo.viewportRight}`);
      }
    }
    console.log(`\nTotal issues: ${issues.length}`);
  } else {
    console.log('✅ No issues found!');
  }

  console.log('\nPage scroll logs:');
  pageLogs.forEach(log => console.log(`  ${log}`));

  await page.waitForTimeout(2000);
  await browser.close();

  process.exit(issues.length > 0 ? 1 : 0);
}

runDiagnostics().catch(err => {
  console.error('Diagnostic failed:', err);
  process.exit(1);
});
