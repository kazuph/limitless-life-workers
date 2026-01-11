import type { Next, Context } from 'hono'
import type { Env } from '../env'
// @ts-ignore - MoonBit generated module
import { ensure_schema } from '../../target/js/release/build/server/server.js'

export const withDb = () => async (c: Context<Env>, next: Next) => {
  await ensure_schema(c.env.LIFELOG_DB)
  await next()
}
