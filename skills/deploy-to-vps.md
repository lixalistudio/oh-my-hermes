---
name: deploy-to-vps
description: Use when a project must be deployed to a custom VPS via Shipnode
version: 1.0.0
tags: [deployment, vps, shipnode, ops]
metadata:
  hermes:
    tags: [deployment, vps, shipnode, ops]
    related_skills: [post-deploy-followup, setup-monitoring, health-check, rollback]
---

## Overview

Deploys a Node.js project to a custom VPS using
[Shipnode](https://github.com/devalade/shipnode). Captures the URL and runs
`post-deploy-followup`.

## When to Use

- `DEPLOYMENT_TARGET=vps` is set in environment or memory
- Founder wants full control over the server
- Project needs long-running services, custom binaries, or non-Cloudflare/AWS workloads

## Prerequisites

- Shipnode CLI installed: `npm install -g shipnode`
- SSH access to the VPS: `ssh -i $SHIPNODE_SSH_KEY_PATH $SHIPNODE_USER@$SHIPNODE_HOST`
- Environment variables set:
  - `SHIPNODE_HOST`, `SHIPNODE_USER`, `SHIPNODE_SSH_KEY_PATH`
  - `SHIPNODE_PROJECT_NAME`, `SHIPNODE_REPO`
- Project has a `package.json` with `start` script
- Project has `/api/health` endpoint

## Procedure

**Pre-deploy checklist:**
1. `git status` clean
2. `AGENTS.md` committed
3. `/api/health` endpoint exists
4. `npm run typecheck` and `npm run build` pass
5. SSH access works: `ssh -i $SHIPNODE_SSH_KEY_PATH $SHIPNODE_USER@$SHIPNODE_HOST "echo ok"`

**Deploy via Shipnode:**
```bash
shipnode deploy --project $SHIPNODE_PROJECT_NAME --repo $SHIPNODE_REPO --host $SHIPNODE_HOST --user $SHIPNODE_USER --key $SHIPNODE_SSH_KEY_PATH
```

Or follow the Shipnode CLI docs for the specific version installed.

**Save deployment context:**
1. Save URL to Hermes memory: key `last-deployment-url`, value `http://$SHIPNODE_HOST` or the Shipnode output URL
2. Save target to Hermes memory: key `deployment-target`, value `vps`
3. Run `post-deploy-followup`

## Pitfalls

- Shipnode must be configured on the VPS before first deploy. See the Shipnode README.
- `.env` files must be placed on the VPS manually or via a secure mechanism; do not commit them.
- The VPS must have Node.js, process manager (PM2/systemd), and reverse proxy (Caddy/Nginx) set up.
- Health check may fail immediately after deploy if the process manager needs time to restart.

## Verification

- Shipnode reports success
- `curl http://$SHIPNODE_HOST/api/health` returns HTTP 200 + `{ status: "ok" }`
- `last-deployment-url` and `deployment-target=vps` saved to Hermes memory
- `post-deploy-followup` started
