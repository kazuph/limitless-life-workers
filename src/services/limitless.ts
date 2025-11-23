import type { Bindings } from '../env'
import type { LimitlessResponse } from '../types/limitless'

const API_BASE = 'https://api.limitless.ai/v1/'
const MAX_RETRIES = 3
const RETRY_BASE_DELAY_MS = 1000

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

const shouldRetryStatus = (status?: number) =>
  typeof status === 'number' && status >= 500 && status < 600

export type FetchLifelogsOptions = {
  cursor?: string
  start?: string
  end?: string
  limit?: number
  timezone?: string
}

export const fetchLifelogs = async (
  env: Bindings,
  options: FetchLifelogsOptions = {}
): Promise<LimitlessResponse> => {
  if (!env.LIMITLESS_API_KEY) {
    throw new Error('Missing LIMITLESS_API_KEY')
  }

  const url = new URL('lifelogs', API_BASE)
  if (options.cursor) url.searchParams.set('cursor', options.cursor)
  if (options.start) url.searchParams.set('start', options.start)
  if (options.end) url.searchParams.set('end', options.end)
  if (options.limit) url.searchParams.set('limit', String(options.limit))
  if (options.timezone) url.searchParams.set('timezone', options.timezone)
  url.searchParams.set('includeMarkdown', 'true')
  url.searchParams.set('includeHeadings', 'true')
  url.searchParams.set('includeContents', 'true')
  url.searchParams.set('direction', 'desc')

  console.log('[Limitless] Fetching', url.toString())

  let lastError: Error | null = null

  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    const delay = RETRY_BASE_DELAY_MS * Math.pow(2, attempt)
    try {
      const response = await fetch(url, {
        headers: {
          'X-API-KEY': env.LIMITLESS_API_KEY,
          'Content-Type': 'application/json'
        }
      })

      if (!response.ok) {
        const message = await response.text()
        const error = new Error(`Limitless API error: ${response.status} ${message}`)
        lastError = error
        if (!shouldRetryStatus(response.status) || attempt === MAX_RETRIES - 1) {
          throw error
        }
        console.warn(`[Limitless] attempt ${attempt + 1} failed with status ${response.status}; retrying in ${delay}ms`)
        await sleep(delay)
        continue
      }

      const json = (await response.json()) as LimitlessResponse
      if (json.data?.lifelogs?.length > 0) {
        const sample = json.data.lifelogs[0]
        console.log(`[Limitless] Sample lifelog: id=${sample.id}, title="${sample.title}", contents=${sample.contents?.length || 0}`)
        console.log('[Limitless] Raw sample keys:', Object.keys(sample).join(', '))
        if (sample.contents && sample.contents.length > 0) {
          console.log('[Limitless] Sample content node:', JSON.stringify(sample.contents[0], null, 2))
        } else {
          console.log('[Limitless] NO CONTENTS IN RESPONSE! Raw sample:', JSON.stringify(sample).slice(0, 500))
        }
      }
      return json
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error))
      if (attempt === MAX_RETRIES - 1) {
        throw lastError
      }
      console.warn(`[Limitless] attempt ${attempt + 1} threw error: ${lastError.message}; retrying in ${delay}ms`)
      await sleep(delay)
    }
  }

  throw lastError ?? new Error('Limitless API error: unknown failure')
}
