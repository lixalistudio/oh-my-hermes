---
name: connect-supabase
description: Use when a Supabase project needs to be linked to the app for the first time, or when new migrations need to be pushed
version: 1.0.0
tags: [supabase, database, setup, migrations]
---

## Overview

Links Supabase to the project, sets environment variables locally and in the target platform, pushes migrations.

## When to Use

- First-time Supabase connection for this project
- New migrations to push to the live database
- Supabase env vars missing from the deployment target

## Prerequisites

- Supabase account and project created at supabase.com
- Supabase CLI: `npm install -g supabase`
- Logged in: `supabase login`
- Project ref from Supabase dashboard → Project Settings → General

## Procedure

**Initial setup:**
```bash
supabase init                               # if not already initialized
supabase link --project-ref [project-ref]
```

Add to `.env.local` (values from Supabase dashboard → Settings → API):
```
SUPABASE_URL=https://[ref].supabase.co
SUPABASE_ANON_KEY=[anon-key]
SUPABASE_SERVICE_KEY=[service-role-key]
DATABASE_URL=postgresql://postgres:***@db.[ref].supabase.co:5432/postgres
```

Add vars to the target platform:

For Cloudflare Pages/Workers:
```bash
wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_ANON_KEY
wrangler secret put SUPABASE_SERVICE_KEY
wrangler secret put DATABASE_URL
```

For AWS / VPS:
```bash
# Add to the platform environment or .env on the server
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_KEY=...
DATABASE_URL=...
```

Push migrations:
```bash
supabase db push
```

Save to Hermes memory: key `supabase-config`, value `{ projectRef, url }`.

**Adding new migrations:**
```bash
supabase migration new [migration-name]
# edit the generated file
supabase db push
```

## Pitfalls

- `SUPABASE_SERVICE_KEY` has full DB access — never prefix with `NEXT_PUBLIC_` or expose to the client.
- `supabase db push` is irreversible for destructive changes. Review migration files before running.
- Always commit migration files to git — they are the schema source of truth.

## Verification

- `supabase status` shows linked and correct project
- All 4 env vars in `.env.local` and Vercel dashboard
- `supabase db diff` shows no pending changes
