---
name: health-check
description: Use when a deployed app needs to be verified as running, after every deployment, or on-demand to confirm availability
version: 2.0.0
tags: [health, monitoring, ops, cloudflare, aws, vps]
metadata:
  hermes:
    tags: [health, monitoring, ops]
    requires_toolsets: [terminal, web]
---

## Overview

Three-layer check: app endpoint → dependencies (database / Inngest / auth) →
platform logs. Reports a full picture, not just "is it up." Works across
Cloudflare, AWS, and VPS targets.

## When to Use

- After every deployment (called by `post-deploy-followup`)
- Scheduled every 15 minutes by Ops Agent cron
- On-demand after an incident to verify recovery

## Prerequisites

- Deployed app URL (from Hermes memory key `last-deployment-url`, or provided directly)
- `deployment-target` in Hermes memory or environment (`cloudflare`, `aws`, `vps`, or `vercel` for legacy)
- CLI credentials for the target platform (Wrangler for Cloudflare, AWS CLI for AWS, SSH for VPS)

## Procedure

### 1. App health endpoint

```bash
curl -s -o /tmp/health_body.json -w "%{http_code} %{time_total}" \
  [url]/api/health
```

Validate:
- HTTP 200
- Body parses as JSON with `"status": "ok"`
- Response time < 3000ms (warn if > 1000ms)

On 404 → health endpoint missing, run `bootstrap.sh`.
On timeout → retry once (cold start), then fail.

### 2. Dependency check

Check whichever dependencies the project uses:

- **D1 / Drizzle backend:** run a quick query via Wrangler or the app's own test endpoint.
- **Supabase:**
  ```bash
  curl -s -o /dev/null -w "%{http_code}" \
    "$SUPABASE_URL/rest/v1/" \
    -H "apikey: $SUPABASE_ANON_KEY"
  ```
  - HTTP 200 → reachable
  - HTTP 401/403 → reachable but key issue
  - Timeout / 5xx → Supabase incident — check status.supabase.com
- **Inngest:** check the Inngest dashboard shows the app as connected.
- **Better Auth:** verify `/api/auth/session` or a known auth endpoint returns an expected response.

### 3. Platform logs

Pull the last 50 lines from the active target:

**Cloudflare Workers/Pages:**
```bash
wrangler tail --format=pretty --limit=50
```

**AWS:**
```bash
aws logs tail /aws/elasticbeanstalk/$AWS_EB_ENVIRONMENT_NAME/var/log/web.stdout.log --follow=false
# or Lambda:
aws logs tail /aws/lambda/$AWS_LAMBDA_FUNCTION_NAME --follow=false
```

**VPS:**
```bash
ssh -i $SHIPNODE_SSH_KEY_PATH $SHIPNODE_USER@$SHIPNODE_HOST "journalctl -u $SHIPNODE_PROJECT_NAME -n 50 --no-pager"
```

Scan for:
- `Error:` or `Unhandled` — application errors
- `FATAL` — process crashes
- Response times > 5000ms — performance issues
- Status 500 or 502 — server errors

Flag any of these in the report. Do not flood the founder — summarize ("3 errors in the last 50 requests, all related to auth").

### 4. Report

```
Health check — [timestamp]
────────────────────────────────────
App endpoint:   PASS / FAIL  ([ms]ms)
Dependencies:   PASS / FAIL
Platform logs:  CLEAN / [n] errors detected
Target:         [cloudflare|aws|vps]

[If anything failed or logged errors:]
  Details: [plain-English summary]
  Action:  [what Hermes will do next]
```

### 5. On any FAIL

- Save to Hermes memory: key `health-failure-log`, append `{ timestamp, layer, detail, target }`
- Load `send-notification` with failure summary
- If logs show 500s: pull more logs and identify the failing route
- If a provider is down: check the provider status page, notify founder, do not attempt operations against it

## Pitfalls

- Cold starts cause slow first requests — always retry once before failing.
- Cloudflare `wrangler tail` requires the project to be linked; run `wrangler login` first.
- VPS logs may not exist if the project is not running as a systemd service or PM2 process.
- Do not report platform noise (routine 200s, OPTIONS requests) as errors.
- Absence of logs is not proof of health; pair with the endpoint check.

## Verification

Full report printed with all three layers checked. Any failures logged to memory.
