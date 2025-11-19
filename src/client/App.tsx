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
  const [offset, setOffset] = React.useState(0)
  const [allEntries, setAllEntries] = React.useState<TimelineResponse['timeline']>([])
  const [loadingMore, setLoadingMore] = React.useState(false)

  const { data, error, isLoading, refetch } = useQuery<TimelineResponse>({
    queryKey: ['timeline', offset],
    queryFn: () => fetchTimeline({ days: 7, offset }),
    refetchInterval: offset === 0 ? 60_000 : false
  })

  React.useEffect(() => {
    if (data) {
      if (offset === 0) {
        setAllEntries(data.timeline)
      } else {
        setAllEntries((prev) => [...prev, ...data.timeline])
      }
    }
  }, [data, offset])

  const handleSync = async () => {
    setSyncing(true)
    try {
      await triggerSync()
      setOffset(0)
      setAllEntries([])
      await refetch()
    } finally {
      setSyncing(false)
    }
  }

  const handleLoadMore = async () => {
    setLoadingMore(true)
    setOffset((prev) => prev + 7)
    setLoadingMore(false)
  }

  const state = data ?? {
    lastSyncedAt: null,
    lastAnalyzedAt: null,
    timeline: [],
    integrations: []
  }

  const hasMore = data?.timeline && data.timeline.length > 0

  return (
    <TooltipProvider>
      <div className="mx-auto flex w-full max-w-[90rem] flex-col gap-12 px-6 py-12 lg:px-12 xl:max-w-[105rem] 2xl:max-w-[115rem]">
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
              <Button
                onClick={handleSync}
                disabled={syncing}
                className="bg-foreground text-background hover:bg-foreground/90"
              >
                {syncing ? 'Requesting…' : 'Request Limitless API'}
              </Button>
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
              {isLoading && !allEntries.length ? (
                <SkeletonPlaceholder />
              ) : (
                <>
                  <TimelineBoard
                    entries={allEntries}
                  />
                  {hasMore && (
                    <div className="flex justify-center pt-6">
                      <Button
                        onClick={handleLoadMore}
                        disabled={loadingMore || isLoading}
                        variant="outline"
                        className="min-w-[200px]"
                      >
                        {loadingMore || isLoading ? 'Loading...' : 'Read More'}
                      </Button>
                    </div>
                  )}
                </>
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
              <InsightsGrid entries={allEntries} />
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
