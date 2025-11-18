/** @jsxImportSource hono/jsx */
import type {
  ExportedHandler,
  ExportedHandlerScheduledHandler
} from '@cloudflare/workers-types'
import { Hono } from 'hono'
import { basicAuth } from 'hono/basic-auth'
import type { Context } from 'hono'
import { renderer } from './renderer'
import type { Env } from './env'
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
import { getDb } from './db/client'
import { lifelogEntries, lifelogSegments } from './db/schema'
import { sql } from 'drizzle-orm'

const app = new Hono<Env>()

app.use('*', withDb())
app.use(
  '*',
  basicAuth({
    verifyUser: async (username, password, c) => {
      const { BASIC_USER, BASIC_PASS } = c.env
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
  const [timelineEntries, lastSyncedAt, lastAnalyzedAt] = await Promise.all([
    getTimelineSnapshot(db, { limit: 50 }),
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
      await syncLifelogs(db, c.env, { fullRefresh: true })
      // Analyze entries gradually to avoid rate limits
      c.executionCtx.waitUntil(analyzeFreshEntries(db, c.env, { limit: 5 }))
    } else if (isStale(lastSyncedAt, 60)) {
      c.executionCtx.waitUntil(
        syncLifelogs(db, c.env).then(() => analyzeFreshEntries(db, c.env, { limit: 3 }))
      )
    } else {
      // Even if sync is fresh, analyze any entries that need it
      c.executionCtx.waitUntil(analyzeFreshEntries(db, c.env, { limit: 2 }))
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

const scheduled: ExportedHandlerScheduledHandler<Env> = async (
  event,
  env,
  ctx
) => {
  const db = getDb(env.LIFELOG_DB)
  await syncLifelogs(db, env)
}

export default {
  fetch: fetchHandler,
  scheduled
}
