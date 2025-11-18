import { defineConfig } from '@playwright/test'
import { existsSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'

const loadDevVars = () => {
  const devVarsPath = resolve(process.cwd(), '.dev.vars')
  if (!existsSync(devVarsPath)) {
    return {}
  }
  try {
    const raw = readFileSync(devVarsPath, 'utf8')
    return raw
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#'))
      .reduce<Record<string, string>>((acc, line) => {
        const [key, ...rest] = line.split('=')
        if (key) {
          acc[key] = rest.join('=')
        }
        return acc
      }, {})
  } catch {
    return {}
  }
}

const devVars = loadDevVars()
const envValue = (key: string, fallback = '') => {
  const value = process.env[key] ?? devVars[key]
  if (value && value.length > 0) {
    return value
  }
  return fallback
}

const PORT = Number(process.env.VITE_PORT ?? 5199)

const basicUser = envValue('BASIC_USER')
const basicPass = envValue('BASIC_PASS')
const limitlessKey = envValue('LIMITLESS_API_KEY')

if (!basicUser || !basicPass) {
  console.warn('Playwright: BASIC_USER or BASIC_PASS missing; Basic auth tests may fail.')
}

export default defineConfig({
  testDir: './tests',
  timeout: 60_000,
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  use: {
    baseURL: `http://127.0.0.1:${PORT}`,
    trace: 'retain-on-failure',
    httpCredentials: basicUser && basicPass ? { username: basicUser, password: basicPass } : undefined,
    extraHTTPHeaders: {
      'x-test-skip-sync': '1',
      'x-test-skip-analysis': '1'
    }
  },
  webServer: {
    command: [
      `LIMITLESS_API_KEY=skip`,
      `BASIC_USER=${basicUser}`,
      `BASIC_PASS=${basicPass}`,
      `DISABLE_LIMITLESS_SYNC=1`,
      `DISABLE_WORKERS_AI=1`,
      `VITE_E2E=1`,
      `npm run dev -- --host 127.0.0.1 --port ${PORT}`
    ].join(' '),
    url: `http://127.0.0.1:${PORT}`,
    reuseExistingServer: !process.env.CI,
    timeout: 60_000
  }
})
