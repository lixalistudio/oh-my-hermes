---
name: deploy-to-cloudflare
description: Use when a frontend or backend project needs to be deployed to Cloudflare Pages or Workers
version: 1.0.0
tags: [deployment, cloudflare, pages, workers, ops]
metadata:
  hermes:
    tags: [deployment, cloudflare, wrangler, ops]
    related_skills: [post-deploy-followup, setup-monitoring, health-check, rollback]
---

## Overview

Pre-deploy checks → deploy to Cloudflare (Pages for frontends, Workers for
backends) → capture URL → trigger `post-deploy-followup`. Uses Wrangler.

## When to Use

- First deployment to Cloudflare Pages or Workers
- Redeployment after changes
- Implementation is complete and build passes locally
- `DEPLOYMENT_TARGET` is `cloudflare` or unset

## Prerequisites

- Wrangler CLI: `npm install -g wrangler`
- `CLOUDFLARE_API_TOKEN` or `wrangler login` (not both required in CI)
- `CLOUDFLARE_ACCOUNT_ID` in environment or `wrangler.toml` / `wrangler.jsonc`
- For Pages: project configured in Cloudflare dashboard (or create with `wrangler pages project create`)
- For Workers: project configured in `wrangler.jsonc`
- Project has `/api/health` endpoint

## Procedure

**Pre-deploy checklist — fix all failures before continuing:**
1. `git status` → clean working tree, no uncommitted changes
2. `.env.local` is in `.gitignore`
3. `AGENTS.md` is committed
4. `/api/health` endpoint exists
5. `npm run build` passes locally (Pages) or `npm run typecheck` passes (Workers)
6. For Workers: `wrangler whoami` shows an authenticated account

**Detect project type:**
```bash
# Pages (Vite, Astro, Next.js, static site)
if [ -f "wrangler.toml" ] || grep -q '"pages"' wrangler.jsonc 2>/dev/null; then
  echo "pages"
fi

# Workers (Elysia, Hono, other backend)
if grep -q '"workers"\|"main"' wrangler.jsonc 2>/dev/null; then
  echo "workers"
fi
```

**Deploy Pages (frontend):**
```bash
npm run build
wrangler pages deploy ./dist --project-name=my-project --branch=main
```
Capture the production URL from output (e.g. `https://my-project.pages.dev`).

**Deploy Workers (backend):**
```bash
wrangler deploy
```
Capture the Worker URL from output (e.g. `https://my-worker.your-account.workers.dev`).

**Save deployment context:**
1. Save URL to Hermes memory: key `last-deployment-url`, value URL string
2. Save target to Hermes memory: key `deployment-target`, value `cloudflare`
3. Run `post-deploy-followup`

## Pitfalls

- `wrangler deploy` exit code 0 does NOT mean the Worker is healthy. Always run `post-deploy-followup`.
- Environment variables on Workers/Pages must be set via `wrangler secret put` or dashboard; `.env.local` is not read in production.
- D1/R2/KV bindings must match between `wrangler.jsonc` and the remote resources.
- Cloudflare Pages preview branches get unique URLs; do not promote them to production without confirmation.

## Verification

- `wrangler pages deploy` or `wrangler deploy` exits 0
- Deployment URL captured and in Hermes memory
- `deployment-target` saved as `cloudflare`
- `post-deploy-followup` started
