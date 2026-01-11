/**
 * Stepwise Scroll Diagnostic Tool
 *
 * Scrolls step by step using mouse wheel simulation and checks
 * at EVERY position if entries and bars are cut off.
 *
 * This simulates real user scrolling behavior.
 */

const { chromium } = require('playwright');

const BASE_URL = process.env.BASE_URL || 'http://localhost:8788/';

async function runDiagnostics() {
  console.log('=== Stepwise Scroll Diagnostic Tool ===\n');
  console.log('Scrolling step-by-step with mouse wheel to detect cut-off issues\n');

  const browser = await chromium.launch({ headless: false, slowMo: 30 });
  const context = await browser.newContext({
    httpCredentials: { username: 'kazuph', password: 'lifelog' },
    viewport: { width: 1440, height: 900 }
  });
  const page = await context.newPage();

  console.log('Navigating to:', BASE_URL);
  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  // Test Day 1 (the one user reported issues with)
  const dayIndex = 1;
  const leftScrollId = `left-scroll-${dayIndex}`;
  const rightScrollId = `right-scroll-${dayIndex}`;

  console.log(`\n=== Testing Day Group ${dayIndex} ===`);

  // Scroll day into view
  await page.evaluate((idx) => {
    const el = document.getElementById(`left-scroll-${idx}`);
    if (el) {
      const card = el.parentElement?.parentElement?.parentElement;
      if (card) card.scrollIntoView({ behavior: 'instant', block: 'start' });
    }
  }, dayIndex);
  await page.waitForTimeout(500);

  // Get info
  const info = await page.evaluate(({ leftId }) => {
    const left = document.getElementById(leftId);
    if (!left) return null;
    const entries = left.querySelectorAll('[data-entry-id]');
    return {
      entryCount: entries.length,
      maxScroll: left.scrollHeight - left.clientHeight,
      clientHeight: left.clientHeight
    };
  }, { leftId: leftScrollId });

  if (!info) {
    console.log('ERROR: Could not get info');
    await browser.close();
    process.exit(1);
  }

  console.log(`  Entries: ${info.entryCount}`);
  console.log(`  Max scroll: ${info.maxScroll}px`);
  console.log(`  Container height: ${info.clientHeight}px`);

  // Reset to top
  await page.evaluate((id) => {
    const el = document.getElementById(id);
    if (el) el.scrollTo({ top: 0, behavior: 'instant' });
  }, leftScrollId);
  await page.waitForTimeout(300);

  // Get scroll container position for mouse wheel
  const leftBox = await page.evaluate((id) => {
    const el = document.getElementById(id);
    if (!el) return null;
    const rect = el.getBoundingClientRect();
    return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 };
  }, leftScrollId);

  // Move mouse to container
  await page.mouse.move(leftBox.x, leftBox.y);
  await page.waitForTimeout(200);

  const issues = [];
  const deltaPerStep = 100; // Scroll 100px per step
  const totalSteps = Math.ceil(info.maxScroll / deltaPerStep) + 5;

  console.log(`\n  Scrolling ${totalSteps} steps (${deltaPerStep}px each)...`);
  console.log('  Checking for cut-off entries at each step...\n');

  for (let step = 0; step < totalSteps; step++) {
    // Scroll with mouse wheel
    await page.mouse.wheel(0, deltaPerStep);
    await page.waitForTimeout(100);

    // Check visibility at current position
    const state = await page.evaluate(({ leftId, rightId }) => {
      const left = document.getElementById(leftId);
      const right = document.getElementById(rightId);
      if (!left || !right) return null;

      const leftRect = left.getBoundingClientRect();
      const rightRect = right.getBoundingClientRect();

      // Get ALL visible entries (not just the last one)
      const entries = left.querySelectorAll('[data-entry-id]');
      const visibleEntries = [];

      entries.forEach((entry, idx) => {
        const entryRect = entry.getBoundingClientRect();
        // Check if entry is at least partially visible
        if (entryRect.bottom > leftRect.top && entryRect.top < leftRect.bottom) {
          const titleEl = entry.querySelector('.font-semibold');
          const timeEl = entry.querySelector('.text-xs');

          let titleCutOff = 0;
          let timeVisible = true;
          let titleVisible = true;

          if (titleEl) {
            const titleRect = titleEl.getBoundingClientRect();
            if (titleRect.bottom > leftRect.bottom) {
              titleCutOff = Math.round(titleRect.bottom - leftRect.bottom);
              titleVisible = false;
            }
            if (titleRect.top < leftRect.top) {
              titleVisible = false;
            }
          }

          if (timeEl) {
            const timeRect = timeEl.getBoundingClientRect();
            timeVisible = timeRect.bottom <= leftRect.bottom + 2 && timeRect.top >= leftRect.top - 2;
          }

          // Only report if time is visible but title is cut off (the bug user described)
          if (timeVisible && !titleVisible && titleCutOff > 0) {
            visibleEntries.push({
              index: idx,
              entryId: entry.getAttribute('data-entry-id'),
              titleText: titleEl ? titleEl.textContent.trim().slice(0, 30) : 'N/A',
              titleCutOff,
              issue: 'TIME_VISIBLE_TITLE_CUT'
            });
          }
        }
      });

      // Also check gantt bars
      const barIssues = [];
      entries.forEach((entry) => {
        const entryId = entry.getAttribute('data-entry-id');
        const bar = right.querySelector(`[data-gantt-entry="${entryId}"]`);
        if (bar) {
          const barRect = bar.getBoundingClientRect();
          if (barRect.bottom > rightRect.top && barRect.top < rightRect.bottom) {
            // Bar is at least partially visible
            if (barRect.bottom > rightRect.bottom) {
              barIssues.push({
                entryId,
                barCutOff: Math.round(barRect.bottom - rightRect.bottom)
              });
            }
          }
        }
      });

      return {
        scrollTop: Math.round(left.scrollTop),
        maxScroll: Math.round(left.scrollHeight - left.clientHeight),
        entryIssues: visibleEntries,
        barIssues
      };
    }, { leftId: leftScrollId, rightId: rightScrollId });

    if (!state) continue;

    const percent = Math.round((state.scrollTop / state.maxScroll) * 100);

    // Report any issues found at this step
    if (state.entryIssues.length > 0) {
      for (const issue of state.entryIssues) {
        console.log(`  Step ${step} (${percent}%): ❌ ENTRY CUT OFF!`);
        console.log(`    Entry: "${issue.titleText}"`);
        console.log(`    Issue: Time visible, but title cut off by ${issue.titleCutOff}px`);
        issues.push({
          step,
          scrollTop: state.scrollTop,
          percent,
          type: 'entry_title_cut_off',
          detail: issue
        });
      }
    }

    if (state.barIssues.length > 0) {
      for (const issue of state.barIssues) {
        console.log(`  Step ${step} (${percent}%): ❌ BAR CUT OFF!`);
        console.log(`    Entry ID: ${issue.entryId}`);
        console.log(`    Bar cut off by ${issue.barCutOff}px`);
        issues.push({
          step,
          scrollTop: state.scrollTop,
          percent,
          type: 'bar_cut_off',
          detail: issue
        });
      }
    }
  }

  await browser.close();

  // Summary
  console.log('\n\n========== SUMMARY ==========\n');

  if (issues.length > 0) {
    console.log(`❌ FOUND ${issues.length} ISSUES during stepwise scroll!\n`);

    // Group by type
    const entryIssues = issues.filter(i => i.type === 'entry_title_cut_off');
    const barIssues = issues.filter(i => i.type === 'bar_cut_off');

    if (entryIssues.length > 0) {
      console.log('Entry title cut-off issues:');
      for (const issue of entryIssues) {
        console.log(`  At ${issue.percent}%: "${issue.detail.titleText}" (${issue.detail.titleCutOff}px cut)`);
      }
    }

    if (barIssues.length > 0) {
      console.log('\nBar cut-off issues:');
      for (const issue of barIssues) {
        console.log(`  At ${issue.percent}%: Entry ${issue.detail.entryId} (${issue.detail.barCutOff}px cut)`);
      }
    }

    console.log('\n>>> SCROLL IMPLEMENTATION IS BROKEN! <<<');
  } else {
    console.log('✅ No cut-off issues found during stepwise scroll');
  }

  process.exit(issues.length > 0 ? 1 : 0);
}

runDiagnostics().catch(err => {
  console.error('Diagnostic failed:', err);
  process.exit(1);
});
