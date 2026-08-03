---
name: setup-inngest
description: Use when a project uses Inngest for background workflows and needs to be wired to a deployed environment
version: 1.0.0
tags: [inngest, workflows, setup, deploy]
metadata:
  hermes:
    tags: [inngest, workflows, setup]
    related_skills: [deploy-to-cloudflare, deploy-to-aws, deploy-to-vps]
---

## Overview

Configures Inngest for local development and production. After each deploy,
syncs functions with the Inngest dashboard so events and scheduled jobs can
execute.

## When to Use

- Project has `src/inngest/` functions
- First time wiring Inngest to a deployed environment
- After a deploy that changed Inngest functions
- `INNGEST_EVENT_KEY` and `INNGEST_SIGNING_KEY` are missing or need rotation

## Prerequisites

- Inngest account at inngest.com
- Inngest CLI: `npm install -g inngest-cli`
- `INNGEST_EVENT_KEY` and `INNGEST_SIGNING_KEY` from Inngest dashboard
- Deployed app URL (from `last-deployment-url` or provided directly)

## Procedure

**Local development:**
```bash
npx inngest-cli@latest dev
# In another terminal:
npm run dev
```

**Set environment variables in the target platform:**

For Cloudflare Workers/Pages:
```bash
wrangler secret put INNGEST_EVENT_KEY
wrangler secret put INNGEST_SIGNING_KEY
```

For AWS / VPS:
```bash
# Add to the platform environment or .env file on the server
INNGEST_EVENT_KEY=...
INNGEST_SIGNING_KEY=...
INNGEST_API_URL=https://api.inngest.com
```

**Sync functions after deploy:**
```bash
npx inngest-cli@latest sync -u https://your-app.com/api/inngest --key $INNGEST_EVENT_KEY
```

For Cloudflare Workers, the Inngest handler is usually mounted at `/api/inngest`.

**Save to Hermes memory:** key `inngest-config`, value `{ eventKey: true, signingKey: true, synced: true }`.

## Pitfalls

- Inngest functions must be idempotent; they may retry on failure.
- `INNGEST_SIGNING_KEY` must not be exposed to the client.
- The sync URL must match the deployed public URL, not `localhost`.
- If functions are not appearing, check the Inngest dashboard sync log and the Worker/VPS logs for handler errors.

## Verification

- `npx inngest-cli@latest sync` reports success
- Inngest dashboard shows the app and its functions
- A test event triggers the expected function run
- `inngest-config` saved to Hermes memory
