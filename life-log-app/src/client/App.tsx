import * as React from 'react'
import { useQuery } from '@tanstack/react-query'
import { fetchTimeline, triggerSync } from './api'
import { TimelineBoard } from './components/timeline-board'
import { InsightsGrid } from './components/insights-grid'
import type { TimelineResponse } from './types'
import { Button } from './components/ui/button'
import { Card, CardContent } from './components/ui/card'
import { TooltipProvider } from './components/ui/tooltip'
import { Separator } from './components/ui/separator'

const formatTimestamp = (value?: string | null) => {
  if (!value) return '---'
  return new Date(value).toLocaleString()
}

export const App: React.FC = () => {
  const [syncing, setSyncing] = React.useState(false)
  const { data, error, isLoading, refetch, isFetching } = useQuery<TimelineResponse>({
    queryKey: ['timeline'],
    queryFn: fetchTimeline,
    refetchInterval: 60_000
  })

  const handleSync = async () => {
    setSyncing(true)
    try {
      await triggerSync()
      await refetch()
    } finally {
      setSyncing(false)
    }
  }

  const state = data ?? {
    lastSyncedAt: null,
    lastAnalyzedAt: null,
    timeline: [],
    integrations: []
  }

  return (
    <TooltipProvider>
      <div className="mx-auto flex max-w-7xl flex-col gap-12 px-8 py-12">
        <header className="flex flex-col gap-6">
          <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <div className="space-y-2">
              <h1 className="text-4xl font-bold tracking-tight text-foreground">
                Limitless Life Log
              </h1>
              <p className="text-sm uppercase tracking-[0.3em] text-muted-foreground/80">
                Activity Timeline
              </p>
            </div>
            <div className="flex flex-col items-end gap-2">
              <div className="flex items-center gap-3">
                <Button
                  variant="outline"
                  onClick={() => refetch()}
                  disabled={isFetching}
                  className="min-w-[100px] border-2 hover:border-foreground/40"
                >
                  {isFetching ? 'Loading...' : 'Refresh'}
                </Button>
                <Button
                  onClick={handleSync}
                  disabled={syncing}
                  className="min-w-[120px] bg-foreground text-background hover:bg-foreground/90"
                >
                  {syncing ? 'Syncing…' : 'Manual Sync'}
                </Button>
              </div>
              <div className="flex items-center gap-4 text-xs text-muted-foreground/70">
                <span>Last sync: {formatTimestamp(state.lastSyncedAt)}</span>
                <span>•</span>
                <span>Last analysis: {formatTimestamp(state.lastAnalyzedAt)}</span>
              </div>
            </div>
          </div>
          <Separator className="bg-border/60" />
        </header>

        {error ? (
          <Card>
            <CardContent className="py-6 text-center text-red-400">
              {error instanceof Error ? error.message : 'Failed to load data'}
            </CardContent>
          </Card>
        ) : (
          <>
            <section className="space-y-6">
              <div>
                <h2 className="text-2xl font-bold tracking-tight text-foreground">Timeline</h2>
                <p className="mt-1 text-xs uppercase tracking-[0.3em] text-muted-foreground/60">
                  Activity Log
                </p>
              </div>
              {isLoading && !state.timeline.length ? (
                <SkeletonPlaceholder />
              ) : (
                <TimelineBoard
                  entries={state.timeline}
                />
              )}
            </section>

            <Separator className="my-4 bg-border/40" />

            <section className="space-y-6">
              <div className="flex items-end justify-between">
                <div>
                  <h2 className="text-2xl font-bold tracking-tight text-foreground">AI Insights</h2>
                  <p className="mt-1 text-xs uppercase tracking-[0.3em] text-muted-foreground/60">
                    Intelligent Suggestions
                  </p>
                </div>
                <span className="text-xs text-muted-foreground/50">
                  Workers AI gpt-oss-20b
                </span>
              </div>
              <InsightsGrid entries={state.timeline} />
            </section>

          </>
        )}
      </div>
    </TooltipProvider>
  )
}

const SkeletonPlaceholder = () => (
  <div className="animate-pulse space-y-4 rounded-xl border border-border/40 p-6 text-muted-foreground">
    <div className="h-6 w-1/3 rounded bg-muted/40" />
    <div className="h-[420px] rounded-xl border border-dashed border-muted/40" />
  </div>
)
