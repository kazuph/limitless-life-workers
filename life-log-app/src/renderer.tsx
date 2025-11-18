/** @jsxImportSource hono/jsx */
import { raw } from 'hono/html'
import { jsxRenderer } from 'hono/jsx-renderer'
import { ViteClient } from 'vite-ssr-components/hono'

export const renderer = jsxRenderer(({ children }) => {
  return (
    <html>
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Limitless Life Log</title>
        <ViteClient />
        {import.meta.env?.DEV && (
          <script type="module">
            {raw(`
              import RefreshRuntime from "/@react-refresh"
              RefreshRuntime.injectIntoGlobalHook(window)
              window.$RefreshReg$ = () => {}
              window.$RefreshSig$ = () => (type) => type
              window.__vite_plugin_react_preamble_installed__ = true
            `)}
          </script>
        )}
        <script type="module" src="/src/client/main.tsx" />
      </head>
      <body class="bg-[hsl(var(--background))] text-[hsl(var(--foreground))]">
        {children}
      </body>
    </html>
  )
})
