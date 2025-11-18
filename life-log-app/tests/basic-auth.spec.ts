import { test, expect } from '@playwright/test'

test.describe('Life log dashboard', () => {
  test('renders timeline shell after auth', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByText('Monochrome Timeline Board')).toBeVisible()
    await expect(page.getByText('Integrations', { exact: true })).toBeVisible()
  })

  test('shows tooltip when hovering timeline bar', async ({ page }) => {
    await page.goto('/')
    const bar = page.locator('[data-testid="timeline-bar"]').last()
    await bar.hover({ timeout: 10000 })
    await expect(page.getByRole('tooltip')).toBeVisible({ timeout: 5000 })
  })
})
