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
        <div key={date} className="max-h-[600px] rounded-xl border-2 border-border bg-card/50 overflow-hidden flex flex-col">
          {/* Card header with date and entry count - 縦スクロール対象外 */}
          <div className="border-b border-border/40 bg-card/95 px-6 py-4 dark:bg-background/95 flex-shrink-0">
            <div className="flex items-center gap-3">
              <span className="text-lg font-bold text-foreground">{date}</span>
              <span className="rounded-md border border-border bg-muted px-3 py-1.5 text-xs font-medium text-muted-foreground">
                {items.length} {items.length === 1 ? 'entry' : 'entries'}
              </span>
            </div>
          </div>

          {/* Hour labels - 縦スクロール対象外、横スクロール可能 */}
          <ScrollArea
            className="flex-shrink-0 w-full [&_[data-radix-scroll-area-viewport]]:overflow-x-auto [&_[data-radix-scroll-area-viewport]]:overflow-y-hidden"
          >
            <div className="min-w-full xl:min-w-[1600px] 2xl:min-w-[1900px]">
              <div className="flex border-b border-border/20 pb-2 pt-2 bg-card/95 dark:bg-background/95">
                <div className="sticky left-0 z-10 w-64 flex-shrink-0 bg-card/95 py-1 pr-4 dark:bg-background/95" />
                <div className="flex flex-1">
                  {HOURS.map((hour) => (
                    <div
                      key={hour}
                      className="flex-1 text-center text-[10px] font-medium uppercase tracking-wider text-muted-foreground"
                    >
                      {hour.toString().padStart(2, '0')}
                    </div>
                  ))}
                </div>
              </div>
            </div>
            <ScrollBar orientation="horizontal" />
          </ScrollArea>

          {/* Timeline entries - 縦スクロール可能、横スクロール可能（エントリ情報は固定） */}
          <ScrollArea
            className="flex-1 w-full [&_[data-radix-scroll-area-viewport]]:overflow-x-auto"
          >
            <div className="min-w-full xl:min-w-[1600px] 2xl:min-w-[1900px] relative">
              {/* Background grid lines */}
              <div className="absolute inset-0 flex pointer-events-none z-0">
                <div className="w-64 flex-shrink-0" />
                <div className="flex flex-1">
                  {HOURS.map((hour) => (
                    <div
                      key={hour}
                      className="flex-1 border-l border-gray-200 dark:border-gray-700 first:border-l-0"
                    />
                  ))}
                </div>
              </div>

              <div className="relative px-6 py-1 z-10">
                {items.map((entry) => (
                  <TimelineRow
                    key={entry.id}
                    entry={entry}
                  />
                ))}
              </div>
            </div>
            <ScrollBar orientation="horizontal" />
          </ScrollArea>
        </div>
      ))}
    </div>
  )
}

type TimelineRowProps = {
  entry: TimelineEntry
}

const TimelineRow: React.FC<TimelineRowProps> = ({ entry }) => {
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

  const charCount = React.useMemo(() => {
    const allContent = entry.segments
      ?.map((segment) => segment.content?.trim())
      .filter((text): text is string => Boolean(text && text.length > 0))
      .join('') ?? ''
    return allContent.length
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
    <div className="flex items-start gap-2">
      {/* Entry info */}
      <div className="sticky left-0 z-20 w-64 flex-shrink-0 py-0.5 pr-4 backdrop-blur-sm bg-card/95 dark:bg-background/95 border-r border-border/60">
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

      {/* Timeline bar */}
      <div className="relative flex flex-1 h-10">
        {/* Timeline segments */}
        <div className="relative h-full w-full flex items-center">
          {segments.map((segment, idx) => (
            <Tooltip delayDuration={50} key={segment.id || idx}>
              <TooltipTrigger asChild>
                <div
                  className="absolute h-6 rounded-lg bg-purple-500 hover:bg-purple-600 pointer-events-auto transition-colors z-0"
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
