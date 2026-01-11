/**
 * Entry Visibility Diagnostic Tool
 *
 * Checks if entries are FULLY visible (not cut off).
 * An entry has: time + character count at TOP, title BELOW.
 * If only time/char count is visible but title is cut off, that's a FAILURE.
 *
 * Also checks if the purple gantt bar is fully visible (not cut off).
 */

const { chromium } = require('playwright');

const BASE_URL = process.env.BASE_URL || 'http://localhost:8788/';

async function runDiagnostics() {
  console.log('=== Entry & Bar Visibility Diagnostic Tool ===\n');
  console.log('Checking:\n  1. Entry titles fully visible (not cut off)');
  console.log('  2. Purple gantt bars fully visible (not cut off)\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    httpCredentials: { username: 'kazuph', password: 'lifelog' },
    viewport: { width: 1440, height: 900 }
  });
  const page = await context.newPage();

  console.log('Navigating to:', BASE_URL);
  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  // Get day group count
  const dayGroupCount = await page.evaluate(() => {
    let count = 0;
    while (document.getElementById(`left-scroll-${count}`)) count++;
    return count;
  });
  console.log(`Found ${dayGroupCount} day groups\n`);

  const issues = [];

  for (let dayIndex = 0; dayIndex < dayGroupCount; dayIndex++) {
    console.log(`\n=== Day Group ${dayIndex} ===`);

    const leftScrollId = `left-scroll-${dayIndex}`;
    const rightScrollId = `right-scroll-${dayIndex}`;

    // Scroll day into view
    await page.evaluate((idx) => {
      const el = document.getElementById(`left-scroll-${idx}`);
      if (el) {
        const card = el.parentElement?.parentElement?.parentElement;
        if (card) card.scrollIntoView({ behavior: 'instant', block: 'start' });
      }
    }, dayIndex);
    await page.waitForTimeout(300);

    // Get initial info
    const info = await page.evaluate(({ leftId, rightId }) => {
      const left = document.getElementById(leftId);
      const right = document.getElementById(rightId);
      if (!left || !right) return null;

      const entries = left.querySelectorAll('[data-entry-id]');
      const card = left.parentElement?.parentElement?.parentElement;
      const header = card?.querySelector('.text-lg');
      const dateText = header?.textContent?.trim() || 'Unknown';

      return {
        dateText,
        entryCount: entries.length,
        leftScrollHeight: left.scrollHeight,
        leftClientHeight: left.clientHeight,
        maxScroll: left.scrollHeight - left.clientHeight,
        rightScrollHeight: right.scrollHeight,
        rightClientHeight: right.clientHeight
      };
    }, { leftId: leftScrollId, rightId: rightScrollId });

    if (!info) {
      console.log('  ERROR: Could not get info');
      continue;
    }

    console.log(`  Date: ${info.dateText}`);
    console.log(`  Entries: ${info.entryCount}`);
    console.log(`  Max scroll: ${info.maxScroll}px`);

    if (info.maxScroll <= 0) {
      console.log('  No scroll needed');
      continue;
    }

    // Scroll to bottom
    await page.evaluate(({ leftId, rightId }) => {
      const left = document.getElementById(leftId);
      const right = document.getElementById(rightId);
      if (left) left.scrollTo({ top: left.scrollHeight, behavior: 'instant' });
      if (right) right.scrollTo({ top: right.scrollHeight, behavior: 'instant' });
    }, { leftId: leftScrollId, rightId: rightScrollId });
    await page.waitForTimeout(500);

    // Check visibility of LAST entry's components AND its gantt bar
    const visibility = await page.evaluate(({ leftId, rightId }) => {
      const left = document.getElementById(leftId);
      const right = document.getElementById(rightId);
      if (!left || !right) return { error: 'container not found' };

      const leftRect = left.getBoundingClientRect();
      const rightRect = right.getBoundingClientRect();
      const entries = left.querySelectorAll('[data-entry-id]');
      if (entries.length === 0) return { error: 'no entries' };

      const lastEntry = entries[entries.length - 1];
      const lastEntryRect = lastEntry.getBoundingClientRect();
      const entryId = lastEntry.getAttribute('data-entry-id');

      // Find the title element within the entry
      const titleEl = lastEntry.querySelector('.font-semibold');
      const timeEl = lastEntry.querySelector('.text-xs');

      // Find the corresponding gantt bar
      const ganttBar = right.querySelector(`[data-gantt-entry="${entryId}"]`);

      const result = {
        entryId,
        scrollTop: Math.round(left.scrollTop),
        maxScroll: Math.round(left.scrollHeight - left.clientHeight),

        // Left panel (entry list)
        leftContainerTop: Math.round(leftRect.top),
        leftContainerBottom: Math.round(leftRect.bottom),
        entryTop: Math.round(lastEntryRect.top),
        entryBottom: Math.round(lastEntryRect.bottom),
        entryFullyVisible: lastEntryRect.top >= leftRect.top - 2 &&
                           lastEntryRect.bottom <= leftRect.bottom + 2,
        entryCutOff: Math.round(Math.max(0, lastEntryRect.bottom - leftRect.bottom)),

        // Title check
        titleVisible: false,
        titleText: null,
        titleCutOff: 0,

        // Time check
        timeVisible: false,
        timeText: null,

        // Right panel (gantt bar)
        rightContainerTop: Math.round(rightRect.top),
        rightContainerBottom: Math.round(rightRect.bottom),
        barExists: !!ganttBar,
        barVisible: false,
        barCutOff: 0
      };

      if (titleEl) {
        const titleRect = titleEl.getBoundingClientRect();
        result.titleTop = Math.round(titleRect.top);
        result.titleBottom = Math.round(titleRect.bottom);
        result.titleText = titleEl.textContent.trim().slice(0, 40);
        result.titleVisible = titleRect.top >= leftRect.top - 2 &&
                              titleRect.bottom <= leftRect.bottom + 2;
        result.titleCutOff = Math.round(Math.max(0, titleRect.bottom - leftRect.bottom));
      }

      if (timeEl) {
        const timeRect = timeEl.getBoundingClientRect();
        result.timeText = timeEl.textContent.trim().slice(0, 30);
        result.timeVisible = timeRect.bottom <= leftRect.bottom + 2;
      }

      if (ganttBar) {
        const barRect = ganttBar.getBoundingClientRect();
        result.barTop = Math.round(barRect.top);
        result.barBottom = Math.round(barRect.bottom);
        result.barVisible = barRect.top >= rightRect.top - 2 &&
                           barRect.bottom <= rightRect.bottom + 2;
        result.barCutOff = Math.round(Math.max(0, barRect.bottom - rightRect.bottom));
      }

      return result;
    }, { leftId: leftScrollId, rightId: rightScrollId });

    if (visibility.error) {
      console.log(`  ERROR: ${visibility.error}`);
      continue;
    }

    console.log(`  Scroll: ${visibility.scrollTop}/${visibility.maxScroll}`);
    console.log(`  --- Left Panel (Entries) ---`);
    console.log(`  Container: ${visibility.leftContainerTop}-${visibility.leftContainerBottom}`);
    console.log(`  Last entry: ${visibility.entryTop}-${visibility.entryBottom}`);

    if (visibility.timeText) {
      console.log(`  Time: "${visibility.timeText}" (visible: ${visibility.timeVisible ? 'YES' : 'NO'})`);
    }

    if (visibility.titleText) {
      console.log(`  Title: "${visibility.titleText}"`);
      console.log(`    Fully visible: ${visibility.titleVisible ? 'YES' : 'NO'}`);
      if (!visibility.titleVisible) {
        console.log(`    Cut off by: ${visibility.titleCutOff}px`);
      }
    }

    console.log(`  --- Right Panel (Gantt Bar) ---`);
    console.log(`  Container: ${visibility.rightContainerTop}-${visibility.rightContainerBottom}`);

    if (visibility.barExists) {
      console.log(`  Bar: ${visibility.barTop}-${visibility.barBottom}`);
      console.log(`  Bar fully visible: ${visibility.barVisible ? 'YES' : 'NO'}`);
      if (!visibility.barVisible) {
        console.log(`    Cut off by: ${visibility.barCutOff}px`);
      }
    } else {
      console.log(`  Bar: NOT FOUND for entry ${visibility.entryId}`);
    }

    // Record issues
    let hasIssue = false;

    if (!visibility.titleVisible && visibility.titleText) {
      console.log(`  ❌ TITLE CUT OFF!`);
      issues.push({
        day: dayIndex,
        date: info.dateText,
        type: 'title_cut_off',
        detail: `Title "${visibility.titleText}" cut off by ${visibility.titleCutOff}px`
      });
      hasIssue = true;
    }

    if (visibility.barExists && !visibility.barVisible) {
      console.log(`  ❌ GANTT BAR CUT OFF!`);
      issues.push({
        day: dayIndex,
        date: info.dateText,
        type: 'bar_cut_off',
        detail: `Bar cut off by ${visibility.barCutOff}px`
      });
      hasIssue = true;
    }

    if (!hasIssue) {
      console.log(`  ✅ ALL VISIBLE`);
    }
  }

  await browser.close();

  // Summary
  console.log('\n\n========== SUMMARY ==========\n');

  if (issues.length > 0) {
    console.log('❌ ISSUES FOUND:\n');
    for (const issue of issues) {
      console.log(`  Day ${issue.day} (${issue.date}) - ${issue.type}:`);
      console.log(`    ${issue.detail}`);
    }
    console.log(`\nTotal issues: ${issues.length}`);
    console.log('\nThis proves the scroll implementation is broken!');
  } else {
    console.log('✅ All entries and bars are fully visible');
  }

  process.exit(issues.length > 0 ? 1 : 0);
}

runDiagnostics().catch(err => {
  console.error('Diagnostic failed:', err);
  process.exit(1);
});
