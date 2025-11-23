import type { Bindings } from '../env'
import type { GeminiInsights } from './gemini-insights'

const SLACK_API_URL = 'https://slack.com/api/chat.postMessage'

export const postToSlack = async (
  env: Bindings,
  text: string
): Promise<boolean> => {
  const token = env.SLACK_BOT_TOKEN
  const channel = env.SLACK_CHANNEL || '#limitless-音声-insight'

  if (!token) {
    console.warn('Missing SLACK_BOT_TOKEN; skipping Slack post.')
    return false
  }

  try {
    const response = await fetch(SLACK_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        token,
        channel,
        username: 'けろよん',
        icon_url: 'https://emoji.slack-edge.com/T030A5CV2/keroyon/c3aa47f65017d188.png',
        text,
        link_names: 'true'
      })
    })

    if (!response.ok) {
      console.error('Slack API error:', response.status)
      return false
    }

    const result = await response.json() as { ok: boolean; error?: string }
    if (!result.ok) {
      console.error('Slack post failed:', result.error)
      return false
    }

    return true
  } catch (error) {
    console.error('Slack post error:', error)
    return false
  }
}

export const formatInsightsForSlack = (insights: GeminiInsights): string => {
  const sections: string[] = []

  // サマリー
  if (insights.summary) {
    sections.push(`📝 *サマリー*\n${insights.summary}`)
  }

  // 予定の提案
  if (insights.suggested_schedules.length > 0) {
    const schedules = insights.suggested_schedules.map(s => {
      const priority = getPriorityEmoji(s.priority)
      const date = s.suggested_date ? ` (${s.suggested_date})` : ''
      return `${priority} *${s.title}*${date}\n   ${s.description}`
    }).join('\n')
    sections.push(`📅 *追加した方が良さそうな予定*\n${schedules}`)
  }

  // TODO項目
  if (insights.todo_items.length > 0) {
    const todos = insights.todo_items.map(t => {
      const priority = getPriorityEmoji(t.priority)
      const due = t.due_date ? ` (期限: ${t.due_date})` : ''
      return `${priority} *${t.title}*${due}\n   ${t.description}`
    }).join('\n')
    sections.push(`✅ *TODOにした方が良さそうなタスク*\n${todos}`)
  }

  // インサイト・学び
  if (insights.insights.length > 0) {
    const insightList = insights.insights.map(i => {
      const context = i.source_context ? ` _（${i.source_context}）_` : ''
      return `💡 *${i.category}*\n   ${i.content}${context}`
    }).join('\n')
    sections.push(`🧠 *インサイト・学び*\n${insightList}`)
  }

  // 買い物提案
  if (insights.shopping_suggestions.length > 0) {
    const shopping = insights.shopping_suggestions.map(s => {
      const urgency = getUrgencyEmoji(s.urgency)
      return `${urgency} *${s.item}*\n   ${s.reason}`
    }).join('\n')
    sections.push(`🛒 *買い物提案*\n${shopping}`)
  }

  // 結合
  return sections.join('\n\n---\n\n')
}

const getPriorityEmoji = (priority: string): string => {
  switch (priority) {
    case 'high': return '🔴'
    case 'medium': return '🟡'
    case 'low': return '🟢'
    default: return '⚪'
  }
}

const getUrgencyEmoji = (urgency: string): string => {
  switch (urgency) {
    case 'immediate': return '🚨'
    case 'soon': return '⏰'
    case 'later': return '📌'
    default: return '📝'
  }
}

export const postInsightsToSlack = async (
  env: Bindings,
  insights: GeminiInsights,
  headerOverride?: string
): Promise<boolean> => {
  // 何もない場合は投稿しない
  const hasContent =
    Boolean(insights.summary && insights.summary.trim()) ||
    insights.suggested_schedules.length > 0 ||
    insights.todo_items.length > 0 ||
    insights.insights.length > 0 ||
    insights.shopping_suggestions.length > 0

  if (!hasContent) {
    console.info('No insights to post to Slack')
    return false
  }

  const text = formatInsightsForSlack(insights)
  const header = headerOverride
    ? headerOverride
    : `@kazuph 🎙️ *Limitless 音声分析レポート*\n_${new Date().toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' })}_\n\n`

  return postToSlack(env, header + text)
}

export const postErrorToSlack = async (
  env: Bindings,
  error: Error | string,
  context?: string
): Promise<boolean> => {
  const errorMessage = error instanceof Error ? error.message : error
  const stack = error instanceof Error ? error.stack : undefined

  const timestamp = new Date().toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' })

  let text = `🚨 *Cron処理エラー*\n_${timestamp}_\n\n`

  if (context) {
    text += `*処理:* ${context}\n`
  }

  text += `*エラー:* \`${errorMessage}\`\n`

  if (stack) {
    // スタックトレースは長いので最初の5行だけ
    const stackLines = stack.split('\n').slice(0, 5).join('\n')
    text += `\n\`\`\`\n${stackLines}\n\`\`\``
  }

  return postToSlack(env, text)
}

export const postWarningToSlack = async (
  env: Bindings,
  message: string,
  context?: string
): Promise<boolean> => {
  const timestamp = new Date().toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' })
  const header = `⚠️ *同期観測*\n_${timestamp}_\n\n`
  const body = context ? `*処理:* ${context}\n` : ''
  return postToSlack(env, `${header}${body}${message}`)
}
