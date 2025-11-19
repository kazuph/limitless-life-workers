export type LimitlessContentNode = {
  type: string
  content?: string
  startTime?: string
  endTime?: string
  startOffsetMs?: number
  endOffsetMs?: number
  children?: LimitlessContentNode[]
  speakerName?: string | null
  speakerIdentifier?: string | null
}

export type LimitlessLifelog = {
  id: string
  title?: string | null
  markdown?: string | null
  contents?: LimitlessContentNode[]
  startTime?: string | null
  endTime?: string | null
  isStarred?: boolean
  updatedAt?: string
}

export type LimitlessMeta = {
  lifelogs?: {
    nextCursor?: string | null
    count?: number
  }
}

export type LimitlessResponse = {
  data: {
    lifelogs: LimitlessLifelog[]
  }
  meta: LimitlessMeta
}
