/** @jsxImportSource hono/jsx */
import { raw } from 'hono/html'
import { jsxRenderer } from 'hono/jsx-renderer'
import { Script, ViteClient } from 'vite-ssr-components/hono'

export const renderer = jsxRenderer(({ children }) => {
  const isDev = Boolean(import.meta.env?.DEV)

  return (
    <html>
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Limitless Life Log</title>
        <ViteClient />
        {isDev && (
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
        <Script src="/src/client/main.tsx" />
      </head>
      <body class="bg-[hsl(var(--background))] text-[hsl(var(--foreground))]">
        {children}
      </body>
    </html>
  )
})
