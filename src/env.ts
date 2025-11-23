import type { Ai, RateLimit } from '@cloudflare/workers-types/experimental'
import type { Database } from './db/client'

export type Bindings = {
  LIFELOG_DB: D1Database
  LIMITLESS_API_KEY: string
  BASIC_USER: string
  BASIC_PASS: string
  AI: Ai
  RATE_LIMITER?: RateLimit
  DISABLE_LIMITLESS_SYNC?: string
  DISABLE_WORKERS_AI?: string
  GEMINI_API_KEY?: string
  SLACK_BOT_TOKEN?: string
  SLACK_CHANNEL?: string
}

export type Variables = {
  db: Database
}

export type Env = {
  Bindings: Bindings
  Variables: Variables
}
