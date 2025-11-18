export type AnalysisJSON = {
  summary: string
  mood: string
  tags: string[]
  time_blocks: {
    startTime?: string | null
    endTime?: string | null
    label: string
    details?: string
  }[]
  action_items: {
    title: string
    suggested_integration?: string
    due?: string
  }[]
  suggestions: {
    target: string
    rationale: string
  }[]
}
