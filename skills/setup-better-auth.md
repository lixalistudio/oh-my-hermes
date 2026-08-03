---
name: setup-better-auth
description: Use when a project needs Better Auth for authentication, especially with API keys or B2B multi-provider requirements
version: 1.0.0
tags: [auth, better-auth, setup, api-key]
metadata:
  hermes:
    tags: [auth, better-auth, setup]
    related_skills: [connect-supabase, setup-inngest, deploy-to-cloudflare]
---

## Overview

Configures Better Auth in a project. Adds the API-key plugin when the project
exposes API keys to B2B clients or integrations. Does not run migrations or
commit secrets.

## When to Use

- Project needs B2B auth, multi-provider auth, or fine-grained permissions
- Project exposes API keys to clients or integrations
- `AGENTS.md` specifies Better Auth as the auth provider
- Founder asks to switch from Supabase Auth to Better Auth

## Prerequisites

- Project already has a backend (Elysia, Hono, NestJS, or Next.js)
- Database adapter chosen (Drizzle on D1 for Cloudflare Workers, or PostgreSQL via Supabase)
- `BETTER_AUTH_SECRET` and `BETTER_AUTH_URL` available in `.env.local`

## Procedure

1. **Install dependencies:**
   ```bash
   npm install better-auth
   npm install @better-auth/api-key
   ```

2. **Create `src/lib/auth.ts`:**
   ```typescript
   import { betterAuth } from "better-auth";
   import { apiKey } from "@better-auth/api-key";

   export const auth = betterAuth({
     database: drizzleAdapter(db), // or your adapter
     plugins: [
       apiKey({
         // options: defaultKeyName, rateLimit, etc.
       }),
     ],
     secret: process.env.BETTER_AUTH_SECRET,
     appUrl: process.env.BETTER_AUTH_URL,
   });
   ```

3. **Mount the auth handler:**
   - Elysia: use `auth.handler` inside a route or plugin.
   - Hono: `app.on("POST", "/api/auth/**", (c) => auth.handler(c.req.raw))`.
   - NestJS: create a controller that forwards requests to `auth.handler`.

4. **Add environment variables to `.env.example` and `.env.local`:**
   ```
   BETTER_AUTH_SECRET=                # openssl rand -base64 32
   BETTER_AUTH_URL=http://localhost:3000
   BETTER_AUTH_API_KEY_ENABLED=true
   ```

5. **Generate and run migrations** if the schema changed (Drizzle or other ORM).

6. **Save config to Hermes memory:** key `auth-config`, value `{ provider: "better-auth", apiKeyEnabled: true }`.

## Pitfalls

- Never commit `BETTER_AUTH_SECRET`. Generate a fresh one for production.
- `BETTER_AUTH_URL` must be the public URL in production, not `localhost`.
- On Cloudflare Workers, the adapter must be compatible with the Workers runtime (D1 adapter for Drizzle, not a Node.js-only Postgres driver).
- The API-key plugin requires the database schema to include its tables; regenerate migrations after installing the plugin.

## Verification

- `npm run typecheck` passes
- `POST /api/auth/session` returns a session (or expected error for unauthenticated request)
- API key endpoints are documented and testable
- `auth-config` saved to Hermes memory
- Secrets are in `.env.local` and not in git
