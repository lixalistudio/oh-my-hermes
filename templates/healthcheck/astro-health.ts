// Astro API route
// Place at src/pages/api/health.ts (Astro v3) or src/routes/api/health.ts (Astro v4)
export const GET = () => {
  return new Response(
    JSON.stringify({ status: "ok", uptime: process.uptime() }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    },
  );
};
