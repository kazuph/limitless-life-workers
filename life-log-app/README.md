# Life Log Cloudflare Worker

Cloudflare Workers + Hono application that:

- pulls Limitless lifelogs via the official API,
- stores normalized entries + transcript segments in D1 through Drizzle ORM,
- summarizes each entry with Workers AI `@cf/openai/gpt-oss-120b`,
- renders a monochrome shadcn/ui timeline dashboard on Workers Sites,
- exposes integration proposals (Google Calendar, Gmail, Slack, GitHub, Obsidian, Zenn).

## Prerequisites

1. `wrangler` >= 4.17
2. Cloudflare D1 database
3. `LIMITLESS_API_KEY`, `BASIC_USER`, `BASIC_PASS` stored locally in `.dev.vars`
4. Workers AI binding named `AI`

### Environment bindings

`wrangler.jsonc`

```jsonc
{
  "d1_databases": [
    {
      "binding": "LIFELOG_DB",
      "database_name": "life_log_app",
      "database_id": "<replace-with-your-d1-id>"
    }
  ],
  "ai": {
    "binding": "AI"
  }
}
```

`.dev.vars`

```
LIMITLESS_API_KEY=sk-***
BASIC_USER=<username>
BASIC_PASS=<password>
```

For production, add the same secrets with `wrangler secret put`.

## Install & develop

```bash
npm install
npm run dev
```

The dev server applies HTTP Basic authentication using the credentials above.

## Build & deploy

```bash
npm run build
npm run deploy
```

`vite build` emits a Worker bundle plus client assets (React + shadcn/ui).

## Database & Drizzle

The schema lives in `src/db/schema.ts`. Drizzle connects to D1 through `drizzle-orm/d1`.

| table | description |
| ----- | ----------- |
| `lifelog_entries` | base metadata for each Limitless entry |
| `lifelog_segments` | flattened `ContentNode` rows for fast timeline rendering |
| `lifelog_analyses` | JSON payload returned by Workers AI |
| `sync_state` | KV-style timestamps for sync + analysis freshness |

`drizzle.config.ts` expects three environment variables to use the D1 HTTP API:

```
CF_ACCOUNT_ID=<cf account>
CF_D1_DATABASE_ID=<d1 id>
CF_D1_API_TOKEN=<api token with D1 edit scope>
```

Commands:

```bash
npm run db:push     # push the schema to D1
npm run db:studio   # open Drizzle Studio
```

## Sync + AI analysis flow

1. `/api/lifelogs` calls `ensureFreshData` which triggers `syncLifelogs` if the last sync is older than 60 minutes.
2. `syncLifelogs` fetches `/v1/lifelogs` with `X-API-KEY`, upserts entries + segments, and updates `sync_state`.
3. `analyzeFreshEntries` calls Workers AI `@cf/openai/gpt-oss-120b` citeturn0search0 with a JSON schema, storing the structured insights back into `lifelog_analyses`.
4. A scheduled cron (`0 * * * *`) repeats the same sync + analysis hourly even without user traffic.

Workers AI output is JSON (summary, mood, time blocks, action items, integration hints) and feeds both the timeline hover tooltips and the insights cards rendered on the dashboard.

## Frontend

- Pure React + shadcn/ui (button, card, badge, scroll-area, tooltip, separator)
- Tailwind (monochrome tokens defined in `src/client/globals.css`)
- Timeline board (`TimelineBoard`) shows days as rows, hours on the X axis, and transcript segments as Gantt bars with tooltips.
- Insights grid lists AI-derived action items.
- Integration grid highlights next-step automations.

The React entry point lives in `src/client/main.tsx`. Assets are injected via `<script type="module" src="/src/client/main.tsx" />` inside the Hono renderer.

## API surface

| method | route | purpose |
| ------ | ----- | ------- |
| `GET` | `/` | SSR shell + React dashboard |
| `GET` | `/api/lifelogs` | returns timeline data, analyses, integration hints |
| `POST` | `/api/sync` | manual sync trigger (Basic Auth protected) |
| `GET` | `/api/health` | returns last sync/analyze timestamps |

All routes (except the scheduled event) run through Basic Auth.

## Integration proposals

The UI (and `src/services/integrations.ts`) surfaces concrete suggestions for:

- Google Calendar auto-scheduling (lifelog → event draft)
- Gmail reply drafts (lifelog highlights → Gmail draft API)
- Slack thread replies (open loops → `chat.postMessage`)
- GitHub pull request scaffolding (dev-focused entries → PR template)
- Obsidian vault notes (`03_文献ノート` sync with Mermaid diagrams)
- Zenn publishing (weekly digest → `zenn-cli` article)

Use these hooks to fan out the AI insights into the rest of your productivity stack.
