---
name: rollback
description: Use when a health check fails after a deploy and the last deploy was under 2 hours ago, to roll back production to the previous working version
version: 2.0.0
tags: [ops, rollback, incident, cloudflare, aws, vps]
metadata:
  hermes:
    tags: [ops, deployment, incident, recovery]
    requires_toolsets: [terminal]
---

## Overview

Rolls back the production deployment to the previous version. Always requires
explicit founder confirmation before executing. Logs the rollback to memory and
notifies via `send-notification`. Supports Cloudflare, AWS, and VPS targets.

## When to Use

- Health check fails after a deploy AND last deploy was under 2 hours ago
- Founder explicitly requests a rollback
- Ops Agent identifies a production incident tied to a recent change

Do NOT use for incidents unrelated to a recent deploy (e.g., provider outage, external API failure).

## Prerequisites

- `deployment-target` in Hermes memory or environment (`cloudflare`, `aws`, `vps`)
- Hermes memory has `last-deployment-url` (set by deploy skills)
- Founder has been notified of the incident before this skill runs
- Platform credentials for the target

## Procedure

1. **Retrieve deployment context from memory:**
   - `last-deployment-url`
   - `deployment-target` (default `cloudflare`)

   If empty, ask founder for the deployment URL before proceeding.

2. **Show founder what will happen** — send this message via `send-notification` before acting:
   ```
   Rolling back production.

   Current (broken): [current-url]
   Target: [cloudflare|aws|vps]
   Rolling back to: previous deployment

   This will make the previous deployment live immediately.

   Reply YES to confirm.
   ```

3. **Wait for explicit YES.** If no response in 10 minutes, do not roll back. Alert founder again.

4. **Execute rollback per target:**

   **Cloudflare Workers:**
   ```bash
   wrangler rollback
   ```

   **Cloudflare Pages:**
   - Go to Cloudflare dashboard → Pages → Deployments → select previous deployment → Deploy to production
   - Or use Wrangler if supported by the CLI version.

   **AWS Elastic Beanstalk:**
   ```bash
   eb rollback $AWS_EB_ENVIRONMENT_NAME
   ```

   **AWS Lambda:**
   ```bash
   aws lambda update-alias --function-name $AWS_LAMBDA_FUNCTION_NAME --name production --function-version $PREVIOUS_VERSION
   ```

   **ECS:**
   ```bash
   aws ecs update-service --cluster $AWS_ECS_CLUSTER --service $AWS_ECS_SERVICE --force-new-deployment
   # Then verify the previous task definition is running
   ```

   **VPS via Shipnode:**
   ```bash
   shipnode rollback --project $SHIPNODE_PROJECT_NAME --host $SHIPNODE_HOST --user $SHIPNODE_USER --key $SHIPNODE_SSH_KEY_PATH
   ```
   Or manually redeploy the previous git tag/SHA on the VPS.

5. **Verify recovery** via `health-check` — wait 30 seconds for propagation, then run:
   ```bash
   curl -s -w "\n%{http_code}" "[production-url]/api/health"
   ```
   Expected: HTTP 200 + `"status":"ok"`.

6. **Save to memory:** key `rollback-log`, append `{ rolledBackAt, fromUrl, target, reason, healthStatus }`.

7. **Notify founder** of outcome via `send-notification`:
   - Success: "Rolled back. Production is healthy. Health: [response-time]ms."
   - Failure: "Rollback completed but health check still failing. Manual investigation needed."

8. **Update kanban card** for the deploy that caused the incident to `blocked` with a note.

## Pitfalls

- Never roll back without founder confirmation — always send the confirmation message first.
- Cloudflare Pages rollback is dashboard-driven; the CLI may not support direct rollback of Pages production aliases.
- AWS Lambda aliases need a previous published version number; know it before rolling back.
- VPS rollback requires a known-good git ref or Shipnode snapshot; document it during deploy.
- If health check still fails after rollback, the issue is not deployment-related — escalate to founder with logs summary.
- Do not chain multiple rollbacks. One rollback, verify, then stop. If still broken, alert founder.

## Verification

- Platform shows the previous deployment as current
- `curl [production-url]/api/health` returns HTTP 200 + `status: ok`
- Rollback entry saved to `rollback-log` in Hermes memory
- Founder notified of outcome
