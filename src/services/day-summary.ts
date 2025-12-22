import { and, desc, eq, gte, lt } from 'drizzle-orm'
import type { Database } from '../db/client'
import { lifelogAnalyses, lifelogEntries } from '../db/schema'
import type { Bindings } from '../env'
import { deleteSyncStateKey, getSyncStateValue, upsertSyncState } from './state'

const MODEL = '@cf/openai/gpt-oss-120b'
const GEMINI_MODEL = 'gemini-2.0-flash'
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models'
const SUMMARY_KEY_PREFIX = 'day_summary:'

export type DayTweet = {
  text: string
  time: string
}

export type DaySummary = {
  date: string
  tweets: DayTweet[]
  generatedAt: string
  source: 'cached' | 'generated' | 'unavailable'
  model?: string
}

type PreferredProvider = 'openai' | 'gemini'

type StoredSummary = {
  tweets: Array<string | DayTweet>
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

// 3-hour time windows: 0-2, 3-5, 6-8, 9-11, 12-14, 15-17, 18-20, 21-23
const TIME_WINDOWS = [
  { start: 0, end: 2, label: '0-2' },
  { start: 3, end: 5, label: '3-5' },
  { start: 6, end: 8, label: '6-8' },
  { start: 9, end: 11, label: '9-11' },
  { start: 12, end: 14, label: '12-14' },
  { start: 15, end: 17, label: '15-17' },
  { start: 18, end: 20, label: '18-20' },
  { start: 21, end: 23, label: '21-23' }
] as const

type TimeWindowLabel = (typeof TIME_WINDOWS)[number]['label']

const getTimeWindow = (hour: number): TimeWindowLabel | null => {
  for (const window of TIME_WINDOWS) {
    if (hour >= window.start && hour <= window.end) {
      return window.label
    }
  }
  return null
}

const getWindowMidpointTime = (windowLabel: TimeWindowLabel): string => {
  const window = TIME_WINDOWS.find((w) => w.label === windowLabel)
  if (!window) return '12:00'
  const midHour = Math.floor((window.start + window.end) / 2)
  return `${midHour.toString().padStart(2, '0')}:30`
}

const SUMMARY_JSON_SCHEMA = {
  type: 'object',
  properties: {
    tweets: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          window: { type: 'string' },
          text: { type: 'string' }
        },
        required: ['window', 'text']
      },
      maxItems: 8
    }
  },
  required: ['tweets']
}

const buildSummaryPrompt = (payload: string, windows: TimeWindowLabel[]) => `あなたは日記編集者です。
以下は1日のライフログ要約素材です。各時間帯ごとに「その時間帯を象徴するツイート文」を1つずつ生成してください。

ルール:
- 各ツイートは80〜200文字程度
- 箇条書きや箇条書き風の記号は避ける
- 固有名詞は必要最低限にし、自然な文体でまとめる
- 各時間帯の内容を反映したツイートを生成する
- データがある時間帯のみ生成する（以下の時間帯: ${windows.join(', ')}）

出力はJSONのみで、次のスキーマに厳密に従ってください:
${JSON.stringify(SUMMARY_JSON_SCHEMA)}

素材:
${payload}
`

type ParsedTweet = { window: string; text: string }

const tryParseTweets = (raw: string): ParsedTweet[] | null => {
  const parseJson = (json: string): ParsedTweet[] | null => {
    try {
      const parsed = JSON.parse(json) as { tweets?: unknown }
      if (!parsed.tweets || !Array.isArray(parsed.tweets)) return null

      // Handle both new format { window, text } and legacy format (string[])
      const tweets = parsed.tweets
        .map((tweet: unknown): ParsedTweet | null => {
          if (typeof tweet === 'string') {
            return { window: '12-14', text: tweet } // Legacy: assign to midday
          }
          if (tweet && typeof tweet === 'object') {
            const t = tweet as { window?: string; text?: string }
            if (typeof t.text === 'string' && typeof t.window === 'string') {
              return { window: t.window, text: t.text }
            }
          }
          return null
        })
        .filter((t): t is ParsedTweet => t !== null)
        .slice(0, 8)

      return tweets.length ? tweets : null
    } catch {
      return null
    }
  }

  const result = parseJson(raw)
  if (result) return result

  // Try to extract JSON from response
  const trimmed = raw.trim()
  const start = trimmed.indexOf('{')
  const end = trimmed.lastIndexOf('}')
  if (start === -1 || end <= start) return null

  return parseJson(trimmed.slice(start, end + 1))
}

const formatJstTime = (value: Date) =>
  value.toLocaleTimeString('ja-JP', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    timeZone: 'Asia/Tokyo'
  })

const buildFallbackTimes = (date: string, count: number, generatedAt?: string) => {
  const base = generatedAt ? new Date(generatedAt) : new Date(`${date}T12:00:00+09:00`)
  const times: string[] = []
  for (let i = 0; i < count; i += 1) {
    const stamp = new Date(base.getTime() + i * 2 * 60 * 60 * 1000)
    times.push(formatJstTime(stamp))
  }
  return times
}

const buildTweetTimes = (
  items: Array<{ startTime: string | null; endTime: string | null }>,
  count: number,
  date: string
) => {
  const times = items
    .map((item) => item.startTime ?? item.endTime)
    .filter((value): value is string => Boolean(value))
    .map((value) => new Date(value))
    .filter((value) => !Number.isNaN(value.getTime()))
  if (!times.length) {
    return buildFallbackTimes(date, count)
  }
  const min = times.reduce((a, b) => (a.getTime() < b.getTime() ? a : b))
  const max = times.reduce((a, b) => (a.getTime() > b.getTime() ? a : b))
  const span = Math.max(max.getTime() - min.getTime(), 60 * 60 * 1000)
  const result: string[] = []
  for (let i = 0; i < count; i += 1) {
    const ratio = count === 1 ? 0.5 : i / Math.max(count - 1, 1)
    const stamp = new Date(min.getTime() + span * ratio)
    result.push(formatJstTime(stamp))
  }
  return result
}

const normalizeStoredTweets = (
  tweets: Array<string | DayTweet>,
  date: string,
  generatedAt?: string
): DayTweet[] => {
  if (!tweets.length) return []
  if (typeof tweets[0] === 'string') {
    const times = buildFallbackTimes(date, tweets.length, generatedAt)
    return (tweets as string[]).map((text, index) => ({
      text,
      time: times[index] ?? times[times.length - 1]
    }))
  }
  return tweets as DayTweet[]
}

const generateWithGemini = async (
  promptPayload: string,
  env: Bindings,
  date: string,
  activeWindows: TimeWindowLabel[] = []
): Promise<DaySummary | null> => {
  const apiKey = env.GEMINI_API_KEY
  if (!apiKey) {
    return null
  }

  const prompt = buildSummaryPrompt(promptPayload, activeWindows)

  try {
    const response = await fetch(
      `${GEMINI_API_URL}/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: prompt
            }]
          }],
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.4,
            maxOutputTokens: 2048
          }
        })
      }
    )

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Gemini day-summary API error:', response.status, errorText)
      return null
    }

    const result = await response.json() as {
      candidates?: Array<{
        content?: {
          parts?: Array<{
            text?: string
          }>
        }
      }>
    }

    const text = result.candidates?.[0]?.content?.parts?.[0]?.text
    if (!text) {
      console.error('No text in Gemini day-summary response')
      return null
    }

    const tweets = tryParseTweets(text) ?? []
    if (!tweets.length) return null

    const now = new Date().toISOString()
    return {
      date,
      tweets: tweets.map((tweet) => ({
        text: tweet.text,
        time: getWindowMidpointTime(tweet.window as TimeWindowLabel)
      })),
      generatedAt: now,
      source: 'generated',
      model: GEMINI_MODEL
    }
  } catch (error) {
    console.error('Gemini day-summary failed:', error)
    return null
  }
}

const summarizeFromEntries = async (
  db: Database,
  env: Bindings,
  date: string,
  opts: { preferredModel?: PreferredProvider } = {}
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

  if (!env.AI || env.DISABLE_WORKERS_AI === '1') {
    return {
      date,
      tweets: [],
      generatedAt: now,
      source: 'unavailable'
    }
  }

  // Group entries by 3-hour time windows
  const windowedItems = new Map<TimeWindowLabel, typeof entries>()
  for (const entry of entries) {
    if (!entry.startTime) continue
    const entryDate = new Date(entry.startTime)
    // Convert to JST hour
    const jstHour = (entryDate.getUTCHours() + 9) % 24
    const windowLabel = getTimeWindow(jstHour)
    if (!windowLabel) continue

    if (!windowedItems.has(windowLabel)) {
      windowedItems.set(windowLabel, [])
    }
    windowedItems.get(windowLabel)!.push(entry)
  }

  // Get windows that have data
  const activeWindows = Array.from(windowedItems.keys()).sort((a, b) => {
    const windowA = TIME_WINDOWS.find((w) => w.label === a)
    const windowB = TIME_WINDOWS.find((w) => w.label === b)
    return (windowA?.start ?? 0) - (windowB?.start ?? 0)
  })

  if (!activeWindows.length) {
    return {
      date,
      tweets: [],
      generatedAt: now,
      source: 'unavailable'
    }
  }

  // Build items with window information
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
    // Determine window for this entry
    let window: TimeWindowLabel | null = null
    if (entry.startTime) {
      const entryDate = new Date(entry.startTime)
      const jstHour = (entryDate.getUTCHours() + 9) % 24
      window = getTimeWindow(jstHour)
    }
    return {
      title: entry.title,
      startTime: entry.startTime,
      endTime: entry.endTime,
      analysisSummary,
      markdownSnippet,
      window
    }
  })

  const promptPayload = JSON.stringify({ date, items, activeWindows })
  const preferredModel = opts.preferredModel ?? 'openai'
  const allowGeminiFallback = preferredModel !== 'gemini'

  if (preferredModel === 'gemini') {
    const gemini = await generateWithGemini(promptPayload, env, date, activeWindows)
    if (gemini) {
      return gemini
    }
  }

  try {
    const response = await env.AI.run(MODEL, {
      input: buildSummaryPrompt(promptPayload, activeWindows)
    })
    const summaryText = extractResponsePayload(response).trim()
    const tweets = tryParseTweets(summaryText) ?? []

    if (!tweets.length && allowGeminiFallback) {
      const gemini = await generateWithGemini(promptPayload, env, date, activeWindows)
      if (gemini) {
        return gemini
      }
    }

    return {
      date,
      tweets: tweets.map((tweet) => ({
        text: tweet.text,
        time: getWindowMidpointTime(tweet.window as TimeWindowLabel)
      })),
      generatedAt: now,
      source: tweets.length ? 'generated' : 'unavailable',
      model: MODEL
    }
  } catch (error) {
    console.error('day summary generation failed', { date, error })
    if (allowGeminiFallback) {
      const gemini = await generateWithGemini(promptPayload, env, date, activeWindows)
      if (gemini) {
        return gemini
      }
    }
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
  date: string,
  opts: { force?: boolean; preferredModel?: PreferredProvider } = {}
): Promise<DaySummary> => {
  const key = `${SUMMARY_KEY_PREFIX}${date}`
  if (opts.force) {
    await deleteSyncStateKey(db, key)
  }
  const cached = await getSyncStateValue(db, key)
  if (cached) {
    try {
      const parsed = JSON.parse(cached) as StoredSummary
      if (parsed.tweets && parsed.tweets.length > 0) {
        return {
          date,
          tweets: normalizeStoredTweets(parsed.tweets, date, parsed.generatedAt),
          generatedAt: parsed.generatedAt,
          source: 'cached',
          model: parsed.model
        }
      }
    } catch {
      // fall through to regeneration
    }
  }

  const generated = await summarizeFromEntries(db, env, date, {
    preferredModel: opts.preferredModel
  })
  const stored: StoredSummary = {
    tweets: generated.tweets,
    generatedAt: generated.generatedAt,
    model: generated.model
  }
  await upsertSyncState(db, key, JSON.stringify(stored))
  return generated
}

export const regenerateDaySummary = async (
  db: Database,
  env: Bindings,
  date: string,
  preferredModel?: PreferredProvider
): Promise<DaySummary> => getDaySummary(db, env, date, { force: true, preferredModel })
