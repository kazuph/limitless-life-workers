/** @jsxImportSource hono/jsx */
import type { ExportedHandler, ExportedHandlerScheduledHandler } from '@cloudflare/workers-types'
import { Hono } from 'hono'
import { basicAuth } from 'hono/basic-auth'
import { secureHeaders } from 'hono/secure-headers'
import type { Env, Bindings } from './env'
import { withDb } from './middleware/db'
import { cloudflareRateLimiter } from '@hono-rate-limiter/cloudflare'
// @ts-ignore - MoonBit generated module
import { configure_app, get_scheduled_handler } from '../target/js/release/build/server/server.js'

const app = new Hono<Env>()

// Security headers
app.use('*', secureHeaders({
  strictTransportSecurity: 'max-age=63072000; includeSubDomains; preload',
  xFrameOptions: 'DENY',
  xContentTypeOptions: 'nosniff',
  referrerPolicy: 'no-referrer',
  crossOriginResourcePolicy: 'same-origin'
}))

// Rate limiting (100 requests per minute per IP)
app.use('*', async (c, next) => {
  if (c.env.RATE_LIMITER) {
    return cloudflareRateLimiter<Env>({
      rateLimitBinding: (c) => c.env.RATE_LIMITER,
      keyGenerator: (c) => c.req.header('cf-connecting-ip') || 'unknown'
    })(c, next)
  }
  await next()
})

// robots.txt
app.get('/robots.txt', (c) => c.text('User-agent: *\nDisallow: /', 200, { 'Content-Type': 'text/plain' }))

// Database middleware
app.use('*', withDb())

// Basic auth
app.use('*', basicAuth({
  verifyUser: async (username, password, c) => {
    const { BASIC_USER, BASIC_PASS } = c.env
    const host = c.req.header('host') || ''
    if (host.includes('localhost') || host.includes('127.0.0.1')) return true
    if (!BASIC_USER || !BASIC_PASS) return true
    return username === BASIC_USER && password === BASIC_PASS
  },
  unauthorizedResponse: (c) => c.text('Unauthorized', 401, { 'WWW-Authenticate': 'Basic realm="life-log-app"' })
}))

// Configure MoonBit routes (API + SSR)
configure_app(app)

// Fetch handler
const fetchHandler: ExportedHandler<Env>['fetch'] = (req, env, ctx) => app.fetch(req, env, ctx)

// Scheduled handler (from MoonBit)
const scheduled: ExportedHandlerScheduledHandler<Bindings> = get_scheduled_handler()

export default { fetch: fetchHandler, scheduled }
