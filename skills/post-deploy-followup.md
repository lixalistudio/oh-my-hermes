---
name: post-deploy-followup
description: Use when a deployment has just completed and health verification, logging, and notification need to run
version: 2.0.0
tags: [deployment, ops, health, notification]
metadata:
  hermes:
    tags: [deployment, ops, health, notification]
    related_skills: [health-check, send-notification, setup-inngest]
---

## Overview

Orchestrates the three post-deploy actions: health-check → log to memory →
send-notification. If the project uses Inngest, syncs functions after the
deployment. The only skill that writes deployment history.

## When to Use

- Immediately after every deployment (called automatically by `deploy-to-cloudflare`, `deploy-to-aws`, or `deploy-to-vps`)
- Manually after any deployment not handled by those skills

## Prerequisites

- Deployment URL in Hermes memory (key: `last-deployment-url`) or provided directly
- `health-check` skill available
- `send-notification` skill available
- `deployment-target` in Hermes memory or environment (`cloudflare`, `aws`, `vps`)

## Procedure

1. **Get URL** from Hermes memory key `last-deployment-url` or from user

2. **Get target** from Hermes memory key `deployment-target` or environment variable `DEPLOYMENT_TARGET`; default to `cloudflare`

3. **Run `health-check`**
   - PASS → continue
   - FAIL → run `send-notification` with failure message, log failure, stop. Do not report success.

4. **Sync Inngest functions** (if `inngest-config` is in memory or `src/inngest/` exists):
   ```bash
   npx inngest-cli@latest sync -u [url]/api/inngest --key $INNGEST_EVENT_KEY
   ```
   If sync fails, notify founder and do not treat the deploy as fully healthy.

5. **Log deployment to Hermes memory:**
   - key: `deployment-log`
   - Append: `{ url, timestamp, healthStatus: "healthy" | "unhealthy", target, engine: "claude-code" | "codex" | "hermes" | "manual" }`

6. **Run `send-notification`:**
   - Event: "Deploy"
   - Status: healthy
   - Include URL and target

7. **Check monitoring:**
   - Retrieve `monitoring-config` from Hermes memory
   - Not configured → print: "Monitoring not configured. Run `setup-monitoring` to set up Sentry, Axiom, and Better Stack."

8. **Print summary:**
   ```
   Deployment summary
   ──────────────────
   URL:          [url]
   Target:       [cloudflare|aws|vps]
   Health:       PASS / FAIL
   Inngest:      synced / not used / failed
   Notification: sent / not sent
   Monitoring:   configured / not configured
   Logged:       yes
   ```

## Pitfalls

- Health check PASS means the endpoint responded — not that the app has no bugs. Note this when reporting.
- Do not skip this skill. It is the only thing that writes deployment history to memory.
- Inngest sync failures are deployment failures if the project relies on workflows.

## Verification

- Deployment in Hermes memory under `deployment-log`
- Slack/Telegram notification delivered (or failure explained)
- Health status confirmed
- Inngest sync status confirmed (if applicable)
- Monitoring status noted
