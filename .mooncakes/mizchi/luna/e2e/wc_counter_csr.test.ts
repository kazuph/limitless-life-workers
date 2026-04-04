import { test, expect } from '@playwright/test';

const DEBUG = process.env.DEBUG === '1';

test.describe('wc-counter CSR navigation', () => {
  test('wc-counter should work after CSR navigation', async ({ page }) => {
    // ホームページから開始（baseURLを使用）
    await page.goto('/');

    // コンソールログを収集
    const logs: string[] = [];
    page.on('console', msg => {
      logs.push(`[${msg.type()}] ${msg.text()}`);
    });

    // ページが読み込まれたことを確認
    await expect(page.locator('nav')).toBeVisible();

    // WC Counterリンクをクリック（CSR遷移）
    await page.click('a[href="/wc-counter"]');

    // 少し待つ
    await page.waitForTimeout(500);

    // URLが変わったことを確認
    expect(page.url()).toContain('/wc-counter');

    // wc-counter要素が表示されるか確認
    const wcCounter = page.locator('wc-counter');
    await expect(wcCounter).toBeVisible({ timeout: 5000 });

    // Shadow DOM内のコンテンツを確認
    const countDisplay = wcCounter.locator('.count-display');

    // カウント表示が0であることを確認
    await expect(countDisplay).toHaveText('0');

    // インクリメントボタンをクリック
    const incButton = wcCounter.locator('.inc');
    await incButton.click();

    // カウントが1になることを確認
    await expect(countDisplay).toHaveText('1');

    if (DEBUG) {
      console.log('Console logs:', logs);
      const isHydrated = logs.some(log => log.includes('[wc-counter] Hydrated'));
      console.log('Is hydrated:', isHydrated);
    }
  });
});
