import path from "node:path";
import { defineConfig } from "vitest/config";

export default defineConfig({
  resolve: {
    alias: {
      "@your-app/contracts": path.resolve(import.meta.dirname, "../../packages/contracts/src/index.ts"),
      "@your-app/mobile-shared": path.resolve(import.meta.dirname, "../../packages/mobile-shared/src/index.ts")
    }
  },
  test: {
    environment: "jsdom",
    globals: true,
    include: ["test/**/*.test.ts", "test/**/*.test.tsx", "src/**/*.test.ts", "src/**/*.test.tsx"],
    setupFiles: ["./test/setup.ts"]
  }
});
