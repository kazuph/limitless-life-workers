import { and, desc, eq, gte, inArray, lt } from 'drizzle-orm'
import type { Database } from '../db/client'
import { lifelogAnalyses, lifelogEntries, lifelogSegments } from '../db/schema'
import type { Bindings } from '../env'
import { getSyncStateValue, upsertSyncState } from './state'

const MODEL = '@cf/openai/gpt-oss-20b'
const SUMMARY_KEY_PREFIX = 'day_summary:'

export type DaySummary = {
  date: string
  tweets: string[]
  generatedAt: string
  source: 'cached' | 'generated' | 'unavailable'
  model?: string
}

type StoredSummary = {
  tweets: string[]
  generatedAt: string
  model?: string
}

const parseDateRange = (date: string) => {
  const [year, month, day] = date.split('-').map((value) => Number(value))
  if (!year || !month || !day) return null
  const startUtc = Date.UTC(year, month - 1, day, 0, 0, 0) - 9 * 60 * 60 * 1000
  const endUtc = startUtc + 24 * 60 * 60 * 1000
  return {
    startIso: new Date(startUtc).toISOString(),
    endIso: new Date(endUtc).toISOString()
  }
}

const extractResponsePayload = (result: unknown): string => {
  if (typeof result === 'string') return result
  if (result && typeof result === 'object') {
    const withResponse = result as { response?: unknown }
    if (typeof withResponse.response === 'string') return withResponse.response
    const withOutputText = result as { output_text?: unknown }
    if (Array.isArray(withOutputText.output_text)) {
      const textChunks = withOutputText.output_text.filter(
        (text): text is string => typeof text === 'string'
      )
      if (textChunks.length) return textChunks.join('\n')
    }
    const withOutput = result as {
      output?: Array<{ content?: Array<{ text?: string }> }>
    }
    if (Array.isArray(withOutput.output)) {
      const chunks = withOutput.output
        .flatMap((item) => (Array.isArray(item?.content) ? item.content : []))
        .map((part) => part?.text)
        .filter((text): text is string => typeof text === 'string')
      if (chunks.length) return chunks.join('\n')
    }
  }
  return ''
}

const SUMMARY_JSON_SCHEMA = {
  type: 'object',
  properties: {
    tweets: {
      type: 'array',
      items: { type: 'string' },
      maxItems: 3
    }
  },
  required: ['tweets']
}

const buildSummaryPrompt = (payload: string) => `あなたは日記編集者です。
以下は1日のライフログ要約素材です。日本語で「その日を象徴するツイート文」を最大3つ生成してください。
各ツイートは80〜200文字程度で、箇条書きや箇条書き風の記号は避けます。
固有名詞は必要最低限にし、自然な文体でまとめてください。
出力はJSONのみで、次のスキーマに厳密に従ってください:
${JSON.stringify(SUMMARY_JSON_SCHEMA)}

素材:
${payload}
`

const tryParseTweets = (raw: string): string[] | null => {
  try {
    const parsed = JSON.parse(raw) as { tweets?: unknown }
    if (!parsed.tweets || !Array.isArray(parsed.tweets)) return null
    return parsed.tweets.filter((tweet): tweet is string => typeof tweet === 'string').slice(0, 3)
  } catch {
    const trimmed = raw.trim()
    const start = trimmed.indexOf('{')
    const end = trimmed.lastIndexOf('}')
    if (start === -1 || end <= start) return null
    try {
      const parsed = JSON.parse(trimmed.slice(start, end + 1)) as { tweets?: unknown }
      if (!parsed.tweets || !Array.isArray(parsed.tweets)) return null
      return parsed.tweets.filter((tweet): tweet is string => typeof tweet === 'string').slice(0, 3)
    } catch {
      return null
    }
  }
}

const summarizeFromEntries = async (
  db: Database,
  env: Bindings,
  date: string
): Promise<DaySummary> => {
  const range = parseDateRange(date)
  const now = new Date().toISOString()
  if (!range) {
    return {
      date,
      tweets: [],
      generatedAt: now,
      source: 'unavailable'
    }
  }

  const entries = await db
    .select({
      id: lifelogEntries.id,
      title: lifelogEntries.title,
      markdown: lifelogEntries.markdown,
      startTime: lifelogEntries.startTime,
      endTime: lifelogEntries.endTime,
      analysisJson: lifelogAnalyses.insightsJson
    })
    .from(lifelogEntries)
    .leftJoin(
      lifelogAnalyses,
      and(eq(lifelogAnalyses.entryId, lifelogEntries.id), eq(lifelogAnalyses.version, 'v1'))
    )
    .where(
      and(
        gte(lifelogEntries.startTime, range.startIso),
        lt(lifelogEntries.startTime, range.endIso)
      )
    )
    .orderBy(desc(lifelogEntries.startTime))
    .limit(120)

  if (!entries.length) {
    return {
      date,
      tweets: [],
      generatedAt: now,
      source: 'unavailable'
    }
  }

  const entryIds = entries.map((entry) => entry.id)
  const hasSegments = await db
    .select({ id: lifelogSegments.entryId })
    .from(lifelogSegments)
    .where(inArray(lifelogSegments.entryId, entryIds))
    .limit(1)
    .then((rows) => rows.length > 0)

  if (!hasSegments) {
    return {
      date,
      tweets: [],
      generatedAt: now,
      source: 'unavailable'
    }
  }

  if (!env.AI || env.DISABLE_WORKERS_AI === '1') {
    return {
      date,
      tweets: [],
      generatedAt: now,
      source: 'unavailable'
    }
  }

  const items = entries.map((entry) => {
    const markdownSnippet = entry.markdown?.slice(0, 240)
    let analysisSummary = ''
    if (entry.analysisJson) {
      try {
        const parsed = JSON.parse(entry.analysisJson) as { summary?: string }
        analysisSummary = parsed.summary ?? ''
      } catch {
        analysisSummary = ''
      }
    }
    return {
      title: entry.title,
      startTime: entry.startTime,
      endTime: entry.endTime,
      analysisSummary,
      markdownSnippet
    }
  })

  const promptPayload = JSON.stringify({ date, items })
  try {
    const response = await env.AI.run(MODEL, {
      input: buildSummaryPrompt(promptPayload)
    })
    const summaryText = extractResponsePayload(response).trim()
    const tweets = tryParseTweets(summaryText) ?? []

    return {
      date,
      tweets,
      generatedAt: now,
      source: tweets.length ? 'generated' : 'unavailable',
      model: MODEL
    }
  } catch (error) {
    console.error('day summary generation failed', { date, error })
    return {
      date,
      tweets: [],
      generatedAt: now,
      source: 'unavailable'
    }
  }
}

export const getDaySummary = async (
  db: Database,
  env: Bindings,
  date: string
): Promise<DaySummary> => {
  const key = `${SUMMARY_KEY_PREFIX}${date}`
  const cached = await getSyncStateValue(db, key)
  if (cached) {
    try {
      const parsed = JSON.parse(cached) as StoredSummary
      if (parsed.tweets && parsed.tweets.length > 0) {
        return {
          date,
          tweets: parsed.tweets,
          generatedAt: parsed.generatedAt,
          source: 'cached',
          model: parsed.model
        }
      }
    } catch {
      // fall through to regeneration
    }
  }

  const generated = await summarizeFromEntries(db, env, date)
  const stored: StoredSummary = {
    tweets: generated.tweets,
    generatedAt: generated.generatedAt,
    model: generated.model
  }
  await upsertSyncState(db, key, JSON.stringify(stored))
  return generated
}
