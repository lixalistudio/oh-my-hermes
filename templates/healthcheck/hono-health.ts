import { Hono } from "hono";

// Copy to: src/routes/health.ts
// Mount with: app.route("/api/health", healthRouter)
// Returns HTTP 200 with { status, version, timestamp } when healthy.
// Better Stack and health-check skill poll this endpoint.

const health = new Hono();

health.get("/", (c) => {
  return c.json({
    status: "ok",
    version: c.env.APP_VERSION ?? process.env.npm_package_version ?? "1.0.0",
    timestamp: new Date().toISOString(),
  });
});

export default health;
