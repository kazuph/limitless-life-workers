import * as React from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type { DaySummary, TimelineEntry, TimelineSegment } from '../types'
import { fetchDaySummary, fetchTimelineEntry, regenerateDaySummary, triggerAnalysis } from '../api'
import { formatDateLabel, toLocaleTime } from '../lib/utils'
import { Tooltip, TooltipContent, TooltipTrigger } from './ui/tooltip'
import * as TooltipPrimitive from '@radix-ui/react-tooltip'
import { Button } from './ui/button'

type RenderedSegment = TimelineSegment & {
  left: string
  width: string
}

type RawLogLine = {
  text: string
  timeLabel?: string | null
}

type Props = {
  entries: TimelineEntry[]
}

const HOURS = Array.from({ length: 24 }).map((_, index) => index)

export const TimelineBoard: React.FC<Props> = ({ entries }) => {
  const grouped = React.useMemo(() => groupByDate(entries), [entries])
  const [selectedEntryId, setSelectedEntryId] = React.useState<string | null>(null)

  const openDetails = React.useCallback((entryId: string) => {
    setSelectedEntryId(entryId)
  }, [])

  const closeDetails = React.useCallback(() => {
    setSelectedEntryId(null)
  }, [])

  if (!entries.length) {
    return (
      <div className="rounded-xl border border-dashed border-border p-8 text-center text-muted-foreground">
        ライフログがまだ保存されていません。先に同期してください。
      </div>
    )
  }

  return (
    <>
      <div className="space-y-6">
        {grouped.map(({ date, items }) => (
          <TimelineGroup key={date} date={date} items={items} onOpenDetails={openDetails} />
        ))}
      </div>
      <EntryDetailsDrawer entryId={selectedEntryId} onClose={closeDetails} />
    </>
  )
}

type TimelineGroupProps = {
  date: string
  items: TimelineEntry[]
  onOpenDetails: (entryId: string) => void
}

const TimelineGroup: React.FC<TimelineGroupProps> = ({ date, items, onOpenDetails }) => {
  const leftScrollRef = React.useRef<HTMLDivElement>(null)
  const rightScrollRef = React.useRef<HTMLDivElement>(null)
  const entryRefs = React.useRef<Map<string, HTMLDivElement>>(new Map())
  const headerRef = React.useRef<HTMLDivElement>(null)
  const queryClient = useQueryClient()
  const [isSyncing, setIsSyncing] = React.useState(false)
  const [isAutoScrolling, setIsAutoScrolling] = React.useState(false)
  const observerOptions = React.useMemo(() => ({ rootMargin: '200px' }), [])
  const isHeaderVisible = useInView(headerRef, observerOptions)

  const { data: daySummary, isLoading: summaryLoading } = useQuery<DaySummary>({
    queryKey: ['day-summary', date],
    queryFn: () => fetchDaySummary(date),
    enabled: isHeaderVisible,
    staleTime: 6 * 60 * 60 * 1000,
    refetchOnWindowFocus: false
  })

  const regenerateSummary = useMutation({
    mutationFn: (provider: 'openai' | 'gemini') => regenerateDaySummary(date, provider),
    onSuccess: (data) => {
      queryClient.setQueryData(['day-summary', date], data)
    }
  })

  const syncScroll = (source: 'left' | 'right') => {
    if (isSyncing) return
    setIsSyncing(true)

    const leftViewport = leftScrollRef.current
    const rightViewport = rightScrollRef.current

    if (leftViewport && rightViewport) {
      if (source === 'left') {
        rightViewport.scrollTop = leftViewport.scrollTop
      } else {
        leftViewport.scrollTop = rightViewport.scrollTop
      }
    }

    requestAnimationFrame(() => setIsSyncing(false))
  }

  // Calculate horizontal scroll position based on entry time
  const calculateHorizontalScroll = React.useCallback((entry: TimelineEntry): number => {
    if (!rightScrollRef.current || !entry.startTime) return 0

    const startDate = new Date(entry.startTime)
    const hours = startDate.getHours()
    const minutes = startDate.getMinutes()

    // Calculate the time position as a percentage of the day
    const timeInMinutes = hours * 60 + minutes
    const totalMinutesInDay = 24 * 60
    const timePercentage = timeInMinutes / totalMinutesInDay

    // Get the scroll container width and scrollable content width
    const container = rightScrollRef.current
    const scrollWidth = container.scrollWidth
    const clientWidth = container.clientWidth
    const maxScroll = scrollWidth - clientWidth

    // Calculate scroll position to center the entry time
    const targetScroll = (timePercentage * scrollWidth) - (clientWidth / 2)
    return Math.max(0, Math.min(targetScroll, maxScroll))
  }, [])

  // Find the currently visible entry based on vertical scroll position
  const findVisibleEntry = React.useCallback((): TimelineEntry | null => {
    if (!leftScrollRef.current) return null

    const container = leftScrollRef.current
    const scrollTop = container.scrollTop
    const containerTop = container.getBoundingClientRect().top

    // Find the entry closest to the top of the viewport
    let closestEntry: TimelineEntry | null = null
    let closestDistance = Infinity

    items.forEach((entry) => {
      const element = entryRefs.current.get(entry.id)
      if (!element) return

      const rect = element.getBoundingClientRect()
      const entryTop = rect.top - containerTop + scrollTop
      const distance = Math.abs(entryTop - scrollTop)

      if (distance < closestDistance) {
        closestDistance = distance
        closestEntry = entry
      }
    })

    return closestEntry
  }, [items])

  // Auto-scroll to latest entry time on mount
  React.useEffect(() => {
    if (!rightScrollRef.current || !items.length) return

    const latestEntry = items[0]
    const initialScroll = calculateHorizontalScroll(latestEntry)
    rightScrollRef.current.scrollLeft = initialScroll
  }, [items, calculateHorizontalScroll])

  // Set up vertical scroll listener with smooth real-time horizontal scroll
  React.useEffect(() => {
    const leftContainer = leftScrollRef.current
    const rightContainer = rightScrollRef.current
    if (!leftContainer || !rightContainer) return

    let rafId: number | null = null

    const syncHorizontalScroll = () => {
      if (rafId !== null) return
      if (isAutoScrolling) return

      rafId = requestAnimationFrame(() => {
        const visibleEntry = findVisibleEntry()
        if (visibleEntry && rightScrollRef.current) {
          const targetScrollLeft = calculateHorizontalScroll(visibleEntry)

          // Use instant scroll (no 'smooth' behavior) for real-time syncing
          rightScrollRef.current.scrollLeft = targetScrollLeft
        }
        rafId = null
      })
    }

    // Listen to both containers for scroll events
    leftContainer.addEventListener('scroll', syncHorizontalScroll, { passive: true })
    rightContainer.addEventListener('scroll', syncHorizontalScroll, { passive: true })

    return () => {
      leftContainer.removeEventListener('scroll', syncHorizontalScroll)
      rightContainer.removeEventListener('scroll', syncHorizontalScroll)
      if (rafId !== null) {
        cancelAnimationFrame(rafId)
      }
    }
  }, [calculateHorizontalScroll, findVisibleEntry, isAutoScrolling])


  return (
    <div className="max-h-[700px] rounded-xl border-2 border-border bg-card/50 overflow-hidden flex flex-col">
      {/* Card header with date, entry count, and tweet summaries - compact */}
      <div
        ref={headerRef}
        className="border-b border-border/40 bg-card/95 px-6 py-3 dark:bg-background/95 flex-shrink-0"
      >
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <span className="text-lg font-bold text-foreground">{date}</span>
            <span className="rounded-md border border-border bg-muted px-3 py-1.5 text-xs font-medium text-muted-foreground">
              {items.length} {items.length === 1 ? 'entry' : 'entries'}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              aria-label="GPT-OSS-120Bで日次ツイートを再生成"
              title="GPT-OSS-120Bで日次ツイートを再生成"
              onClick={() => regenerateSummary.mutate('openai')}
              className="inline-flex h-8 w-8 items-center justify-center rounded-full border border-border/60 bg-background/90 shadow-sm transition hover:bg-muted/40 disabled:opacity-60"
              disabled={regenerateSummary.isPending}
            >
              <img
                src="/images/openai-icon.svg"
                alt="GPT-OSS"
                className="h-4 w-4 rounded-full"
                loading="lazy"
              />
            </button>
            <button
              type="button"
              aria-label="Gemini 2.0 Flashで日次ツイートを再生成"
              title="Gemini 2.0 Flashで日次ツイートを再生成"
              onClick={() => regenerateSummary.mutate('gemini')}
              className="inline-flex h-8 w-8 items-center justify-center rounded-full border border-border/60 bg-background/90 shadow-sm transition hover:bg-muted/40 disabled:opacity-60"
              disabled={regenerateSummary.isPending}
            >
              <img
                src="/images/gemini-icon.svg"
                alt="Gemini"
                className="h-4 w-4 rounded-full"
                loading="lazy"
              />
            </button>
          </div>
        </div>
        {daySummary?.tweets?.length ? (
          <div className="relative mt-3">
            {/* 2-column grid with horizontal scroll */}
            <div className="overflow-x-auto pb-2 scrollbar-thin scrollbar-thumb-border scrollbar-track-transparent">
              <div className="grid grid-rows-2 grid-flow-col gap-2 w-max">
                {daySummary.tweets.map((tweet, index) => (
                  <div
                    key={`${date}-tweet-${index}`}
                    className="flex items-start gap-2 rounded-lg border border-border/50 bg-background/80 px-3 py-2 shadow-sm w-[280px]"
                  >
                    <img
                      src="/images/kazuph-avatar.png"
                      alt="Kazuph avatar"
                      className="h-6 w-6 rounded-full object-cover border border-border/40 flex-shrink-0"
                      loading="lazy"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground">
                        <span className="text-foreground/90 font-medium">Daily Memo</span>
                        <span className="text-muted-foreground/70">@kazuph</span>
                        <span className="ml-auto">{tweet.time || ''}</span>
                      </div>
                      <p className="text-xs leading-snug text-foreground/90 whitespace-pre-wrap mt-0.5">
                        {tweet.text}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ) : summaryLoading ? (
          <p className="mt-2 text-xs text-muted-foreground/70">サマリー生成中...</p>
        ) : null}
      </div>

      {/* 2-column layout: fixed left column + scrollable right column */}
      <div className="flex flex-1 min-h-0">
        {/* Left column: Entry info (fixed, vertical scroll only) */}
        <div className="w-64 flex-shrink-0 flex flex-col border-r border-border/60">
          {/* Empty space for hour labels alignment */}
          <div className="flex-shrink-0 h-[36px] border-b border-border/20 bg-card/95 dark:bg-background/95" />

          {/* Entry list (vertical scroll) */}
          <div
            ref={leftScrollRef}
            className="flex-1 overflow-y-auto overflow-x-hidden"
            onScroll={() => syncScroll('left')}
          >
            <div className="py-1">
              {items.map((entry) => (
                <TimelineEntryInfo
                  key={entry.id}
                  entry={entry}
                  onOpenDetails={onOpenDetails}
                  ref={(el) => {
                    if (el) {
                      entryRefs.current.set(entry.id, el)
                    } else {
                      entryRefs.current.delete(entry.id)
                    }
                  }}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Right column: Timeline chart (horizontal + vertical scroll) */}
        <div className="flex-1 flex flex-col min-w-0">
          {/* Combined hour labels + timeline bars (horizontal + vertical scroll) */}
          <div
            ref={rightScrollRef}
            className="flex-1 overflow-auto"
            onScroll={() => syncScroll('right')}
          >
            <div className="min-w-full xl:min-w-[1600px] 2xl:min-w-[1900px]">
              {/* Hour labels (sticky header) */}
              <div className="sticky top-0 z-20 flex border-b border-border/20 pb-2 pt-2 bg-card/95 dark:bg-background/95 h-[36px]">
                {HOURS.map((hour) => (
                  <div
                    key={hour}
                    className="flex-1 text-center text-[10px] font-medium uppercase tracking-wider text-muted-foreground"
                  >
                    {hour.toString().padStart(2, '0')}
                  </div>
                ))}
              </div>

              {/* Timeline bars with background grid */}
              <div className="relative">
                {/* Background grid lines */}
                <div className="absolute inset-0 flex pointer-events-none z-0">
                  {HOURS.map((hour) => (
                    <div
                      key={hour}
                      className="flex-1 border-l border-gray-200 dark:border-gray-700 first:border-l-0"
                    />
                  ))}
                </div>

                <div className="relative py-1 z-10">
                  {items.map((entry) => (
                    <TimelineBar key={entry.id} entry={entry} onOpenDetails={onOpenDetails} />
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

type TimelineEntryInfoProps = {
  entry: TimelineEntry
  onOpenDetails: (entryId: string) => void
}

const TimelineEntryInfo = React.forwardRef<HTMLDivElement, TimelineEntryInfoProps>(
  ({ entry, onOpenDetails }, ref) => {
  const charCount = React.useMemo(() => {
    const allContent = entry.segments
      ?.map((segment) => segment.content?.trim())
      .filter((text): text is string => Boolean(text && text.length > 0))
      .join('') ?? ''
    return allContent.length
  }, [entry])
  const metricLabel = charCount > 0
    ? `${charCount.toLocaleString()}文字`
    : entry.segments.length > 0
    ? `${entry.segments.length}セグメント`
    : entry.durationMinutes
    ? `${entry.durationMinutes}分`
    : '—'

  // Build logs for tooltip display
  const segmentLogs = React.useMemo(() => {
    if (!entry.segments || entry.segments.length === 0) return []
    return entry.segments
      .map((segment) => {
        const text = segment.content?.trim()
        if (!text) return null
        return {
          text,
          timeLabel: segment.startTime ? toLocaleTime(segment.startTime) : null
        }
      })
      .filter((log): log is { text: string; timeLabel: string | null } => log !== null)
      .slice(0, 10) // Show first 10 logs in tooltip
  }, [entry.segments])

  return (
    <div
      ref={ref}
      className="px-6 py-0.5 cursor-pointer hover:bg-muted/30 transition-colors"
      onMouseEnter={() => onOpenDetails(entry.id)}
    >
      <div className="flex items-center justify-between">
        <span className="text-xs text-muted-foreground">{toLocaleTime(entry.startTime)} - {toLocaleTime(entry.endTime)}</span>
        <span className="text-xs text-muted-foreground">{metricLabel}</span>
      </div>
      <div className="mt-0.5 flex items-center gap-1.5">
        <p className="text-sm font-semibold text-foreground">{entry.title}</p>
        {entry.analysis?.mood && (
          <span className="text-xs text-muted-foreground whitespace-nowrap">{entry.analysis.mood}</span>
        )}
      </div>
    </div>
  )
})

TimelineEntryInfo.displayName = 'TimelineEntryInfo'

type TimelineBarProps = {
  entry: TimelineEntry
  onOpenDetails: (entryId: string) => void
}

const TimelineBar: React.FC<TimelineBarProps> = ({ entry, onOpenDetails }) => {
  const segments = React.useMemo<RenderedSegment[]>(() => {
    // If no segments exist, create a single segment from entry times
    if (!entry.segments || entry.segments.length === 0) {
      const midnight = entry.startTime ? startOfDay(entry.startTime) : new Date()
      const fakeSegment: TimelineSegment = {
        id: entry.id,
        content: entry.title || 'Activity',
        startTime: entry.startTime,
        endTime: entry.endTime,
        nodeType: null,
        speakerName: null
      }
      const { left, width } = computeBand(fakeSegment, entry, midnight)
      return [{
        ...fakeSegment,
        left: `${left}%`,
        width: `${width}%`
      }]
    }
    const rendered = renderSegments(entry)

    // If all segments were invalid, fallback to a single bar
    if (rendered.length === 0) {
      const midnight = entry.startTime ? startOfDay(entry.startTime) : new Date()
      const fakeSegment: TimelineSegment = {
        id: entry.id,
        content: entry.title || 'Activity',
        startTime: entry.startTime,
        endTime: entry.endTime,
        nodeType: null,
        speakerName: null
      }
      const { left, width } = computeBand(fakeSegment, entry, midnight)
      return [{
        ...fakeSegment,
        left: `${left}%`,
        width: `${width}%`
      }]
    }

    return rendered
  }, [entry])
  const analysisSummary = entry.analysis?.summary?.trim()

  // Build logs for tooltip display
  const segmentLogs = React.useMemo(() => {
    if (!entry.segments || entry.segments.length === 0) return []
    return entry.segments
      .map((segment) => {
        const text = segment.content?.trim()
        if (!text) return null
        return {
          text,
          timeLabel: segment.startTime ? toLocaleTime(segment.startTime) : null
        }
      })
      .filter((log): log is { text: string; timeLabel: string | null } => log !== null)
      .slice(0, 10)
  }, [entry.segments])

  return (
    <div className="relative h-10 px-6">
      {/* Timeline segments */}
      <div className="relative h-full w-full flex items-center">
        {segments.map((segment, idx) => (
          <div
            key={segment.id || idx}
            className="absolute h-6 rounded-full bg-purple-500 hover:bg-purple-600 pointer-events-auto transition-colors z-0 cursor-pointer"
            data-testid="timeline-bar"
            style={{
              left: segment.left,
              width: segment.width,
              minWidth: '8px',
              top: '50%',
              transform: 'translateY(-50%)'
            }}
            onMouseEnter={() => onOpenDetails(entry.id)}
          />
        ))}
      </div>
    </div>
  )
}

type EntryDetailsDrawerProps = {
  entryId: string | null
  onClose: () => void
}

const EntryDetailsDrawer: React.FC<EntryDetailsDrawerProps> = ({ entryId, onClose }) => {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['timeline-entry', entryId],
    queryFn: () => fetchTimelineEntry(entryId as string),
    enabled: Boolean(entryId),
    staleTime: 5 * 60 * 1000
  })

  const analysisMutation = useMutation({
    mutationFn: () => triggerAnalysis(entryId as string),
    onSuccess: () => refetch()
  })

  const segmentLogs = React.useMemo(
    () => (data ? buildRawLogs(data) : []),
    [data]
  )
  const markdownBody = data?.markdown?.trim() ?? ''

  if (!entryId) return null

  return (
    <div className="fixed right-0 top-0 h-full z-[9999]">
      <div className="h-full w-full max-w-[540px] border-l border-border/60 bg-background shadow-2xl">
        <div className="flex items-center justify-between border-b border-border/40 px-6 py-4">
          <div className="space-y-1">
            <p className="text-xs uppercase tracking-[0.3em] text-muted-foreground/70">Entry Details</p>
            <h3 className="text-lg font-semibold text-foreground">{data?.title ?? 'Loading...'}</h3>
          </div>
          <Button variant="ghost" size="sm" onClick={onClose}>
            閉じる
          </Button>
        </div>

        <div className="h-[calc(100%-64px)] overflow-y-auto px-6 py-5 space-y-6">
          {isLoading && (
            <div className="rounded-md border border-border/40 bg-muted/30 px-4 py-3 text-sm text-muted-foreground">
              詳細を読み込み中...
            </div>
          )}
          {error && (
            <div className="rounded-md border border-border/40 bg-red-500/10 px-4 py-3 text-sm text-red-400">
              詳細の取得に失敗しました。
            </div>
          )}

          {data && (
            <>
              <div className="space-y-2">
                <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">AI Summary</p>
                <p className="text-sm leading-relaxed text-foreground/90 whitespace-pre-wrap">
                  {data.analysis?.summary ?? 'AI Summaryはまだ生成されていません。'}
                </p>
                <div className="flex justify-end">
                  <button
                    type="button"
                    aria-label="AIサマリーを再生成"
                    onClick={() => analysisMutation.mutate()}
                    className="inline-flex h-8 w-8 items-center justify-center rounded-full border border-border/60 bg-background/90 shadow-sm transition hover:bg-muted/40 disabled:opacity-60"
                    disabled={analysisMutation.isPending}
                  >
                    <img
                      src="/images/openai-icon.svg"
                      alt="ChatGPT"
                      className="h-4 w-4 rounded-full"
                      loading="lazy"
                    />
                  </button>
                </div>
              </div>

              {data.analysis?.action_items?.length ? (
                <div className="space-y-2">
                  <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Action Items</p>
                  <ul className="space-y-2 text-sm text-foreground/90">
                    {data.analysis.action_items.map((item) => (
                      <li key={item.title} className="rounded-md border border-border/40 px-3 py-2">
                        <p>{item.title}</p>
                        {item.suggested_integration && (
                          <p className="text-[11px] uppercase tracking-wide text-muted-foreground">
                            → {item.suggested_integration}
                          </p>
                        )}
                      </li>
                    ))}
                  </ul>
                </div>
              ) : null}

              {data.analysis?.suggestions?.length ? (
                <div className="space-y-2">
                  <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Suggestions</p>
                  <ul className="space-y-1 text-sm text-foreground/90">
                    {data.analysis.suggestions.map((suggestion) => (
                      <li key={suggestion.target}>
                        {suggestion.target}: <span className="text-muted-foreground">{suggestion.rationale}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              ) : null}

              <div className="space-y-2">
                <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Logs</p>
                {segmentLogs.length > 0 ? (
                  <ul className="space-y-2 text-sm text-foreground/90">
                    {segmentLogs.map((log, idx) => (
                      <li key={idx} className="flex gap-3">
                        <span className="text-[11px] font-mono text-muted-foreground min-w-[52px]">
                          {log.timeLabel ?? '—'}
                        </span>
                        <span className="whitespace-pre-wrap">{log.text}</span>
                      </li>
                    ))}
                  </ul>
                ) : markdownBody ? (
                  <pre className="whitespace-pre-wrap rounded-md border border-border/40 bg-muted/20 p-3 text-sm text-foreground/90">
                    {markdownBody}
                  </pre>
                ) : (
                  <p className="text-sm text-muted-foreground">ログが見つかりませんでした。</p>
                )}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

const groupByDate = (entries: TimelineEntry[]) => {
  const map = new Map<string, TimelineEntry[]>()
  for (const entry of entries) {
    const label = entry.dateLabel ?? formatDateLabel(entry.startTime)
    if (!map.has(label)) {
      map.set(label, [])
    }
    map.get(label)!.push(entry)
  }
  return Array.from(map.entries()).map(([date, items]) => ({
    date,
    items
  }))
}

const renderSegments = (entry: TimelineEntry): RenderedSegment[] => {
  const midnight = entry.startTime ? startOfDay(entry.startTime) : new Date()

  return entry.segments
    .map((segment) => {
      const { left, width } = computeBand(segment, entry, midnight)
      // Skip segments with invalid dimensions
      if (width <= 0 || left < 0 || left > 100) {
        return null
      }

      return {
        ...segment,
        left: `${left}%`,
        width: `${Math.max(width, 0.5)}%` // Minimum 0.5% width
      }
    })
    .filter((seg): seg is RenderedSegment => seg !== null)
}

const computeBand = (
  segment: TimelineSegment,
  entry: TimelineEntry,
  midnight: Date
) => {
  const startDate = selectDate(segment.startTime, entry.startTime)
  const endDate = selectDate(segment.endTime, entry.endTime)
  const minutesPerDay = 24 * 60
  const startMinutes = percentageMinutes(startDate, midnight)
  const endMinutes = percentageMinutes(endDate, midnight)

  // Ensure valid time range
  if (Number.isNaN(startMinutes) || Number.isNaN(endMinutes)) {
    return { left: 0, width: 0 }
  }

  const duration = Math.max(endMinutes - startMinutes, 0.5)
  const left = clamp(startMinutes / minutesPerDay, 0, 1) * 100
  const width = clamp(duration / minutesPerDay, 0.01, 1) * 100

  return { left, width }
}

const buildRawLogs = (entry: TimelineEntry): RawLogLine[] => {
  if (entry.segments && entry.segments.length > 0) {
    return entry.segments
      .map((segment) => {
        const text = segment.content?.trim()
        if (!text) return null
        return {
          text,
          timeLabel: segment.startTime ? toLocaleTime(segment.startTime) : null
        }
      })
      .filter((line): line is RawLogLine => line !== null)
  }
  return []
}

const selectDate = (value?: string | null, fallback?: string | null) => {
  if (value) {
    const date = new Date(value)
    if (!Number.isNaN(date.getTime())) return date
  }
  if (fallback) {
    const fallbackDate = new Date(fallback)
    if (!Number.isNaN(fallbackDate.getTime())) return fallbackDate
  }
  return new Date()
}

const startOfDay = (value: string) => {
  const date = new Date(value)
  date.setHours(0, 0, 0, 0)
  return date
}

const percentageMinutes = (date: Date, midnight: Date) => {
  const diff = date.getTime() - midnight.getTime()
  return Math.max(diff / 60000, 0)
}

const clamp = (value: number, min: number, max: number) =>
  Math.min(Math.max(value, min), max)

const useInView = (
  ref: React.RefObject<Element>,
  options?: IntersectionObserverInit
) => {
  const [isInView, setIsInView] = React.useState(false)

  React.useEffect(() => {
    const node = ref.current
    if (!node || typeof IntersectionObserver === 'undefined') return

    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        setIsInView(true)
      }
    }, options)

    observer.observe(node)
    return () => observer.disconnect()
  }, [ref, options])

  return isInView
}
