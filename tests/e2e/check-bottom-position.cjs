/**
 * Check what happens at EXACT 100% scroll position
 */

const { chromium } = require('playwright');

const BASE_URL = process.env.BASE_URL || 'http://localhost:8787/';

async function runCheck() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    httpCredentials: { username: 'kazuph', password: 'lifelog' },
    viewport: { width: 1440, height: 900 }
  });
  const page = await context.newPage();
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

  // Scroll to EXACT bottom using scrollTo
  await page.evaluate((id) => {
    const el = document.getElementById(id);
    if (el) {
      el.scrollTo({ top: el.scrollHeight - el.clientHeight, behavior: 'instant' });
    }
  }, leftScrollId);
  await page.waitForTimeout(500);

  // Check the EXACT state at 100% scroll
  const state = await page.evaluate((id) => {
    const left = document.getElementById(id);
    if (!left) return { error: 'not found' };

    const leftRect = left.getBoundingClientRect();
    const entries = left.querySelectorAll('[data-entry-id]');
    const lastEntry = entries[entries.length - 1];
    const lastEntryRect = lastEntry.getBoundingClientRect();
    const titleEl = lastEntry.querySelector('.font-semibold');
    const titleRect = titleEl ? titleEl.getBoundingClientRect() : null;

    return {
      scrollTop: Math.round(left.scrollTop),
      scrollHeight: left.scrollHeight,
      clientHeight: left.clientHeight,
      maxScroll: left.scrollHeight - left.clientHeight,
      scrollPercent: Math.round((left.scrollTop / (left.scrollHeight - left.clientHeight)) * 100),
      containerTop: Math.round(leftRect.top),
      containerBottom: Math.round(leftRect.bottom),
      lastEntryTop: Math.round(lastEntryRect.top),
      lastEntryBottom: Math.round(lastEntryRect.bottom),
      lastEntryHeight: Math.round(lastEntryRect.height),
      titleTop: titleRect ? Math.round(titleRect.top) : null,
      titleBottom: titleRect ? Math.round(titleRect.bottom) : null,
      titleText: titleEl ? titleEl.textContent.trim() : null,
      // Key checks
      entryAboveContainer: lastEntryRect.top < leftRect.top,
      entryBelowContainer: lastEntryRect.bottom > leftRect.bottom,
      titleBelowContainer: titleRect ? titleRect.bottom > leftRect.bottom : null
    };
  }, leftScrollId);

  console.log('=== State at 100% scroll ===');
  console.log('Scroll position:', state.scrollTop, '/', state.maxScroll, '(' + state.scrollPercent + '%)');
  console.log('');
  console.log('Container bounds:', state.containerTop, '-', state.containerBottom);
  console.log('Last entry bounds:', state.lastEntryTop, '-', state.lastEntryBottom, '(height:', state.lastEntryHeight + 'px)');
  console.log('Title bounds:', state.titleTop, '-', state.titleBottom);
  console.log('Title text:', state.titleText);
  console.log('');
  console.log('Entry extends above container:', state.entryAboveContainer ? 'YES' : 'NO');
  console.log('Entry extends below container:', state.entryBelowContainer ? 'YES (cut off)' : 'NO');
  console.log('Title extends below container:', state.titleBelowContainer ? 'YES (title cut off!)' : 'NO');

  if (state.entryBelowContainer) {
    console.log('');
    console.log('CUT OFF AMOUNT:', state.lastEntryBottom - state.containerBottom, 'px');
  }

  await browser.close();
}

runCheck().catch(err => {
  console.error('Check failed:', err);
  process.exit(1);
});
