/**
 * Scroll Diagnostic Tool
 *
 * Programmatically verifies:
 * 1. Can each day group scroll to the absolute bottom?
 * 2. Does horizontal scroll actually trigger when vertical scrolling?
 * 3. Is the purple bar visible in the viewport at each scroll position?
 */

const { chromium } = require('playwright');

const BASE_URL = process.env.BASE_URL || 'http://localhost:8788/';

async function runDiagnostics() {
  console.log('=== Scroll Diagnostic Tool ===\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    httpCredentials: { username: 'kazuph', password: 'lifelog' },
    viewport: { width: 1440, height: 900 }
  });
  const page = await context.newPage();

  console.log('Navigating to:', BASE_URL);
  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  // Get all day groups
  const dayGroupCount = await page.evaluate(() => {
    let count = 0;
    while (document.getElementById(`left-scroll-${count}`)) count++;
    return count;
  });
  console.log(`Found ${dayGroupCount} day groups\n`);

  const issues = [];
  const results = [];

  for (let i = 0; i < dayGroupCount; i++) {
    const leftScrollId = `left-scroll-${i}`;
    const rightScrollId = `right-scroll-${i}`;

    console.log(`\n--- Day Group ${i} ---`);

    // Scroll the day group into view
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

      // Get date from header
      const card = left.parentElement?.parentElement?.parentElement;
      const header = card?.querySelector('h2, h3, .text-lg');
      const dateText = header?.textContent?.trim() || `Day ${leftId}`;

      // Get entry count
      const entries = left.querySelectorAll('[data-entry-id]');

      return {
        dateText,
        entryCount: entries.length,
        left: {
          scrollHeight: left.scrollHeight,
          clientHeight: left.clientHeight,
          scrollTop: left.scrollTop,
          maxScrollTop: left.scrollHeight - left.clientHeight
        },
        right: {
          scrollWidth: right.scrollWidth,
          clientWidth: right.clientWidth,
          scrollLeft: right.scrollLeft
        }
      };
    }, { leftId: leftScrollId, rightId: rightScrollId });

    if (!initialState) {
      console.log('  ERROR: Could not get initial state');
      issues.push({ dayGroup: i, issue: 'Could not get initial state' });
      continue;
    }

    console.log(`  Date: ${initialState.dateText}`);
    console.log(`  Entries: ${initialState.entryCount}`);
    console.log(`  Left panel: scrollHeight=${initialState.left.scrollHeight}, clientHeight=${initialState.left.clientHeight}`);
    console.log(`  Max scroll: ${initialState.left.maxScrollTop}px`);
    console.log(`  Right panel: scrollWidth=${initialState.right.scrollWidth}, scrollLeft=${initialState.right.scrollLeft}`);

    // Check if scrollable
    const canScroll = initialState.left.scrollHeight > initialState.left.clientHeight;
    if (!canScroll) {
      console.log('  Status: No scroll needed (content fits)');
      results.push({
        dayGroup: i,
        date: initialState.dateText,
        canScroll: false,
        scrolledToBottom: true,
        horizontalScrollChanged: 'N/A',
        purpleBarVisible: 'N/A'
      });
      continue;
    }

    // Reset to top
    await page.evaluate((id) => {
      const el = document.getElementById(id);
      if (el) el.scrollTo({ top: 0, behavior: 'instant' });
    }, leftScrollId);
    await page.waitForTimeout(200);

    // Record initial horizontal scroll
    const initialHScroll = await page.evaluate((id) => {
      const el = document.getElementById(id);
      return el ? el.scrollLeft : -1;
    }, rightScrollId);

    // Scroll to absolute bottom
    await page.evaluate((id) => {
      const el = document.getElementById(id);
      if (el) {
        el.scrollTo({ top: el.scrollHeight, behavior: 'instant' });
      }
    }, leftScrollId);
    await page.waitForTimeout(500); // Wait for horizontal scroll sync

    // Check if we reached the bottom
    const afterScrollState = await page.evaluate(({ leftId, rightId }) => {
      const left = document.getElementById(leftId);
      const right = document.getElementById(rightId);
      if (!left || !right) return null;

      const maxScrollTop = left.scrollHeight - left.clientHeight;
      const actualScrollTop = left.scrollTop;
      const reachedBottom = Math.abs(actualScrollTop - maxScrollTop) < 2;

      return {
        scrollTop: actualScrollTop,
        maxScrollTop,
        reachedBottom,
        scrollLeft: right.scrollLeft
      };
    }, { leftId: leftScrollId, rightId: rightScrollId });

    if (!afterScrollState) {
      console.log('  ERROR: Could not get after-scroll state');
      issues.push({ dayGroup: i, issue: 'Could not get after-scroll state' });
      continue;
    }

    console.log(`  After scroll: scrollTop=${afterScrollState.scrollTop}/${afterScrollState.maxScrollTop}`);
    console.log(`  Reached bottom: ${afterScrollState.reachedBottom ? 'YES' : 'NO'}`);

    if (!afterScrollState.reachedBottom) {
      issues.push({
        dayGroup: i,
        date: initialState.dateText,
        issue: `Cannot scroll to bottom. Current: ${afterScrollState.scrollTop}, Max: ${afterScrollState.maxScrollTop}`
      });
    }

    // Check if horizontal scroll changed
    const horizontalScrollChanged = afterScrollState.scrollLeft !== initialHScroll;
    console.log(`  Horizontal scroll: ${initialHScroll} -> ${afterScrollState.scrollLeft} (changed: ${horizontalScrollChanged ? 'YES' : 'NO'})`);

    if (!horizontalScrollChanged && initialState.entryCount > 3) {
      issues.push({
        dayGroup: i,
        date: initialState.dateText,
        issue: `Horizontal scroll did not change. Before: ${initialHScroll}, After: ${afterScrollState.scrollLeft}`
      });
    }

    // Check if purple bar is visible at bottom scroll position
    const barVisibility = await page.evaluate(({ leftId, rightId }) => {
      const left = document.getElementById(leftId);
      const right = document.getElementById(rightId);
      if (!left || !right) return { visible: false, reason: 'elements not found' };

      // Find the center-most visible entry
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

      if (!centerEntry) return { visible: false, reason: 'no visible entry found' };

      const entryId = centerEntry.getAttribute('data-entry-id');
      const bar = right.querySelector(`[data-gantt-entry="${entryId}"]`);
      if (!bar) return { visible: false, reason: `no bar found for entry ${entryId}` };

      // Check if bar is in viewport
      const rightRect = right.getBoundingClientRect();
      const barRect = bar.getBoundingClientRect();

      const barInViewport = barRect.right > rightRect.left && barRect.left < rightRect.right;

      return {
        visible: barInViewport,
        entryId,
        barLeft: Math.round(barRect.left - rightRect.left),
        barRight: Math.round(barRect.right - rightRect.left),
        viewportWidth: Math.round(rightRect.width),
        scrollLeft: Math.round(right.scrollLeft)
      };
    }, { leftId: leftScrollId, rightId: rightScrollId });

    console.log(`  Purple bar visible: ${barVisibility.visible ? 'YES' : 'NO'}`);
    if (!barVisibility.visible) {
      console.log(`    Reason: ${barVisibility.reason || 'bar outside viewport'}`);
      if (barVisibility.barLeft !== undefined) {
        console.log(`    Bar position: ${barVisibility.barLeft} to ${barVisibility.barRight} (viewport: 0-${barVisibility.viewportWidth})`);
      }
      issues.push({
        dayGroup: i,
        date: initialState.dateText,
        issue: `Purple bar not visible at bottom. ${barVisibility.reason || ''}`
      });
    }

    results.push({
      dayGroup: i,
      date: initialState.dateText,
      canScroll: true,
      scrolledToBottom: afterScrollState.reachedBottom,
      horizontalScrollChanged,
      purpleBarVisible: barVisibility.visible,
      details: {
        maxScrollTop: afterScrollState.maxScrollTop,
        actualScrollTop: afterScrollState.scrollTop,
        initialHScroll,
        finalHScroll: afterScrollState.scrollLeft,
        barVisibility
      }
    });
  }

  await browser.close();

  // Summary
  console.log('\n\n========== DIAGNOSTIC SUMMARY ==========\n');

  console.log('Results by Day Group:');
  console.log('Day | Date       | Scroll | H-Scroll | Bar Visible');
  console.log('----|------------|--------|----------|------------');

  for (const r of results) {
    const scrollStatus = r.canScroll ? (r.scrolledToBottom ? '✅' : '❌') : 'N/A';
    const hScrollStatus = r.horizontalScrollChanged === 'N/A' ? 'N/A' : (r.horizontalScrollChanged ? '✅' : '❌');
    const barStatus = r.purpleBarVisible === 'N/A' ? 'N/A' : (r.purpleBarVisible ? '✅' : '❌');
    console.log(`${String(r.dayGroup).padStart(3)} | ${r.date.padEnd(10).slice(0, 10)} | ${scrollStatus.padEnd(6)} | ${hScrollStatus.padEnd(8)} | ${barStatus}`);
  }

  if (issues.length > 0) {
    console.log('\n\n========== ISSUES FOUND ==========\n');
    for (const issue of issues) {
      console.log(`❌ Day ${issue.dayGroup} (${issue.date || 'unknown'}): ${issue.issue}`);
    }
    console.log(`\nTotal issues: ${issues.length}`);
  } else {
    console.log('\n✅ No issues found!');
  }

  // Return exit code
  process.exit(issues.length > 0 ? 1 : 0);
}

runDiagnostics().catch(err => {
  console.error('Diagnostic failed:', err);
  process.exit(1);
});
