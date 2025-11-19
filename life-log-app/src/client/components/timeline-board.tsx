import * as React from 'react'
import type { TimelineEntry, TimelineSegment } from '../types'
import { ScrollArea, ScrollBar } from './ui/scroll-area'
import { formatDateLabel, toLocaleTime } from '../lib/utils'
import { Tooltip, TooltipContent, TooltipTrigger } from './ui/tooltip'
import * as TooltipPrimitive from '@radix-ui/react-tooltip'

type RenderedSegment = TimelineSegment & {
  left: string
  width: string
  preview: string
  transcript: string
}

type Props = {
  entries: TimelineEntry[]
}

const HOURS = Array.from({ length: 24 }).map((_, index) => index)

export const TimelineBoard: React.FC<Props> = ({ entries }) => {
  const grouped = React.useMemo(() => groupByDate(entries), [entries])

  if (!entries.length) {
    return (
      <div className="rounded-xl border border-dashed border-border p-8 text-center text-muted-foreground">
        ライフログがまだ保存されていません。先に同期してください。
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {grouped.map(({ date, items }) => (
        <TimelineGroup key={date} date={date} items={items} />
      ))}
    </div>
  )
}

type TimelineGroupProps = {
  date: string
  items: TimelineEntry[]
}

const TimelineGroup: React.FC<TimelineGroupProps> = ({ date, items }) => {
  const leftScrollRef = React.useRef<HTMLDivElement>(null)
  const rightScrollRef = React.useRef<HTMLDivElement>(null)
  const entryRefs = React.useRef<Map<string, HTMLDivElement>>(new Map())
  const [isSyncing, setIsSyncing] = React.useState(false)
  const [isAutoScrolling, setIsAutoScrolling] = React.useState(false)

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
    <div className="max-h-[600px] rounded-xl border-2 border-border bg-card/50 overflow-hidden flex flex-col">
      {/* Card header with date and entry count */}
      <div className="border-b border-border/40 bg-card/95 px-6 py-4 dark:bg-background/95 flex-shrink-0">
        <div className="flex items-center gap-3">
          <span className="text-lg font-bold text-foreground">{date}</span>
          <span className="rounded-md border border-border bg-muted px-3 py-1.5 text-xs font-medium text-muted-foreground">
            {items.length} {items.length === 1 ? 'entry' : 'entries'}
          </span>
        </div>
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
                    <TimelineBar key={entry.id} entry={entry} />
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
}

const TimelineEntryInfo = React.forwardRef<HTMLDivElement, TimelineEntryInfoProps>(({ entry }, ref) => {
  const charCount = React.useMemo(() => {
    const allContent = entry.segments
      ?.map((segment) => segment.content?.trim())
      .filter((text): text is string => Boolean(text && text.length > 0))
      .join('') ?? ''
    return allContent.length
  }, [entry])

  return (
    <div ref={ref} className="px-6 py-0.5">
      <div className="flex items-center justify-between">
        <span className="text-xs text-muted-foreground">{toLocaleTime(entry.startTime)} - {toLocaleTime(entry.endTime)}</span>
        <span className="text-xs text-muted-foreground">{charCount.toLocaleString()}文字</span>
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
}

const TimelineBar: React.FC<TimelineBarProps> = ({ entry }) => {
  const entryTranscript = React.useMemo(() => {
    const pieces =
      entry.segments
        ?.map((segment) => segment.content?.trim())
        .filter((text): text is string => Boolean(text && text.length > 0)) ?? []
    if (pieces.length) return pieces.join('\n\n')
    if (entry.analysis?.summary) return entry.analysis.summary
    if (entry.analysis?.time_blocks?.length) {
      return entry.analysis.time_blocks
        .map((block) => `${block.label}: ${block.details ?? ''}`.trim())
        .join('\n')
    }
    return entry.markdown ?? entry.title ?? ''
  }, [entry])

  const segments = React.useMemo<RenderedSegment[]>(() => {
    console.log('Processing entry:', {
      id: entry.id,
      title: entry.title,
      startTime: entry.startTime,
      endTime: entry.endTime,
      segmentCount: entry.segments?.length || 0
    })

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
      console.log('Fake segment dimensions:', { left, width })
      return [{
        ...fakeSegment,
        preview: entry.title || 'Activity',
        left: `${left}%`,
        width: `${width}%`,
        transcript: entryTranscript
      }]
    }
    const rendered = renderSegments(entry, entryTranscript)
    console.log('Rendered segments:', rendered.length, rendered)

    // If all segments were invalid, fallback to a single bar
    if (rendered.length === 0) {
      console.warn('All segments invalid, falling back to entry-level bar')
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
      console.log('Fallback segment dimensions:', { left, width })
      return [{
        ...fakeSegment,
        preview: entry.title || 'Activity',
        left: `${left}%`,
        width: `${width}%`,
        transcript: entryTranscript
      }]
    }

    return rendered
  }, [entry, entryTranscript])

  return (
    <div className="relative h-10 px-6">
      {/* Timeline segments */}
      <div className="relative h-full w-full flex items-center">
        {segments.map((segment, idx) => (
          <Tooltip delayDuration={50} key={segment.id || idx}>
            <TooltipTrigger asChild>
              <div
                className="absolute h-6 rounded-full bg-purple-500 hover:bg-purple-600 pointer-events-auto transition-colors z-0"
                data-testid="timeline-bar"
                style={{
                  left: segment.left,
                  width: segment.width,
                  minWidth: '8px',
                  top: '50%',
                  transform: 'translateY(-50%)'
                }}
              />
            </TooltipTrigger>
            <TooltipPrimitive.Portal>
              <TooltipContent
                className="max-w-sm max-h-[360px] overflow-y-auto border-2 bg-popover text-left shadow-2xl"
                style={{ zIndex: 99999 }}
                side="left"
                align="start"
                avoidCollisions={false}
              >
              <p className="text-sm font-medium text-popover-foreground whitespace-pre-wrap leading-relaxed">
                {segment.transcript || segment.content || segment.preview}
              </p>
              {segment.nodeType && (
                <p className="mt-1 text-[10px] uppercase tracking-wider text-muted-foreground">
                  {segment.nodeType}
                </p>
              )}
              {segment.speakerName && (
                <p className="mt-1 text-[11px] text-muted-foreground">
                  Speaker: {segment.speakerName}
                </p>
              )}
              <p className="mt-1 text-[11px] text-muted-foreground">
                {toLocaleTime(segment.startTime)} - {toLocaleTime(segment.endTime)}
              </p>
            </TooltipContent>
            </TooltipPrimitive.Portal>
          </Tooltip>
        ))}
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

const renderSegments = (entry: TimelineEntry, transcript: string): RenderedSegment[] => {
  const midnight = entry.startTime ? startOfDay(entry.startTime) : new Date()

  console.log('Entry segments:', entry.segments.map(seg => ({
    id: seg.id,
    nodeType: seg.nodeType,
    contentLength: seg.content?.length || 0,
    contentPreview: seg.content?.slice(0, 50) || 'NO CONTENT',
    startTime: seg.startTime,
    endTime: seg.endTime
  })))

  return entry.segments
    .map((segment) => {
      const { left, width } = computeBand(segment, entry, midnight)
      // Skip segments with invalid dimensions
      if (width <= 0 || left < 0 || left > 100) {
        console.warn('Invalid segment dimensions:', { left, width, segment })
        return null
      }

      const preview = segment.content?.slice(0, 96) ?? segment.nodeType ?? 'segment'
      console.log('Segment preview:', {
        id: segment.id,
        preview: preview.slice(0, 50),
        hasContent: !!segment.content,
        contentLength: segment.content?.length
      })

      return {
        ...segment,
        left: `${left}%`,
        width: `${Math.max(width, 0.5)}%`, // Minimum 0.5% width
        preview,
        transcript
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
    console.warn('Invalid time calculation:', {
      segment,
      entry,
      startDate,
      endDate,
      startMinutes,
      endMinutes
    })
    return { left: 0, width: 0 }
  }

  const duration = Math.max(endMinutes - startMinutes, 0.5)
  const left = clamp(startMinutes / minutesPerDay, 0, 1) * 100
  const width = clamp(duration / minutesPerDay, 0.01, 1) * 100

  return { left, width }
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
