import type {
  LimitlessContentNode,
  LimitlessLifelog
} from '../types/limitless'
import type {
  NewLifelogEntry,
  NewLifelogSegment
} from '../db/schema'

const toEpochMs = (value?: string | null) => {
  if (!value) return null
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return null
  return date.getTime()
}

export const lifelogToEntry = (lifelog: LimitlessLifelog): NewLifelogEntry => ({
  id: lifelog.id,
  title: lifelog.title ?? 'Untitled entry',
  markdown: lifelog.markdown ?? null,
  startTime: lifelog.startTime ?? null,
  endTime: lifelog.endTime ?? null,
  startEpochMs: toEpochMs(lifelog.startTime),
  endEpochMs: toEpochMs(lifelog.endTime),
  isStarred: lifelog.isStarred ?? false,
  updatedAt: lifelog.updatedAt ?? lifelog.endTime ?? lifelog.startTime ?? new Date().toISOString(),
  timezone: lifelog.startTime ? new Date(lifelog.startTime).toLocaleTimeString('en-US', { timeZoneName: 'short' }).split(' ').pop() ?? undefined : undefined
})

export const lifelogToSegments = (
  lifelog: LimitlessLifelog
): NewLifelogSegment[] => {
  if (!lifelog.contents?.length) return []
  return flattenNodes(lifelog.contents, lifelog.id)
}

const flattenNodes = (
  nodes: LimitlessContentNode[],
  lifelogId: string,
  parents: number[] = []
): NewLifelogSegment[] => {
  return nodes.flatMap((node, index) => {
    const pathArray = [...parents, index]
    const path = pathArray.join('.')
    const nodeId = `${lifelogId}:${path}`
    const current: NewLifelogSegment = {
      entryId: lifelogId,
      nodeId,
      path,
      nodeType: node.type ?? 'paragraph',
      content: node.content ?? null,
      startTime: node.startTime ?? null,
      endTime: node.endTime ?? null,
      startOffsetMs: node.startOffsetMs ?? null,
      endOffsetMs: node.endOffsetMs ?? null,
      speakerName: node.speakerName ?? null,
      speakerIdentifier: node.speakerIdentifier ?? null
    }
    const children = node.children?.length
      ? flattenNodes(node.children, lifelogId, pathArray)
      : []
    return [current, ...children]
  })
}

export const lifelogHashSeed = (lifelog: LimitlessLifelog) =>
  JSON.stringify({
    id: lifelog.id,
    updatedAt: lifelog.updatedAt,
    title: lifelog.title,
    startTime: lifelog.startTime,
    endTime: lifelog.endTime
  })
