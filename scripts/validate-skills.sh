#!/usr/bin/env bash
# validate-skills.sh — lints skill frontmatter and checks cross-references
# Checks: required frontmatter fields, referenced skills exist, no broken links.
# Run before committing skill changes.
#
# Note: written to be compatible with bash 3.2+ (macOS default) and uses simple
# grep-based indexing instead of associative arrays.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"

PASS=0
FAIL=0
WARN=0

ok()   { echo "  [OK]   $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN+1)); }

REQUIRED_FIELDS=(name description version tags)

echo "Oh My Hermes — skill validation"
echo "================================"
echo ""

if [ ! -d "$SKILLS_DIR" ]; then
  echo "[ERROR] skills/ directory not found at $SKILLS_DIR"
  exit 1
fi

# Build an index of known skill names (frontmatter `name:`) and filename stems.
# Stored as newline-delimited lists in temporary files.
SKILL_NAME_INDEX="$(mktemp)"
SKILL_STEM_INDEX="$(mktemp)"
trap 'rm -f "$SKILL_NAME_INDEX" "$SKILL_STEM_INDEX"' EXIT

for skill_file in "$SKILLS_DIR"/*.md; do
  [ -f "$skill_file" ] || continue
  skill_name=$(grep -m1 '^name:' "$skill_file" 2>/dev/null | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'")
  if [ -n "$skill_name" ]; then
    echo "$skill_name" >> "$SKILL_NAME_INDEX"
  fi
  # Index by filename stem
  stem=$(basename "$skill_file" .md)
  echo "$stem" >> "$SKILL_STEM_INDEX"
done

skill_count=$(sort -u "$SKILL_NAME_INDEX" "$SKILL_STEM_INDEX" | wc -l | tr -d ' ')
echo "Skills found: $skill_count"
echo ""

for skill_file in "$SKILLS_DIR"/*.md; do
  [ -f "$skill_file" ] || continue
  stem=$(basename "$skill_file" .md)
  echo "── $stem"

  # ── 1. Has frontmatter ─────────────────────────────────────────────────────
  first_line=$(head -1 "$skill_file")
  if [ "$first_line" = "---" ]; then
    ok "$stem: frontmatter opening ---"
  else
    fail "$stem: missing frontmatter opening ---"
    continue
  fi

  # ── 2. Required fields present ─────────────────────────────────────────────
  for field in "${REQUIRED_FIELDS[@]}"; do
    if grep -qE "^${field}:" "$skill_file"; then
      ok "$stem: has '$field'"
    else
      fail "$stem: missing required field '$field'"
    fi
  done

  # ── 3. Required sections present ───────────────────────────────────────────
  for section in "When to Use" "Prerequisites" "Procedure" "Verification"; do
    if grep -qE "^## ${section}" "$skill_file"; then
      ok "$stem: has '## $section'"
    else
      fail "$stem: missing '## $section' section"
    fi
  done

  # ── 4. Cross-reference check — backticked skill names ──────────────────────
  grep -oE '\`[a-z][a-z0-9-]+\`' "$skill_file" 2>/dev/null | sort -u | while IFS= read -r ref; do
    ref_clean=$(echo "$ref" | tr -d '`')
    # Skip common non-skill tokens and memory keys
    case "$ref_clean" in
      bash|json|ok|status|true|false|null|in-progress|wontfix|blocked|needs-design|current-task|notification-log|github-repo|last-deployment-url|rollback-log|triage-last-run|deployment-target|log-observer-state|product-brief|implementation-spec|auth-config|inngest-config|supabase-config|monitoring-config|health-failure-log|pending-approval)
        continue
        ;;
    esac
    if grep -Fxq "$ref_clean" "$SKILL_NAME_INDEX" || grep -Fxq "$ref_clean" "$SKILL_STEM_INDEX"; then
      ok "$stem: reference '$ref_clean' resolves"
    else
      warn "$stem: reference '$ref_clean' not found in skills/ — may be a workflow or external command"
    fi
  done || true

  # ── 5. No hardcoded secrets ────────────────────────────────────────────────
  if grep -Eqi '(api_key|token|password|secret)\s*=\s*[a-z0-9_-]{20,}' "$skill_file" 2>/dev/null; then
    fail "$stem: possible hardcoded secret detected — review file"
  else
    ok "$stem: no hardcoded secrets detected"
  fi

  echo ""
done

echo "================================"
printf "Passed: %d   Warned: %d   Failed: %d\n" $PASS $WARN $FAIL
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "Skill validation failed. Fix failures before committing."
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "Skills valid. Review warnings above — cross-references may be workflow names or external commands."
  exit 0
else
  echo "All skills valid."
  exit 0
fi
