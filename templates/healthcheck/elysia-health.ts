import { Elysia } from "elysia";

// Copy to: src/routes/health.ts
// Mount with: app.use(healthRouter)
// Returns HTTP 200 with { status, version, timestamp } when healthy.
// Better Stack and health-check skill poll this endpoint.

export const healthRouter = new Elysia({ prefix: "/api/health" }).get("/", () => ({
  status: "ok",
  version: process.env.npm_package_version ?? "1.0.0",
  timestamp: new Date().toISOString(),
}));

export default healthRouter;
