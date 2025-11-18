import type { TimelineEntry } from '../types'
import { Card, CardContent, CardHeader, CardTitle } from './ui/card'
import { Badge } from './ui/badge'
import { Separator } from './ui/separator'

type Props = {
  entries: TimelineEntry[]
}

export const InsightsGrid: React.FC<Props> = ({ entries }) => {
  const analyzed = entries.filter((entry) => entry.analysis).slice(0, 4)
  if (!analyzed.length) return null

  return (
    <div className="grid gap-4 md:grid-cols-2">
      {analyzed.map((entry) => (
        <Card key={entry.id}>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-base">{entry.title}</CardTitle>
              {entry.analysis?.tags?.slice(0, 2).map((tag) => (
                <Badge key={tag} variant="muted">
                  {tag}
                </Badge>
              ))}
            </div>
            <p className="text-sm text-muted-foreground">{entry.analysis?.summary}</p>
          </CardHeader>
          <CardContent className="space-y-4">
            {entry.analysis?.action_items?.length ? (
              <div className="text-sm">
                <p className="mb-2 font-semibold text-foreground/80">Action Items</p>
                <ul className="space-y-1 text-muted-foreground">
                  {entry.analysis.action_items.slice(0, 3).map((item) => (
                    <li key={item.title} className="rounded-md border border-border/30 px-3 py-2">
                      <p className="text-foreground">{item.title}</p>
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
            {entry.analysis?.suggestions?.length ? (
              <>
                <Separator />
                <div className="text-sm">
                  <p className="mb-2 font-semibold">Integration ideas</p>
                  <ul className="space-y-1 text-muted-foreground">
                    {entry.analysis.suggestions.slice(0, 2).map((suggestion) => (
                      <li key={suggestion.target} className="text-foreground/90">
                        {suggestion.target}: <span className="text-muted-foreground">{suggestion.rationale}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </>
            ) : null}
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
