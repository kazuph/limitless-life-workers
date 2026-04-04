/*
# CMS Worker Example

Uses D1 (database), R2 (storage), and HTMLRewriter

```
moon build
npx wrangler dev fixtures/cf-worker-cms.js --config fixtures/wrangler-cms.toml
```

First, initialize the database:
```
curl -X POST http://localhost:8787/cms/init
```
*/
let handler = null;
export default {
  async fetch(request, env, ctx) {
    if (handler === null) {
      const mod = await import(
        "../target/js/release/build/examples/cfw/cfw.js"
      );
      handler = mod.get_cms_handler();
    }
    return handler(request, env, ctx);
  },
};
