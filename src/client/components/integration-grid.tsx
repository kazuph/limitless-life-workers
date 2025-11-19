import type { IntegrationSuggestion } from '../types'
import { Card, CardContent, CardHeader, CardTitle } from './ui/card'
import { Button } from './ui/button'

type Props = {
  integrations: IntegrationSuggestion[]
}

export const IntegrationGrid: React.FC<Props> = ({ integrations }) => {
  if (!integrations.length) return null
  return (
    <div className="grid gap-4 md:grid-cols-3">
      {integrations.map((integration) => (
        <Card key={integration.id} className="flex flex-col justify-between">
          <CardHeader>
            <CardTitle className="text-base">{integration.title}</CardTitle>
            <p className="text-sm text-muted-foreground">{integration.description}</p>
          </CardHeader>
          <CardContent className="mt-auto flex items-center justify-between text-sm text-muted-foreground">
            <span>{integration.action}</span>
            <Button asChild variant="outline" size="sm">
              <a href={integration.target} target="_blank" rel="noreferrer">
                Open
              </a>
            </Button>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
