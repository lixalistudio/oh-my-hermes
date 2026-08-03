// Copy to: src/api/health.ts (Vite/React SPA) or src/pages/api/health.ts (Astro)
// Returns HTTP 200 with { status, version, timestamp } when healthy.
// Better Stack and health-check skill poll this endpoint.
//
// For Vite/React SPA, expose this as an API route via the framework router
// (e.g. react-router or a Hono/Express handler mounted in front of Vite).
// For Astro, place in src/pages/api/health.ts to get a server endpoint.

export function GET() {
  return Response.json({
    status: "ok",
    version: import.meta.env.APP_VERSION ?? import.meta.env.PACKAGE_VERSION ?? "1.0.0",
    timestamp: new Date().toISOString(),
  });
}

export const prerender = false;
