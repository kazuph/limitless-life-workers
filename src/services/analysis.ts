import { and, desc, eq, inArray, isNull, ne, or } from 'drizzle-orm'
import type { Database } from '../db/client'
import {
  lifelogAnalyses,
  lifelogEntries,
  lifelogSegments
} from '../db/schema'
import type { Bindings } from '../env'
import { getSyncStateValue, upsertSyncState } from './state'
import type { AnalysisJSON } from '../types/analysis'
import { logAnalysisEvent } from './analysis-log'

const MODEL = '@cf/openai/gpt-oss-120b'
const GEMINI_MODEL = 'gemini-2.0-flash'
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models'
const ANALYSIS_VERSION = 'v1'
const LAST_ANALYZED_KEY = 'lifelog:lastAnalyzedAt'
const SYSTEM_PROMPT =
  'あなたは生産性コーチです。与えられたライフログを読み取り、モノクロ表示でも分かりやすい要約とアクション提案を日本語で作成してください。moodフィールドは必ず「絵文字 テキスト」の形式で出力してください（例：😊 前向き、😓 やや疲労感、💪 意欲的）。'
const JSON_PARSE_SNIPPET_MAX = 160

const buildJsonSchemaDefinition = () => ({
  type: 'object',
  properties: {
    summary: { type: 'string' },
    mood: { type: 'string' },
    tags: {
      type: 'array',
      items: { type: 'string' }
    },
    time_blocks: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          startTime: { type: 'string' },
          endTime: { type: 'string' },
          label: { type: 'string' },
          details: { type: 'string' }
        },
        required: ['label']
      }
    },
    action_items: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          suggested_integration: { type: 'string' },
          due: { type: 'string' }
        },
        required: ['title']
      }
    },
    suggestions: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          target: { type: 'string' },
          rationale: { type: 'string' }
        },
        required: ['target', 'rationale']
      }
    }
  },
  required: ['summary', 'mood', 'tags', 'time_blocks', 'action_items', 'suggestions']
})

const ANALYSIS_JSON_SCHEMA = buildJsonSchemaDefinition()
const SCHEMA_TEXT = JSON.stringify(ANALYSIS_JSON_SCHEMA, null, 2)

const buildAnalysisPrompt = (payload: string) => `${SYSTEM_PROMPT}
Return ONLY valid JSON that matches the provided schema. Do not include commentary or code fences.

Schema:
${SCHEMA_TEXT}

Analyze the following lifelog JSON and respond strictly with the requested schema:
${payload}`

const analyzeWithGeminiFallback = async (
  payload: string,
  env: Bindings
): Promise<AnalysisJSON | null> => {
  const apiKey = env.GEMINI_API_KEY
  if (!apiKey) return null

  const prompt = buildAnalysisPrompt(payload)

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
            maxOutputTokens: 4096
          }
        })
      }
    )

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Gemini analysis fallback error:', response.status, errorText)
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
      console.error('No text in Gemini fallback response')
      return null
    }

    return tryParseAnalysisJson(text)
  } catch (error) {
    console.error('Gemini fallback failed:', error)
    return null
  }
}

const tryParseAnalysisJson = (raw: string): AnalysisJSON | null => {
  try {
    return JSON.parse(raw) as AnalysisJSON
  } catch {
    const trimmed = raw.trim()
    const start = trimmed.indexOf('{')
    const end = trimmed.lastIndexOf('}')
    if (start === -1 || end <= start) {
      return null
    }
    try {
      return JSON.parse(trimmed.slice(start, end + 1)) as AnalysisJSON
    } catch {
      return null
    }
  }
}

const ensureAnalysisJson = (raw: string): AnalysisJSON => {
  const parsed = tryParseAnalysisJson(raw)
  if (!parsed) {
    const preview = raw
      .replace(/\s+/g, ' ')
      .slice(0, JSON_PARSE_SNIPPET_MAX)
    throw new SyntaxError(`Model response is not valid JSON: "${preview}"`)
  }
  return parsed
}

const buildRepairPrompt = (schema: unknown, attempt: string) =>
  'You fix malformed JSON by returning a corrected JSON document matching the provided schema. ' +
  'Return JSON only without commentary.\n' +
  `Schema:\n${JSON.stringify(schema)}\n\nAttempt:\n${attempt}`
const extractResponsePayload = (result: unknown): string => {
  if (typeof result === 'string') {
    return result
  }

  if (result && typeof result === 'object') {
    const withResponse = result as { response?: unknown }
    if (typeof withResponse.response === 'string') {
      return withResponse.response
    }

    const withOutputText = result as { output_text?: unknown }
    if (Array.isArray(withOutputText.output_text)) {
      const textChunks = withOutputText.output_text.filter(
        (text): text is string => typeof text === 'string'
      )
      if (textChunks.length) {
        return textChunks.join('\n')
      }
    }

    const withOutput = result as {
      output?: Array<{ content?: Array<{ text?: string }> }>
    }
    if (Array.isArray(withOutput.output)) {
      const chunks = withOutput.output
        .flatMap((item) => (Array.isArray(item?.content) ? item.content : []))
        .map((part) => part?.text)
        .filter((text): text is string => typeof text === 'string')

      if (chunks.length) {
        return chunks.join('\n')
      }
    }
  }

  return '{}'
}

type AnalyzeOptions = {
  limit?: number
  entryIds?: string[]
  force?: boolean
}

export const analyzeFreshEntries = async (
  db: Database,
  env: Bindings,
  opts: AnalyzeOptions = {}
) => {
  if (!env.AI) {
    console.warn('Workers AI binding is not configured')
    return []
  }
  if (env.DISABLE_WORKERS_AI === '1') {
    console.info('Workers AI disabled via DISABLE_WORKERS_AI flag; skipping analysis.')
    return []
  }
  const { limit = 2, entryIds, force = false } = opts
  const scopedEntryIds = entryIds?.filter((id) => Boolean(id?.trim())) ?? []

  const baseQuery = db
    .select({
      id: lifelogEntries.id,
      title: lifelogEntries.title,
      markdown: lifelogEntries.markdown,
      startTime: lifelogEntries.startTime,
      endTime: lifelogEntries.endTime,
      summaryHash: lifelogEntries.summaryHash
    })
    .from(lifelogEntries)
    .leftJoin(
      lifelogAnalyses,
      and(
        eq(lifelogAnalyses.entryId, lifelogEntries.id),
        eq(lifelogAnalyses.version, ANALYSIS_VERSION)
      )
    )

  const needsAnalysis = or(
    isNull(lifelogAnalyses.id),
    ne(lifelogAnalyses.payloadHash, lifelogEntries.summaryHash)
  )

  const whereClause = scopedEntryIds.length
    ? force
      ? inArray(lifelogEntries.id, scopedEntryIds)
      : and(inArray(lifelogEntries.id, scopedEntryIds), needsAnalysis)
    : needsAnalysis

  const fetchLimit = scopedEntryIds.length || limit

  const candidates = await baseQuery
    .where(whereClause)
    .orderBy(desc(lifelogEntries.startTime))
    .limit(fetchLimit)

  const analyzedIds: string[] = []
  const skippedIds: string[] = []

  for (let i = 0; i < candidates.length; i++) {
    const entry = candidates[i]
    if (!entry.id) continue

    // Add delay between requests to avoid rate limits (except for first request)
    if (i > 0) {
      await new Promise(resolve => setTimeout(resolve, 5000))
    }
    const segments = await db
      .select({
        content: lifelogSegments.content,
        startTime: lifelogSegments.startTime,
        endTime: lifelogSegments.endTime,
        speakerName: lifelogSegments.speakerName,
        nodeType: lifelogSegments.nodeType
      })
      .from(lifelogSegments)
      .where(eq(lifelogSegments.entryId, entry.id))
      .limit(120)

    const promptPayload = JSON.stringify({
      meta: {
        id: entry.id,
        title: entry.title,
        startTime: entry.startTime,
        endTime: entry.endTime
      },
      markdown: entry.markdown,
      segments
    })

    try {
      const primaryRequest = {
        input: buildAnalysisPrompt(promptPayload),
        response_format: {
          type: 'json_schema',
          json_schema: {
            name: 'lifelog_analysis',
            schema: ANALYSIS_JSON_SCHEMA
          }
        }
      }

      let response = await env.AI.run(MODEL, primaryRequest)
      let serialized = extractResponsePayload(response)
      let parsed = tryParseAnalysisJson(serialized)
      let modelUsed = MODEL

      if (!parsed) {
        response = await env.AI.run(MODEL, {
          input: buildRepairPrompt(ANALYSIS_JSON_SCHEMA, serialized),
          response_format: primaryRequest.response_format
        })
        serialized = extractResponsePayload(response)
        parsed = tryParseAnalysisJson(serialized)
      }

      if (!parsed) {
        const geminiParsed = await analyzeWithGeminiFallback(promptPayload, env)
        if (geminiParsed) {
          parsed = geminiParsed
          modelUsed = GEMINI_MODEL
        }
      }

      const analysisJson = parsed ?? ensureAnalysisJson(serialized)

      await db
        .insert(lifelogAnalyses)
        .values({
          entryId: entry.id,
          model: modelUsed,
          version: ANALYSIS_VERSION,
          payloadHash: entry.summaryHash ?? undefined,
          insightsJson: JSON.stringify(analysisJson)
        })
        .onConflictDoUpdate({
          target: [lifelogAnalyses.entryId, lifelogAnalyses.version],
          set: {
            model: modelUsed,
            payloadHash: entry.summaryHash ?? undefined,
            insightsJson: JSON.stringify(analysisJson),
            createdAt: new Date().toISOString()
          }
        })

      await db
        .update(lifelogEntries)
        .set({ lastAnalyzedAt: new Date().toISOString() })
        .where(eq(lifelogEntries.id, entry.id))

      await logAnalysisEvent(db, {
        entryId: entry.id,
        status: 'success',
        details: `Analysis stored (${modelUsed})`
      })

      analyzedIds.push(entry.id)
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      const isRateLimit = errorMessage.includes('1031')

      if (isRateLimit) {
        console.warn('Rate limit reached, skipping remaining entries', { id: entry.id })
        skippedIds.push(entry.id)
        // Stop processing to avoid more rate limit errors
        break
      }

      console.error('analysis failed', { id: entry.id, error })
      await logAnalysisEvent(db, {
        entryId: entry.id,
        status: 'error',
        details: errorMessage
      })
    }
  }

  if (skippedIds.length > 0) {
    console.info(`Skipped ${skippedIds.length} entries due to rate limits. They will be analyzed on next run.`)
  }

  if (analyzedIds.length) {
    await upsertSyncState(db, LAST_ANALYZED_KEY, new Date().toISOString())
  }

  return analyzedIds
}

export const getLastAnalyzedAt = async (db: Database) =>
  getSyncStateValue(db, LAST_ANALYZED_KEY)
