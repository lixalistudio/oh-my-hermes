---
name: setup-monitoring
description: Use when a newly deployed app has no error tracking, log aggregation, or uptime alerting configured
version: 2.0.0
tags: [monitoring, sentry, axiom, better-stack, ops]
metadata:
  hermes:
    tags: [monitoring, sentry, axiom, better-stack, ops]
    related_skills: [deploy-to-cloudflare, deploy-to-aws, deploy-to-vps, health-check]
---

## Overview

Configures Sentry for error tracking, Axiom for log aggregation, and Better Stack
for uptime/alerting. Run once per project after first deploy.

## When to Use

- First deployment is complete
- App has no Sentry DSN, Axiom token, or Better Stack URL configured
- `monitoring-config` not in Hermes memory

## Prerequisites

- App deployed with working `/api/health` endpoint
- Sentry account at sentry.io
- Axiom account at axiom.co
- Better Stack account at betterstack.com
- `SLACK_WEBHOOK_URL` or Telegram credentials available for alerts

## Procedure

**Sentry (error tracking):**

For Cloudflare Workers / Pages:
```bash
npm install toucan-js
```
Configure Sentry in the Worker entrypoint using `toucan-js` and the `SENTRY_DSN`.

For Vite / Astro / Node.js backends:
```bash
npm install @sentry/react          # Vite/React frontend
# or
npm install @sentry/astro          # Astro
# or
npm install @sentry/node            # Node.js backend
```

Add to `.env.local`:
```
SENTRY_DSN=your-dsn-from-sentry-dashboard
SENTRY_AUTH_TOKEN=your-auth-token   # for source map uploads
```

For Cloudflare Workers/Pages, set via `wrangler secret put`:
```bash
wrangler secret put SENTRY_DSN
wrangler secret put SENTRY_AUTH_TOKEN
```

**Axiom (log aggregation):**

```bash
npm install @axiomhq/js
```

Add to `.env.local`:
```
AXIOM_TOKEN=your-axiom-token
AXIOM_DATASET=your-axiom-dataset
```

For Cloudflare Workers, send structured logs via Axiom's fetch API or use the
Axiom Cloudflare Workers integration from the dashboard.

For VPS, install the Axiom shipper or forward structured stdout.

**Better Stack (uptime + alerting):**

1. Create a heartbeat monitor in Better Stack dashboard.
2. Copy the heartbeat URL to `BETTER_STACK_URL`.
3. Add a cron job or scheduled Inngest function to ping the URL every minute.
4. Add Slack/Telegram notification in Better Stack dashboard for incidents.

Example ping (add to a cron or Inngest scheduled function):
```bash
curl -s "$BETTER_STACK_URL" -o /dev/null -w "%{http_code}"
```

Save to Hermes memory: key `monitoring-config`, value `{ sentry: true, axiom: true, betterStack: true }`.

## Pitfalls

- Do not enable Sentry in local development by default; gate it with `NODE_ENV`.
- Axiom token has write access; never expose it to the client.
- Better Stack heartbeat URL is not a secret, but do not log it publicly.
- Test Sentry in a preview environment before production by triggering a deliberate error.

## Verification

- `SENTRY_DSN` in target platform env vars
- Test error appears in Sentry dashboard
- Axiom shows logs from the deployed environment
- Better Stack shows monitor as "Up" and can trigger an alert
- `monitoring-config` saved to Hermes memory
