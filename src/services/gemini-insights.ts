import type { Database } from '../db/client'
import type { Bindings } from '../env'
import { lifelogEntries, lifelogSegments } from '../db/schema'
import { desc, eq, and, gte, lt } from 'drizzle-orm'

const GEMINI_MODEL = 'gemini-2.0-flash'
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models'

export type GeminiInsights = {
  suggested_schedules: Array<{
    title: string
    description: string
    suggested_date?: string
    priority: 'high' | 'medium' | 'low'
  }>
  todo_items: Array<{
    title: string
    description: string
    due_date?: string
    priority: 'high' | 'medium' | 'low'
  }>
  insights: Array<{
    category: string
    content: string
    source_context?: string
  }>
  shopping_suggestions: Array<{
    item: string
    reason: string
    urgency: 'immediate' | 'soon' | 'later'
  }>
  summary: string
}

const SYSTEM_PROMPT = `あなたは優秀なパーソナルアシスタントです。与えられたライフログ（会話データ）を分析し、以下の4つの観点で有用な情報を抽出してください。

分析対象：
1. **追加した方が良さそうな予定（suggested_schedules）**: 会話中で言及された予定、約束、イベントなど
2. **TODOにした方が良さそうなタスク（todo_items）**: やるべきこと、宿題、調べ物、連絡事項など
3. **インサイト・学び（insights）**: 会話から得られた気づき、新しい知識、重要な発見
4. **買い物提案（shopping_suggestions）**: 必要そうなもの、欲しいと言っていたもの、消耗品の補充など

重要な注意事項：
- 日本語で出力してください
- 具体的で実行可能な形で提案してください
- 会話の文脈を考慮して、本当に重要なものだけを抽出してください
- 各項目は最大5個までにしてください
- 該当するものがない場合は空配列で返してください`

const JSON_SCHEMA = {
  type: 'object',
  properties: {
    suggested_schedules: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          description: { type: 'string' },
          suggested_date: { type: 'string' },
          priority: { type: 'string', enum: ['high', 'medium', 'low'] }
        },
        required: ['title', 'description', 'priority']
      }
    },
    todo_items: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          description: { type: 'string' },
          due_date: { type: 'string' },
          priority: { type: 'string', enum: ['high', 'medium', 'low'] }
        },
        required: ['title', 'description', 'priority']
      }
    },
    insights: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          category: { type: 'string' },
          content: { type: 'string' },
          source_context: { type: 'string' }
        },
        required: ['category', 'content']
      }
    },
    shopping_suggestions: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          item: { type: 'string' },
          reason: { type: 'string' },
          urgency: { type: 'string', enum: ['immediate', 'soon', 'later'] }
        },
        required: ['item', 'reason', 'urgency']
      }
    },
    summary: { type: 'string' }
  },
  required: ['suggested_schedules', 'todo_items', 'insights', 'shopping_suggestions', 'summary']
}

type GeminiAnalyzeOptions = {
  hoursBack?: number
  from?: Date
  to?: Date
  maxEntries?: number
  maxSegments?: number
  mode?: 'full' | 'hourly_bullets'
}

export const analyzeWithGemini = async (
  db: Database,
  env: Bindings,
  options: GeminiAnalyzeOptions = {}
): Promise<GeminiInsights | null> => {
  const apiKey = env.GEMINI_API_KEY

  if (!apiKey) {
    console.warn('Missing GEMINI_API_KEY; skipping Gemini analysis.')
    return null
  }

  const {
    hoursBack = 1,
    from,
    to = new Date(),
    maxEntries = 50,
    maxSegments = 200,
    mode = 'full'
  } = options

  // 期間決定（優先順位: from/to → hoursBack）
  const rangeFrom = from
    ? from
    : (() => {
        const d = new Date()
        d.setHours(d.getHours() - hoursBack)
        return d
      })()
  const rangeTo = to

  const entries = await db
    .select({
      id: lifelogEntries.id,
      title: lifelogEntries.title,
      markdown: lifelogEntries.markdown,
      startTime: lifelogEntries.startTime,
      endTime: lifelogEntries.endTime
    })
    .from(lifelogEntries)
    .where(
      and(
        gte(lifelogEntries.startTime, rangeFrom.toISOString()),
        lt(lifelogEntries.startTime, rangeTo.toISOString())
      )
    )
    .orderBy(desc(lifelogEntries.startTime))
    .limit(maxEntries)

  if (entries.length === 0) {
    console.info('No recent entries found for Gemini analysis')
    return null
  }

  // 各エントリのセグメントを取得
  const entriesWithSegments = await Promise.all(
    entries.map(async (entry) => {
      const segments = await db
        .select({
          content: lifelogSegments.content,
          speakerName: lifelogSegments.speakerName,
          startTime: lifelogSegments.startTime
        })
        .from(lifelogSegments)
        .where(eq(lifelogSegments.entryId, entry.id))
        .limit(maxSegments)

      return {
        ...entry,
        segments
      }
    })
  )

  // プロンプト用のペイロードを作成
  const payload = JSON.stringify({
    analysis_period: {
      from: rangeFrom.toISOString(),
      to: rangeTo.toISOString()
    },
    entries: entriesWithSegments.map(e => ({
      title: e.title,
      startTime: e.startTime,
      endTime: e.endTime,
      content: e.markdown || e.segments.map(s =>
        s.speakerName ? `${s.speakerName}: ${s.content}` : s.content
      ).join('\n')
    }))
  })

  const basePrompt = mode === 'hourly_bullets'
    ? `あなたは簡潔なサマリー専任のアシスタントです。以下の時間範囲の出来事を日本語で3-6行の箇条書きにまとめてください。

出力要件:
- summary フィールドのみに箇条書きで書く（例: "- ミーティングでAの仕様確認"）
- 他の配列フィールド（suggested_schedules, todo_items, insights, shopping_suggestions）は内容がなければ空配列のまま返す
- JSONのみを返し、コメントやコードフェンスは不要
- 重要度が低い雑談は入れず、行数は最小限に抑える
`
    : `${SYSTEM_PROMPT}

以下のライフログを分析して、JSON形式で結果を返してください。JSONのみを返してください（コメントやコードフェンスは不要）。`

  const prompt = `${basePrompt}

Schema:
${JSON.stringify(JSON_SCHEMA, null, 2)}

分析対象期間: ${rangeFrom.toISOString()} 〜 ${rangeTo.toISOString()}
ライフログデータ:
${payload}`

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
            temperature: 0.7,
            maxOutputTokens: 4096
          }
        })
      }
    )

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Gemini API error:', response.status, errorText)
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
      console.error('No text in Gemini response')
      return null
    }

    // JSONをパース
    const insights = JSON.parse(text) as GeminiInsights
    return insights
  } catch (error) {
    console.error('Gemini analysis failed:', error)
    return null
  }
}
