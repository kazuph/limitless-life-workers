/** @jsxImportSource hono/jsx */
import type {
  ExportedHandler,
  ExportedHandlerScheduledHandler
} from '@cloudflare/workers-types'
import { Hono } from 'hono'
import { basicAuth } from 'hono/basic-auth'
import { secureHeaders } from 'hono/secure-headers'
import type { Context } from 'hono'
import { renderer } from './renderer'
import type { Env, Bindings } from './env'
import { withDb } from './middleware/db'
import { getIntegrationSuggestions } from './services/integrations'
import { getTimelineSnapshot } from './services/timeline'
import {
  analyzeFreshEntries,
  getLastAnalyzedAt
} from './services/analysis'
import {
  getLastSyncedAt,
  syncLifelogs
} from './services/sync'
import type { SyncStats } from './services/sync'
import { analyzeWithGemini } from './services/gemini-insights'
import { postInsightsToSlack, postErrorToSlack, postWarningToSlack } from './services/slack'
import { getDb } from './db/client'
import type { Database } from './db/client'
import { lifelogEntries, lifelogSegments } from './db/schema'
import { sql } from 'drizzle-orm'
import { cloudflareRateLimiter } from '@hono-rate-limiter/cloudflare'
import { getSyncStateValue, upsertSyncState } from './services/state'

const app = new Hono<Env>()
const LAST_GEMINI_POSTED_KEY = 'gemini:lastPostedAt'
const MORNING_SUMMARY_KEY = 'gemini:morningSummaryDate'
const EVENING_SUMMARY_KEY = 'gemini:eveningSummaryDate'
const LAST_UPDATED_AT_KEY = 'lifelog:lastUpdatedAt'
const LAST_SYNC_WARNING_KEY = 'lifelog:lastWarningAt'

// Apply security headers
app.use('*', secureHeaders({
  strictTransportSecurity: 'max-age=63072000; includeSubDomains; preload',
  xFrameOptions: 'DENY',
  xContentTypeOptions: 'nosniff',
  referrerPolicy: 'no-referrer',
  crossOriginResourcePolicy: 'same-origin'
}))

// Apply rate limiting (100 requests per minute per IP) - only if binding exists
app.use('*', async (c, next) => {
  if (c.env.RATE_LIMITER) {
    return cloudflareRateLimiter<Env>({
      rateLimitBinding: (c) => c.env.RATE_LIMITER,
      keyGenerator: (c) => c.req.header('cf-connecting-ip') || 'unknown'
    })(c, next)
  }
  await next()
})

// robots.txt - Disallow all crawlers (must be before auth middleware)
app.get('/robots.txt', (c) => {
  return c.text(
    `User-agent: *
Disallow: /`,
    200,
    { 'Content-Type': 'text/plain' }
  )
})

app.use('*', withDb())
app.use(
  '*',
  basicAuth({
    verifyUser: async (username, password, c) => {
      const { BASIC_USER, BASIC_PASS } = c.env
      // Skip basic auth in development if accessing via localhost
      const host = c.req.header('host') || ''
      if (host.includes('localhost') || host.includes('127.0.0.1')) {
        return true
      }
      if (!BASIC_USER || !BASIC_PASS) {
        console.warn('Basic auth credentials missing in environment')
        return true
      }
      return username === BASIC_USER && password === BASIC_PASS
    },
    unauthorizedResponse: (c) =>
      c.text('Unauthorized', 401, { 'WWW-Authenticate': 'Basic realm="life-log-app"' })
  })
)

app.get('/api/health', async (c) => {
  const db = c.get('db')
  const [lastSyncedAt, lastAnalyzedAt] = await Promise.all([
    getLastSyncedAt(db),
    getLastAnalyzedAt(db)
  ])
  return c.json({
    ok: true,
    lastSyncedAt,
    lastAnalyzedAt
  })
})

app.get('/api/lifelogs', async (c) => {
  await ensureFreshData(c)
  const db = c.get('db')
  const days = parseInt(c.req.query('days') || '7', 10)
  const offset = parseInt(c.req.query('offset') || '0', 10)

  const [timelineEntries, lastSyncedAt, lastAnalyzedAt] = await Promise.all([
    getTimelineSnapshot(db, { days, offset }),
    getLastSyncedAt(db),
    getLastAnalyzedAt(db)
  ])

  return c.json({
    timeline: timelineEntries,
    lastSyncedAt,
    lastAnalyzedAt,
    integrations: getIntegrationSuggestions()
  })
})

app.get('/api/debug/entries', async (c) => {
  const db = c.get('db')

  const entries = await db
    .select({
      id: lifelogEntries.id,
      title: lifelogEntries.title,
      startTime: lifelogEntries.startTime,
      endTime: lifelogEntries.endTime,
      dateLabel: sql<string>`date(${lifelogEntries.startTime})`
    })
    .from(lifelogEntries)
    .orderBy(sql`${lifelogEntries.startTime} DESC`)
    .limit(100)

  const dateGroups = new Map<string, number>()
  for (const entry of entries) {
    const date = entry.dateLabel || 'unknown'
    dateGroups.set(date, (dateGroups.get(date) || 0) + 1)
  }

  return c.json({
    totalEntries: entries.length,
    dateGroups: Object.fromEntries(dateGroups),
    recentEntries: entries.slice(0, 10).map(e => ({
      id: e.id,
      title: e.title,
      startTime: e.startTime,
      dateLabel: e.dateLabel
    }))
  })
})

app.get('/api/debug/segments/:entryId', async (c) => {
  const db = c.get('db')
  const entryId = c.req.param('entryId')

  const segments = await db
    .select()
    .from(lifelogSegments)
    .where(sql`${lifelogSegments.entryId} = ${entryId}`)

  return c.json({
    entryId,
    segmentCount: segments.length,
    segments: segments.map(seg => ({
      id: seg.nodeId,
      nodeType: seg.nodeType,
      contentLength: seg.content?.length || 0,
      contentPreview: seg.content?.slice(0, 100) || null,
      startTime: seg.startTime,
      endTime: seg.endTime,
      speakerName: seg.speakerName
    }))
  })
})

app.post('/api/sync', async (c) => {
  const db = c.get('db')
  const stats = await syncLifelogs(db, c.env, {
    fullRefresh: c.req.query('full') === '1',
    skipNetwork: false
  })
  return c.json({ ok: true, stats })
})

app.post('/api/analyze/:entryId', async (c) => {
  const db = c.get('db')
  const entryId = c.req.param('entryId')

  if (!entryId) {
    return c.json({ ok: false, error: 'Missing entryId' }, 400)
  }

  const analyzedIds = await analyzeFreshEntries(db, c.env, {
    entryIds: [entryId],
    force: true
  })
  const ok = analyzedIds.includes(entryId)
  const status = ok ? 200 : 404

  return c.json({ ok, analyzedIds }, status)
})

// Gemini分析してSlackに投稿（手動トリガー用）
app.post('/api/slack-insights', async (c) => {
  const db = c.get('db')
  const hours = parseInt(c.req.query('hours') || '24', 10)

  try {
    const insights = await analyzeWithGemini(db, c.env, hours)
    if (!insights) {
      return c.json({ ok: false, error: 'No insights generated' }, 404)
    }

    const posted = await postInsightsToSlack(c.env, insights)
    return c.json({
      ok: posted,
      insights,
      posted
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error'
    return c.json({ ok: false, error: message }, 500)
  }
})

app.get('/', renderer, async (c) => {
  await ensureFreshData(c)
  return c.render(
    <div id="root" class="min-h-screen">
      <noscript>Enable JavaScript to view the dashboard.</noscript>
    </div>
  )
})

const ensureFreshData = async (c: Context<Env>) => {
  const db = c.get('db')
  const skipSyncHeader = c.req.header('x-test-skip-sync') === '1'
  const lastSyncedAt = await getLastSyncedAt(db)

  const disableSyncFlag = c.env.DISABLE_LIMITLESS_SYNC === '1'
  const skipSync = skipSyncHeader || disableSyncFlag

  if (!skipSync) {
    const [{ count }] = await db
      .select({ count: sql<number>`count(*)` })
      .from(lifelogEntries)
      .limit(1)
    const needsBootstrap = !lastSyncedAt || count === 0

    if (needsBootstrap) {
      // Try to sync, but don't block page rendering if it fails
      // Use incremental sync instead of fullRefresh to avoid excessive API calls
      try {
        await syncLifelogs(db, c.env, { fullRefresh: false })
      } catch (error) {
        console.error('Bootstrap sync failed, but continuing with existing D1 data:', error)
      }
      // Analyze entries gradually to avoid rate limits (reduced from 5 to 3)
      c.executionCtx.waitUntil(
        analyzeFreshEntries(db, c.env, { limit: 3 }).catch(error => {
          console.error('Background analysis failed:', error)
        })
      )
    } else if (isStale(lastSyncedAt, 60)) {
      // Background sync and analysis - errors won't affect page rendering
      c.executionCtx.waitUntil(
        syncLifelogs(db, c.env)
          .then(() => analyzeFreshEntries(db, c.env, { limit: 2 }))
          .catch(error => {
            console.error('Background sync/analysis failed:', error)
          })
      )
    } else {
      // Even if sync is fresh, analyze any entries that need it
      c.executionCtx.waitUntil(
        analyzeFreshEntries(db, c.env, { limit: 1 }).catch(error => {
          console.error('Background analysis failed:', error)
        })
      )
    }
  }

}

const isStale = (value: string, minutes: number) => {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return true
  const threshold = minutes * 60 * 1000
  return Date.now() - date.getTime() > threshold
}

const fetchHandler: ExportedHandler<Env>['fetch'] = (req, env, ctx) =>
  app.fetch(req, env, ctx)

const scheduled: ExportedHandlerScheduledHandler<Bindings> = async (
  event,
  env,
  ctx
) => {
  const db = getDb(env.LIFELOG_DB)
  const lastUpdatedBefore = await getSyncStateValue(db, LAST_UPDATED_AT_KEY)
  let syncStats: SyncStats | null = null

  // 1. Limitlessからデータを同期
  try {
    syncStats = await syncLifelogs(db, env)
  } catch (error) {
    console.error('Sync failed:', error)
    await postErrorToSlack(env, error instanceof Error ? error : String(error), 'Limitless同期')
  }

  await maybeWarnStaleSync(db, env, syncStats, lastUpdatedBefore)

  // 2. Workers AIで分析
  try {
    await analyzeFreshEntries(db, env, { limit: 3 })
  } catch (error) {
    console.error('Workers AI analysis failed:', error)
    await postErrorToSlack(env, error instanceof Error ? error : String(error), 'Workers AI分析')
  }

  // 3. Gemini 2.0 Flashでインサイト分析してSlackに投稿
  ctx.waitUntil(
    (async () => {
      try {
        // 前回投稿以降をまとめて分析（最大24時間ぶんを再取得）
        const lastPostedAt = await getSyncStateValue(db, LAST_GEMINI_POSTED_KEY)
        const now = new Date()
        const hoursSinceLast = lastPostedAt
          ? Math.max(1, Math.ceil((now.getTime() - new Date(lastPostedAt).getTime()) / (60 * 60 * 1000)))
          : 1
        const hoursBack = Math.min(hoursSinceLast, 24)

        const insights = await analyzeWithGemini(db, env, { hoursBack, mode: 'hourly_bullets' })
        if (insights) {
          await postInsightsToSlack(env, insights)
          await upsertSyncState(db, LAST_GEMINI_POSTED_KEY, now.toISOString())
          console.info('Successfully posted insights to Slack')
        }
      } catch (error) {
        console.error('Gemini analysis or Slack post failed:', error)
        await postErrorToSlack(env, error instanceof Error ? error : String(error), 'Gemini分析/Slack投稿')
      }
    })()
  )

  // 4. 朝夕のデイリーまとめ（JST 6時・23時に1回ずつ）
  ctx.waitUntil(
    (async () => {
      try {
        await maybePostDailySummaries(db, env)
      } catch (error) {
        console.error('Daily summary failed:', error)
        await postErrorToSlack(env, error instanceof Error ? error : String(error), 'デイリーGeminiまとめ')
      }
    })()
  )
}

const hoursSince = (iso?: string | null) => {
  if (!iso) return null
  const date = new Date(iso)
  if (Number.isNaN(date.getTime())) return null
  return (Date.now() - date.getTime()) / (1000 * 60 * 60)
}

const maybeWarnStaleSync = async (
  db: Database,
  env: Bindings,
  stats: SyncStats | null,
  lastUpdatedBefore: string | null
) => {
  if (!stats) return

  const lastUpdatedAfter = await getSyncStateValue(db, LAST_UPDATED_AT_KEY)

  const lastWarningAt = await getSyncStateValue(db, LAST_SYNC_WARNING_KEY)
  const hoursSinceWarning = hoursSince(lastWarningAt)
  if (hoursSinceWarning !== null && hoursSinceWarning < 3) return

  // 直近同期が成功していればスキップ
  if (lastUpdatedAfter && lastUpdatedAfter !== lastUpdatedBefore) return

  const staleHours = hoursSince(lastUpdatedAfter || lastUpdatedBefore)

  // 初回や短時間のギャップでは通知を出さない
  if (staleHours !== null && staleHours < 3) return

  const ageText = lastUpdatedAfter || lastUpdatedBefore
    ? `最後の更新から約${staleHours?.toFixed(1) ?? '?'}時間経過 (${lastUpdatedAfter || lastUpdatedBefore})`
    : 'これまでに一度も同期成功していません'

  console.warn('[Limitless] stale sync detected, sending Slack warning', {
    lastUpdatedAfter,
    lastUpdatedBefore,
    staleHours,
    lastWarningAt
  })

  await postWarningToSlack(
    env,
    `Limitless同期が新規データを取得できていません。${ageText}`,
    'Limitless同期'
  )

  await upsertSyncState(db, LAST_SYNC_WARNING_KEY, new Date().toISOString())
}

const toJstDate = (date: Date) =>
  new Date(date.toLocaleString('en-US', { timeZone: 'Asia/Tokyo' }))

const formatJstDate = (date: Date) => {
  const d = toJstDate(date)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

const buildJstDate = (base: Date, hour: number, minute = 0, second = 0) => {
  const d = toJstDate(base)
  d.setHours(hour, minute, second, 0)
  return d
}

const maybePostDailySummaries = async (db: Database, env: Bindings) => {
  const nowJst = toJstDate(new Date())
  const hour = nowJst.getHours()
  const todayStr = formatJstDate(nowJst)

  // 朝6時: 前日0:00-24:00
  if (hour === 6) {
    const yesterday = new Date(nowJst)
    yesterday.setDate(yesterday.getDate() - 1)
    const prevDayStr = formatJstDate(yesterday)
    const lastPosted = await getSyncStateValue(db, MORNING_SUMMARY_KEY)
    if (lastPosted !== prevDayStr) {
      const rangeStart = buildJstDate(yesterday, 0)
      const rangeEnd = buildJstDate(nowJst, 0) // 当日0時
      const insights = await analyzeWithGemini(db, env, {
        from: rangeStart,
        to: rangeEnd,
        maxEntries: 200,
        maxSegments: 400
      })
      if (insights) {
        const header = `@kazuph 🌅 *前日デイリーまとめ (JST)*\n_${prevDayStr}_\n\n`
        await postInsightsToSlack(env, insights, header)
        await upsertSyncState(db, MORNING_SUMMARY_KEY, prevDayStr)
      }
    }
  }

  // 夜23時: 当日6:00-23:00
  if (hour === 23) {
    const lastPosted = await getSyncStateValue(db, EVENING_SUMMARY_KEY)
    if (lastPosted !== todayStr) {
      const rangeStart = buildJstDate(nowJst, 6)
      const rangeEnd = buildJstDate(nowJst, 23, 59, 59)
      const insights = await analyzeWithGemini(db, env, {
        from: rangeStart,
        to: rangeEnd,
        maxEntries: 200,
        maxSegments: 400
      })
      if (insights) {
        const header = `@kazuph 🌙 *本日のまとめ (JST)*\n_${todayStr} 06:00-23:00_\n\n`
        await postInsightsToSlack(env, insights, header)
        await upsertSyncState(db, EVENING_SUMMARY_KEY, todayStr)
      }
    }
  }
}

export default {
  fetch: fetchHandler,
  scheduled
}
