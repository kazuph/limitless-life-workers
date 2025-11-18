import type { Next } from 'hono'
import type { Context } from 'hono'
import { getDb } from '../db/client'
import { ensureSchema } from '../db/schema-init'
import type { Env } from '../env'

export const withDb = () => async (c: Context<Env>, next: Next) => {
  await ensureSchema(c.env.LIFELOG_DB)
  if (!c.get('db')) {
    c.set('db', getDb(c.env.LIFELOG_DB))
  }
  await next()
}
