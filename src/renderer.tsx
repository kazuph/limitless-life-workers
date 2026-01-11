/** @jsxImportSource hono/jsx */
import { jsxRenderer } from 'hono/jsx-renderer'
import { Script, ViteClient } from 'vite-ssr-components/hono'

export const renderer = jsxRenderer(({ children }) => {
  return (
    <html>
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Life Log</title>
        <ViteClient />
        <Script src="/src/client/main.ts" />
      </head>
      <body class="bg-[hsl(var(--background))] text-[hsl(var(--foreground))]">
        {children}
      </body>
    </html>
  )
})
