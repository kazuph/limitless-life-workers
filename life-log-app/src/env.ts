import type { Ai } from '@cloudflare/workers-types/experimental'
import type { Database } from './db/client'

export type Bindings = {
  LIFELOG_DB: D1Database
  LIMITLESS_API_KEY: string
  BASIC_USER: string
  BASIC_PASS: string
  AI: Ai
  DISABLE_LIMITLESS_SYNC?: string
  DISABLE_WORKERS_AI?: string
}

export type Variables = {
  db: Database
}

export type Env = {
  Bindings: Bindings
  Variables: Variables
}
