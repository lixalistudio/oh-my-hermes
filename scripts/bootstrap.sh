#!/usr/bin/env bash
set -e

PROJECT_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMH_DIR="$(dirname "$SCRIPT_DIR")"

# Location of templates relative to this script
TEMPLATES_DIR="$OMH_DIR/templates"

echo "Oh My Hermes — project bootstrap (Lixali stack)"
echo "================================================"
echo "Project: $PROJECT_DIR"
echo ""

# Guard: don't bootstrap oh-my-hermes itself
if [ "$PROJECT_DIR" = "$OMH_DIR" ]; then
  echo "[ERROR] Run bootstrap.sh from your project directory, not from oh-my-hermes."
  exit 1
fi

CREATED=0

# ── AGENTS.md ────────────────────────────────────────────────────────────────
if [ ! -f "$PROJECT_DIR/AGENTS.md" ]; then
  cp "$TEMPLATES_DIR/AGENTS.md.template" "$PROJECT_DIR/AGENTS.md"
  echo "[CREATED] AGENTS.md"
  CREATED=$((CREATED + 1))
else
  echo "[SKIP]    AGENTS.md already exists"
fi

# ── .env.example ─────────────────────────────────────────────────────────────
if [ ! -f "$PROJECT_DIR/.env.example" ]; then
  cp "$TEMPLATES_DIR/.env.example" "$PROJECT_DIR/.env.example"
  echo "[CREATED] .env.example"
  CREATED=$((CREATED + 1))
else
  echo "[SKIP]    .env.example already exists"
fi

# ── Detect project type ────────────────────────────────────────────────────────
# Order matters: more specific frameworks first, then generic frontends.
DETECTED_TYPE="unknown"

if [ -f "$PROJECT_DIR/wrangler.jsonc" ] || [ -f "$PROJECT_DIR/wrangler.toml" ] || [ -f "$PROJECT_DIR/wrangler.json" ]; then
  DETECTED_TYPE="cloudflare-worker"
fi

if [ -f "$PROJECT_DIR/astro.config.mjs" ] || [ -f "$PROJECT_DIR/astro.config.ts" ] || [ -f "$PROJECT_DIR/astro.config.js" ]; then
  DETECTED_TYPE="astro"
fi

if [ -f "$PROJECT_DIR/vite.config.ts" ] || [ -f "$PROJECT_DIR/vite.config.mts" ] || [ -f "$PROJECT_DIR/vite.config.js" ] || [ -f "$PROJECT_DIR/vite.config.mjs" ]; then
  if grep -Eq '"@tanstack/react-router"|react-router' "$PROJECT_DIR/package.json" 2>/dev/null; then
    DETECTED_TYPE="react-router-vite"
  else
    DETECTED_TYPE="vite-react"
  fi
fi

if [ -f "$PROJECT_DIR/next.config.js" ] || [ -f "$PROJECT_DIR/next.config.mjs" ] || [ -f "$PROJECT_DIR/next.config.ts" ] || [ -f "$PROJECT_DIR/package.json" ] && grep -Eq '"next"[[:space:]]*:' "$PROJECT_DIR/package.json" 2>/dev/null; then
  DETECTED_TYPE="nextjs"
fi

if [ -f "$PROJECT_DIR/src/lib/auth.ts" ] || [ -f "$PROJECT_DIR/src/index.ts" ] && grep -Eq 'Elysia' "$PROJECT_DIR/src/index.ts" 2>/dev/null; then
  DETECTED_TYPE="elysia"
fi

if [ -f "$PROJECT_DIR/src/index.ts" ] && grep -Eq 'Hono' "$PROJECT_DIR/src/index.ts" 2>/dev/null; then
  DETECTED_TYPE="hono"
fi

if [ -f "$PROJECT_DIR/nest-cli.json" ] || [ -f "$PROJECT_DIR/package.json" ] && grep -Eq '"@nestjs/core"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  DETECTED_TYPE="nestjs"
fi

if [ -f "$PROJECT_DIR/package.json" ] && grep -Eq '"express"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  DETECTED_TYPE="express"
fi

echo "[INFO]    Detected project type: $DETECTED_TYPE"

# ── Health endpoint ──────────────────────────────────────────────────────────
# Create a health endpoint tailored to the detected framework. Only create if a
# matching template exists and the file does not already exist.

HEALTH_TEMPLATE=""
HEALTH_DEST=""

case "$DETECTED_TYPE" in
  nextjs)
    HEALTH_TEMPLATE="$TEMPLATES_DIR/healthcheck/nextjs-health-route.ts"
    HEALTH_DEST="$PROJECT_DIR/src/app/api/health/route.ts"
    ;;
  astro)
    HEALTH_TEMPLATE="$TEMPLATES_DIR/healthcheck/astro-health.ts"
    HEALTH_DEST="$PROJECT_DIR/src/pages/api/health.ts"
    ;;
  vite-react|react-router-vite)
    HEALTH_TEMPLATE="$TEMPLATES_DIR/healthcheck/vite-react-health.ts"
    HEALTH_DEST="$PROJECT_DIR/src/api/health.ts"
    ;;
  elysia)
    HEALTH_TEMPLATE="$TEMPLATES_DIR/healthcheck/elysia-health.ts"
    HEALTH_DEST="$PROJECT_DIR/src/routes/health.ts"
    ;;
  hono)
    HEALTH_TEMPLATE="$TEMPLATES_DIR/healthcheck/hono-health.ts"
    HEALTH_DEST="$PROJECT_DIR/src/routes/health.ts"
    ;;
  nestjs)
    HEALTH_TEMPLATE="$TEMPLATES_DIR/healthcheck/nestjs-health.ts"
    HEALTH_DEST="$PROJECT_DIR/src/health/health.controller.ts"
    ;;
  express)
    HEALTH_TEMPLATE="$TEMPLATES_DIR/healthcheck/express-health.js"
    HEALTH_DEST="$PROJECT_DIR/src/routes/health.js"
    ;;
  cloudflare-worker)
    HEALTH_TEMPLATE="$TEMPLATES_DIR/healthcheck/hono-health.ts"
    HEALTH_DEST="$PROJECT_DIR/src/routes/health.ts"
    ;;
  *)
    HEALTH_TEMPLATE=""
    ;;
esac

if [ -n "$HEALTH_TEMPLATE" ] && [ -f "$HEALTH_TEMPLATE" ] && [ ! -f "$HEALTH_DEST" ]; then
  mkdir -p "$(dirname "$HEALTH_DEST")"
  cp "$HEALTH_TEMPLATE" "$HEALTH_DEST"
  echo "[CREATED] $HEALTH_DEST"
  CREATED=$((CREATED + 1))
elif [ -n "$HEALTH_DEST" ] && [ -f "$HEALTH_DEST" ]; then
  echo "[SKIP]    $HEALTH_DEST already exists"
else
  echo "[SKIP]    No health endpoint template for type: $DETECTED_TYPE"
fi

# ── .gitignore guard ─────────────────────────────────────────────────────────
if [ -f "$PROJECT_DIR/.gitignore" ] && ! grep -q "^\.env\.local" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
  printf "\n.env.local\n" >> "$PROJECT_DIR/.gitignore"
  echo "[UPDATED] .gitignore — added .env.local"
fi

if [ -f "$PROJECT_DIR/.gitignore" ] && ! grep -q "\.wrangler" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
  printf "\n.wrangler\n" >> "$PROJECT_DIR/.gitignore"
  echo "[UPDATED] .gitignore — added .wrangler"
fi

echo ""
echo "Created $CREATED file(s)."
echo ""
echo "Next steps:"
echo "  1. Edit AGENTS.md — fill in Project Overview and Architecture"
echo "  2. cp .env.example .env.local && add real values"
echo "  3. Tell Hermes: 'set up the CTO loop'"
