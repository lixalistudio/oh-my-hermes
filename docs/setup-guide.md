# Complete Setup Guide

Everything you need before the CTO loop runs autonomously.

---

## What you need before starting

| Requirement | Why |
|---|---|
| A VPS or always-on machine | Hermes must run 24/7 for cron and monitoring |
| Hermes Agent v0.16+ | Profiles, Kanban, skill search, cron, and Computer Use |
| A model provider (Anthropic, OpenAI, OpenRouter…) | Hermes needs an LLM |
| A messaging platform (Telegram recommended) | How you receive approval requests |
| GitHub account + repo | Optional delivery surface for issues and PRs |
| GitHub CLI (`gh`) | Optional GitHub automation |
| Vercel account + CLI | Needed when deploying to Vercel |
| Node.js 22+ | For current CLIs and optional HyperFrames production |

---

## Step 1 — Get a VPS

Cheapest option that works: $5/month Ubuntu 22.04 on DigitalOcean, Hetzner, or Vultr.

```bash
# After SSH into your VPS:
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl unzip
```

---

## Step 2 — Install Hermes Agent

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc
hermes --version   # should print v0.16+
```

Configure a model provider:
```bash
hermes model       # interactive wizard — choose Anthropic or OpenAI
```

Test it works:
```bash
hermes chat -q "say hello"
```

Recommended smooth build policy:

```bash
hermes config set approvals.mode smart
hermes config set terminal.sudo_password ''
```

Smart mode auto-handles low-risk commands while escalating real risk. The empty
sudo value suppresses password dialogs; agents must use project-local,
user-level, package-manager, or container paths instead. Do not disable approval
checks on the host.

---

## Step 3 — Connect your messaging platform

Telegram is the most reliable for approvals (always-on, works on any phone).

```bash
hermes gateway setup     # interactive — choose Telegram
hermes gateway start     # start as background service
hermes gateway status    # confirm it's running
```

For Telegram: the wizard will give you a bot link to open on your phone. Open it, start the bot, send a message — Hermes responds. That's your approval channel.

For Slack:
```bash
hermes gateway setup     # choose Slack, follow OAuth flow
```

---

## Step 4 — Install CLIs

### Required for Cloudflare (default Lixali target)

```bash
# Wrangler CLI
npm install -g wrangler
wrangler login          # opens browser, or use CLOUDFLARE_API_TOKEN for CI/VPS

# Inngest dev server (for workflows)
npm install -g inngest-cli
```

### Supabase CLI (if using Supabase)

```bash
npm install -g supabase
supabase login
```

### GitHub CLI

```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
sudo apt update && sudo apt install gh -y

# GitHub authentication — VPS has no browser, use a token instead of gh auth login
# 1. Go to github.com → Settings → Developer settings → Personal access tokens → Fine-grained tokens
# 2. Create a token with these permissions on your repo:
#    - Contents: Read & Write      (push code)
#    - Issues: Read & Write        (triage, comment, close)
#    - Pull requests: Read & Write (create, merge PRs)
#    - Metadata: Read              (required base permission)
# 3. Copy the token, then on your VPS:
echo "YOUR_GITHUB_TOKEN" | gh auth login --with-token
gh auth status   # confirm: Logged in to github.com as [your-username]

# Also set it as an env var so skills can use it directly:
echo 'export GITHUB_TOKEN="YOUR_GITHUB_TOKEN"' >> ~/.bashrc
source ~/.bashrc
```

### Alternative targets

AWS CLI (if using `deploy-to-aws`):
```bash
npm install -g aws-cdk
# or: apt install awscli
aws configure
```

Shipnode (if using `deploy-to-vps`):
```bash
npm install -g shipnode
# See: https://github.com/devalade/shipnode
```

---

## Step 5 — Install Oh My Hermes

```bash
git clone https://github.com/salomondiei08/oh-my-hermes /tmp/oh-my-hermes
bash /tmp/oh-my-hermes/install.sh
```

Verify:
```bash
bash /tmp/oh-my-hermes/scripts/verify.sh
```

All items should show [OK].

## Step 5b — Configure the CTO loop agents

This creates real Hermes profiles for each agent, initializes the kanban board, and sets up cron jobs. Run it after `install.sh`:

```bash
# Set these first (see Step 7 for details):
export GITHUB_TOKEN=your-fine-grained-token
export GITHUB_USERNAME=your-github-username
export GITHUB_REPO=owner/repo
export PRODUCTION_URL=https://yourapp.pages.dev   # optional but recommended
export DEPLOYMENT_TARGET=cloudflare               # or aws / vps

OH_MY_HERMES_SETUP_CTO_CONFIRM=1 bash /path/to/oh-my-hermes/scripts/setup-cto.sh
```

Optional integrations are configured only when first needed. Do not paste keys
into chat:

```bash
bash ~/.hermes/scripts/setup-integrations.sh --check
bash ~/.hermes/scripts/setup-integrations.sh --buffer
bash ~/.hermes/scripts/setup-integrations.sh --seedance
bash ~/.hermes/scripts/setup-integrations.sh --openai
```

Buffer is requested at the first approved social scheduling action. Seedance is
requested at the first approved paid video generation. OpenAI is requested only
when selected as the Hermes model or creative provider.

For a fresh VPS, use the installed server bootstrap after installing Oh My
Hermes:

```bash
bash ~/.hermes/scripts/server-bootstrap.sh --project myapp --repo owner/repo --telegram
bash ~/.hermes/scripts/status.sh
```

To replace stale runtime state before a new Telegram agent:

```bash
bash ~/.hermes/scripts/reset-runtime.sh --yes
```

The script:
- Creates Hermes profiles: `cto`, `pm`, `designer`, `dev`, `qa`, `security`, `ops`
- Injects each agent's role definition into its profile
- Initializes the kanban board
- Authenticates `gh` CLI using your token (no browser needed)
- Warns if a gateway is already running (do not start duplicate gateways with the same bot token)
- Saves your repo and username to Hermes memory
- Creates missing named cron jobs for product review, health, logs, daily report,
  daily security, and weekly security based on available repo/production context

Safe to re-run — it is idempotent.

---

## Step 6 — Bootstrap your project

In your project directory:
```bash
cd /path/to/your/project
bash /path/to/oh-my-hermes/scripts/bootstrap.sh
```

This creates:
- `AGENTS.md` — fill in your project name, stack, and any constraints
- `.env.example` — fill in and copy to `.env.local`
- A health endpoint tailored to the detected framework (Vite, Astro, Elysia, Hono, NestJS, or Express)

**Fill in AGENTS.md.** This is important — it tells the Dev Agent what stack to use and what conventions to follow.

---

## Step 7 — Set your environment variables

Required minimum:
```bash
# In your .env.local

# GitHub — optional for issue and PR delivery
# Create at: github.com → Settings → Developer settings → Personal access tokens → Fine-grained
# Permissions needed: Contents (R/W), Issues (R/W), Pull requests (R/W), Metadata (R)
GITHUB_TOKEN=your-fine-grained-token
GITHUB_USERNAME=your-github-username     # used when assigning issues to Hermes
GITHUB_REPO=owner/repo                   # the repo the CTO loop manages

# Cloudflare (default target)
CLOUDFLARE_API_TOKEN=                    # dash.cloudflare.com → My Profile → API Tokens
CLOUDFLARE_ACCOUNT_ID=                   # dash.cloudflare.com → Workers & Pages → Overview
WRANGLER_API_TOKEN=                      # same scope as CLOUDFLARE_API_TOKEN

# Alternative targets (use only the one you need)
DEPLOYMENT_TARGET=cloudflare             # or aws / vps
AWS_ACCESS_KEY_ID=                       # if DEPLOYMENT_TARGET=aws
SHIPNODE_HOST=                           # if DEPLOYMENT_TARGET=vps

# Notifications
SLACK_WEBHOOK_URL=        # leave empty if using Telegram only
TELEGRAM_BOT_TOKEN=       # leave empty if using Slack only
TELEGRAM_CHAT_ID=         # leave empty if using Slack only
```

Add to Cloudflare Pages/Workers dashboard after first deploy:
```bash
# Supabase (if used)
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_KEY=
DATABASE_URL=

# Better Auth (if used)
BETTER_AUTH_SECRET=
BETTER_AUTH_URL=

# Inngest (if used)
INNGEST_EVENT_KEY=
INNGEST_SIGNING_KEY=

# Monitoring
SENTRY_DSN=
SENTRY_AUTH_TOKEN=
AXIOM_TOKEN=
AXIOM_DATASET=
BETTER_STACK_URL=
```

For Cloudflare Workers/Pages, environment variables are configured in the
Cloudflare dashboard or via `wrangler secret put`. For AWS/VPS, follow the
platform-specific skill.

---

## Step 8 — Start the CTO loop

Tell Hermes (via Telegram, Slack, or terminal):

```
Set up the CTO loop for [owner/repo].
Send approvals to me on Telegram.
```

Hermes will inspect the project, infer available settings, ask at most three
optional questions with recommended defaults, create the seven profiles, save
available context, create missing named cron jobs, and show the kanban board.

---

## What happens next (no action needed from you)

- CTO keeps one product outcome active across Understand, Design, Build, Check,
  Ship, and Learn
- Product turns ideas, feedback, analytics, and issues into compact build briefs
- Designer defines and verifies user-facing work
- Builder implements the smallest complete increment
- Security and Reviewer independently check risk and behavior
- You choose YES, NO, CLOSE, or LATER at release
- Ops deploys, checks health, deduplicates logs, and reports actionable incidents
- Daily and weekly security jobs run when a repository is configured

---

## Troubleshooting

**Hermes gateway not responding on Telegram:**
```bash
hermes gateway status
hermes gateway restart
hermes logs gateway
```

**Kanban not showing tasks:**
```bash
hermes kanban list
hermes kanban stats
```

**Cron jobs not firing:**
```bash
hermes cron list
hermes cron status
```

**Health check always failing:**
- Check that `/api/health` returns `{ "status": "ok" }` with HTTP 200
- Check Cloudflare Workers/Pages logs in the dashboard or via `wrangler tail`
- Verify `APP_URL` / `BETTER_AUTH_URL` / `INNGEST_API_URL` point to the deployed URL, not localhost
- Check the URL saved in memory: retrieve `last-deployment-url`

**Build failing on Cloudflare but passing locally:**
- Compare Node.js version: `node --version` vs `wrangler` Node compatibility
- Check that environment variables are set in the Cloudflare dashboard or via `wrangler secret put`
- For Workers, ensure `wrangler.jsonc` bindings (D1, R2, KV) match the remote resources
- For Pages, verify `Functions` directory or adapter configuration

**Inngest functions not triggering after deploy:**
- Check the Inngest dashboard shows the sync from the deployed URL
- Verify `INNGEST_SIGNING_KEY` and `INNGEST_EVENT_KEY` are set in the platform
- Run `npx inngest-cli@latest dev` locally and fire a test event

**Shipnode/VPS deployment issues:**
- Confirm SSH key access: `ssh -i $SHIPNODE_SSH_KEY_PATH $SHIPNODE_USER@$SHIPNODE_HOST`
- Check Shipnode project name matches the remote config
- See: https://github.com/devalade/shipnode

---

## Minimum viable setup (just to test)

If you want to try the approval loop without the full CTO automation:

1. Steps 1–5 (Hermes + messaging + CLIs + Oh My Hermes)
2. Tell Hermes: `deploy this project to Cloudflare` — it runs `deploy-to-cloudflare`
3. After deploy: tell Hermes: `run post-deploy-followup` — it health checks and notifies you
4. Create a GitHub issue manually — tell Hermes: `implement issue #1` — it picks it up, implements, creates PR, reviews, and asks for your approval
