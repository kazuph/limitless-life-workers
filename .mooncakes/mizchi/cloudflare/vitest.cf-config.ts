// For Cloudflare Workers testing with Vitest and vitest-pool-workers
import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
  test: {
    testTimeout: 30000, // Increase timeout to 30 seconds
    poolOptions: {
      workers: {
        miniflare: {
          // Add any Miniflare-specific options here
          kvNamespaces: ["TEST_KV", "MY_KV"],
          d1Databases: ["TEST_DB", "CMS_DB"],
          r2Buckets: ["TEST_R2", "CMS_R2"],
        },
      },
    },
  },
});
