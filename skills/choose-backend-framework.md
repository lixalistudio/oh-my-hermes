---
name: choose-backend-framework
description: Use when a backend task or project needs to choose between Elysia, Hono, or NestJS
version: 1.0.0
tags: [backend, framework, decision, elysia, hono, nestjs]
metadata:
  hermes:
    tags: [backend, framework, decision]
    related_skills: [deploy-to-cloudflare, implement-with-claude-code, implement-with-codex]
---

## Overview

Recommends the smallest backend framework that fits the project. The Lixali
Studio default is Elysia for Cloudflare Workers, with Hono and NestJS as
alternatives.

## When to Use

- Starting a new backend project
- Deciding whether to migrate an existing backend
- Founder asks which framework to use

## Prerequisites

- Access to `AGENTS.md` and `package.json` in the project
- Basic knowledge of project requirements (Workers vs. long-running, team size, existing ecosystem)

## Decision Table

| Situation | Recommended | Why |
|---|---|---|
| Cloudflare Workers, lightweight API, MVP | Elysia | Type-safe, fast, excellent DX, Cloudflare-native templates |
| Cloudflare Workers, ecosystem middleware, max compatibility | Hono | Most popular on Workers, huge middleware ecosystem |
| Large monolith, many developers, enterprise integrations | NestJS | Mature DI, decorators, enterprise patterns |
| Long-running server, complex domain logic | NestJS | Best support for non-Worker runtimes |

## Procedure

1. Read `AGENTS.md` and `package.json` for existing constraints.
2. If the project already uses one of these frameworks, continue using it unless the founder asks for a migration.
3. If the project is a Cloudflare Worker backend and has no strong preference, default to Elysia.
4. Record the decision in Hermes memory: key `backend-framework`, value `elysia` / `hono` / `nestjs`.
5. If starting a new project, use the matching template from `templates/backend-elysia-starter-template` or `templates/backend-hono-starter-template`.

## Pitfalls

- Don't switch frameworks for a single-file fix.
- Don't default to NestJS for a Cloudflare Worker MVP; it adds complexity that may not be needed.
- Elysia and Hono are faster in raw throughput but have a smaller ecosystem than NestJS.

## Verification

- Decision recorded in Hermes memory
- AGENTS.md and project conventions match the chosen framework
- Build and typecheck pass with the chosen framework
