---
name: server-bootstrap
description: Use when setting up a brand new server with Hermes, Telegram gateway, Oh My Hermes, project context, and the CTO loop
version: 1.0.0
tags: [setup, server, telegram, bootstrap, first-run]
---

## When to Use

- A fresh VPS or SSH host should become a Hermes product-building server.
- The founder wants a new Telegram-connected Hermes agent.
- Old runtime state needs to be backed up and replaced.

## Prerequisites

- SSH access to the server.
- A Telegram bot token or permission to prompt for it securely on the server.
- Optional repo, production URL, and deployment target (`cloudflare` default, `aws`, `vps`).

## Procedure

1. If replacing an existing agent, first run `reset-runtime` with backup.
2. Install target CLIs on the server:
   - Cloudflare: `npm install -g wrangler inngest-cli`
   - AWS (optional): `npm install -g aws-cdk` or `apt install awscli`
   - Shipnode (optional): `npm install -g shipnode`
3. Run:
   ```bash
   ~/.hermes/scripts/server-bootstrap.sh --project myapp --repo owner/repo --telegram
   ```
4. If the script prompts for a token, enter it in the terminal only. Never paste
   tokens into chat.
5. Send a Telegram message to the bot: `status`.
6. Run `project-status` and then start from the current product outcome or use
   `ship-this-idea`.
7. Set `DEPLOYMENT_TARGET` in the environment or Hermes memory to `cloudflare`,
   `aws`, or `vps`.

## Pitfalls

- Do not assume editing `config.yaml` clears stale Telegram sessions.
- Do not start two gateways with the same Telegram bot token.
- Rotate any token that was pasted into chat.

## Verification

- `~/.hermes/scripts/status.sh` reports Hermes and gateway state.
- The Telegram bot responds to a message.
- Seven product-loop profiles are present or setup reports the exact missing
  Hermes capability.
