const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    httpCredentials: { username: 'kazuph', password: 'lifelog' },
    viewport: { width: 1440, height: 900 }
  });
  const page = await context.newPage();
  await page.goto('http://localhost:8787/', { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  // Analyze Day 1
  const dayIndex = 1;

  const analysis = await page.evaluate((idx) => {
    const leftId = 'left-scroll-' + idx;
    const rightId = 'right-scroll-' + idx;
    const left = document.getElementById(leftId);
    const right = document.getElementById(rightId);

    if (!left || !right) return { error: 'not found' };

    const entries = left.querySelectorAll('[data-entry-id]');

    // Measure actual entry heights
    const entryHeights = [];
    entries.forEach((entry, i) => {
      const rect = entry.getBoundingClientRect();
      entryHeights.push({
        index: i,
        height: Math.round(rect.height),
        top: Math.round(rect.top),
        bottom: Math.round(rect.bottom)
      });
    });

    // Get wrapper padding
    const wrapper = left.querySelector('div');
    const wrapperStyles = wrapper ? getComputedStyle(wrapper) : null;

    const leftRect = left.getBoundingClientRect();

    return {
      leftScrollHeight: left.scrollHeight,
      leftClientHeight: left.clientHeight,
      maxScroll: left.scrollHeight - left.clientHeight,
      rightScrollHeight: right.scrollHeight,
      rightClientHeight: right.clientHeight,
      rightMaxScroll: right.scrollHeight - right.clientHeight,
      containerTop: Math.round(leftRect.top),
      containerBottom: Math.round(leftRect.bottom),
      containerHeight: Math.round(leftRect.height),
      entryCount: entries.length,
      entryHeights,
      totalEntryHeight: entryHeights.reduce((sum, e) => sum + e.height, 0),
      wrapperPaddingTop: wrapperStyles ? wrapperStyles.paddingTop : null,
      wrapperPaddingBottom: wrapperStyles ? wrapperStyles.paddingBottom : null
    };
  }, dayIndex);

  console.log('=== Day Group 1 Analysis ===');
  console.log('Left scroll container:');
  console.log('  scrollHeight:', analysis.leftScrollHeight);
  console.log('  clientHeight:', analysis.leftClientHeight);
  console.log('  maxScroll:', analysis.maxScroll);
  console.log('');
  console.log('Right scroll container:');
  console.log('  scrollHeight:', analysis.rightScrollHeight);
  console.log('  clientHeight:', analysis.rightClientHeight);
  console.log('  maxScroll:', analysis.rightMaxScroll);
  console.log('');
  console.log('Entry count:', analysis.entryCount);
  console.log('Entry heights:');
  analysis.entryHeights.forEach(e => {
    console.log('  Entry', e.index + ':', e.height + 'px');
  });
  console.log('Total entry height:', analysis.totalEntryHeight);
  console.log('Wrapper padding:', analysis.wrapperPaddingTop, '/', analysis.wrapperPaddingBottom);
  console.log('');
  console.log('Expected scrollHeight = totalEntryHeight + padding');
  console.log('Actual scrollHeight:', analysis.leftScrollHeight);
  console.log('Difference:', analysis.leftScrollHeight - analysis.totalEntryHeight);

  await browser.close();
})();
