import * as React from 'react'
import type { TimelineEntry, TimelineSegment } from '../types'
import { ScrollArea } from './ui/scroll-area'
import { cn, formatDateLabel, toLocaleTime } from '../lib/utils'
import { Tooltip, TooltipContent, TooltipTrigger } from './ui/tooltip'
import { Badge } from './ui/badge'

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
    <ScrollArea className="h-[600px] rounded-xl border-2 border-border bg-card/50">
      <div className="min-w-[1200px] divide-y divide-border/40">
        {grouped.map(({ date, items }) => (
          <div key={date} className="px-6 py-6">
            <div className="mb-6 flex items-center justify-between">
              <span className="text-lg font-bold text-foreground">{date}</span>
              <span className="rounded-md border border-border bg-muted px-3 py-1.5 text-xs font-medium text-muted-foreground">
                {items.length} {items.length === 1 ? 'entry' : 'entries'}
              </span>
            </div>

            {/* Hour labels */}
            <div className="mb-2 flex">
              <div className="w-48 flex-shrink-0" />
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

            {/* Timeline entries */}
            <div className="space-y-3">
              {items.map((entry) => (
                <TimelineRow
                  key={entry.id}
                  entry={entry}
                />
              ))}
            </div>
          </div>
        ))}
      </div>
    </ScrollArea>
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
    <div className="flex items-start gap-4">
      {/* Entry info */}
      <div className="w-48 flex-shrink-0 py-2">
        <p className="text-sm font-semibold text-foreground">{entry.title}</p>
        <p className="mt-1 text-xs text-muted-foreground">
          {toLocaleTime(entry.startTime)} - {toLocaleTime(entry.endTime)}
        </p>
        {entry.analysis?.mood && (
          <Badge className="mt-2 inline-flex text-xs">{entry.analysis.mood}</Badge>
        )}
      </div>

      {/* Timeline bar */}
      <div className="relative flex flex-1 h-24">
        {/* Hour grid lines */}
        <div className="absolute inset-0 flex pointer-events-none z-0 opacity-10">
          {HOURS.map((hour) => (
            <div
              key={hour}
              className="flex-1 border-l border-border/30 first:border-l-0"
            />
          ))}
        </div>

        {/* Timeline segments */}
        <div className="relative h-full w-full z-10 flex items-center">
          {segments.map((segment, idx) => (
            <Tooltip delayDuration={50} key={segment.id || idx}>
              <TooltipTrigger asChild>
                <div
                  className={cn(
                    'absolute h-10 rounded-md border border-gray-300 bg-white transition-all hover:border-gray-500 hover:shadow-lg hover:z-20 pointer-events-auto',
                    'dark:border-gray-600 dark:bg-gray-800 dark:hover:border-gray-400',
                    segment.nodeType === 'heading1' &&
                      'border-blue-400 bg-blue-50 dark:border-blue-500 dark:bg-blue-900/30 font-semibold',
                    segment.nodeType === 'blockquote' &&
                      'border-dashed border-gray-300 bg-gray-50 dark:border-gray-600 dark:bg-gray-800/50'
                  )}
                  data-testid="timeline-bar"
                  style={{
                    left: segment.left,
                    width: segment.width,
                    top: '50%',
                    transform: 'translateY(-50%)'
                  }}
                >
                  <div className="flex h-full items-center px-2 text-xs font-medium text-gray-700 dark:text-gray-200">
                    <span className="truncate">{segment.preview}</span>
                  </div>
                </div>
              </TooltipTrigger>
              <TooltipContent
                className="max-w-sm max-h-[360px] overflow-y-auto border-2 bg-popover text-left shadow-2xl"
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
