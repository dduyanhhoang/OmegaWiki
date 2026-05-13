#!/usr/bin/env bash
# ============================================================================
# OmegaWiki - Codex Setup
# ============================================================================
# Usage:
#   chmod +x setup-codex.sh && ./setup-codex.sh
#   chmod +x setup-codex.sh && ./setup-codex.sh --lang zh
#
# This is the Codex-native setup path. It does not modify setup.sh, .claude/,
# or CLAUDE.md. It creates repo-local Codex config, AGENTS.md, and native
# .agents/skills files.
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $1"; }

LANG_CODE="en"
ARGS=("$@")
for i in "${!ARGS[@]}"; do
  case "${ARGS[$i]}" in
    --lang=*) LANG_CODE="${ARGS[$i]#*=}" ;;
    --lang)   LANG_CODE="${ARGS[$((i+1))]}" ;;
  esac
done

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

[[ "$LANG_CODE" == "en" || "$LANG_CODE" == "zh" ]] || {
  fail "Unknown lang: $LANG_CODE (use 'en' or 'zh')"
  exit 1
}

I18N_DIR="$PROJECT_ROOT/i18n/$LANG_CODE"
[ -d "$I18N_DIR" ] || {
  fail "i18n/$LANG_CODE not found"
  exit 1
}

echo ""
echo "============================================"
echo "  OmegaWiki - Codex Setup"
echo "============================================"
echo ""

info "Checking prerequisites..."

if command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD="python3"
else
  fail "python3 not found. Install Python 3.9+ first."
  exit 1
fi

PY_VERSION=$("$PYTHON_CMD" --version 2>&1 | awk '{print $2}')
PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 9 ]; then
  ok "Python $PY_VERSION"
else
  fail "Python >= 3.9 required, found $PY_VERSION"
  exit 1
fi

if "$PYTHON_CMD" -m pip --version >/dev/null 2>&1; then
  ok "pip available"
else
  fail "pip not found. Install with: $PYTHON_CMD -m ensurepip"
  exit 1
fi

if command -v codex >/dev/null 2>&1; then
  ok "Codex CLI installed"
else
  warn "Codex CLI not found. Install Codex before using the generated skills."
fi

echo ""
info "Setting up Python environment..."

if [ -d ".venv" ]; then
  warn ".venv already exists, using it"
else
  "$PYTHON_CMD" -m venv .venv
  ok "Created .venv"
fi

VENV_PYTHON="$PROJECT_ROOT/.venv/bin/python"
if [ ! -x "$VENV_PYTHON" ] && [ -x "$PROJECT_ROOT/.venv/Scripts/python.exe" ]; then
  VENV_PYTHON="$PROJECT_ROOT/.venv/Scripts/python.exe"
fi
if [ ! -x "$VENV_PYTHON" ]; then
  fail "Could not find .venv Python executable"
  exit 1
fi

info "Installing dependencies into .venv..."
"$VENV_PYTHON" -m pip install -r requirements.txt -q
ok "Dependencies installed"

echo ""
info "Creating Codex repo-local files..."

if [ -f ".env" ]; then
  warn ".env already exists, not overwriting"
else
  cp .env.example .env
  ok "Created .env from template"
fi

mkdir -p .codex
if [ -f ".codex/config.toml" ]; then
  warn ".codex/config.toml already exists, not overwriting"
else
  cp config/codex.config.toml.example .codex/config.toml
  ok "Created .codex/config.toml"
fi

if [ -f "AGENTS.md" ]; then
  warn "AGENTS.md already exists, refreshing from $LANG_CODE runtime contract"
fi
{
  echo "# OmegaWiki - Codex Runtime Contract"
  echo ""
  echo "This is the Codex-native project instruction file. Edit this file directly for Codex-specific behavior, or rerun ./setup-codex.sh --lang $LANG_CODE to refresh it from the active OmegaWiki runtime contract."
  echo ""
  sed \
    -e 's/Claude Code/Codex/g' \
    -e 's/Claude/Codex/g' \
    -e 's/claude/codex/g' \
    -e 's/CLAUDE.md/AGENTS.md/g' \
    -e 's/setup\.sh/setup-codex.sh/g' \
    "$I18N_DIR/CLAUDE.md" |
    sed \
      -e '1{/^# /d;}' \
      -e '/^Edit `i18n\/.*\/AGENTS\.md`/d' \
      -e 's/Read `runtime\/AGENTS.md` before changing any rule./Read `runtime\/schema\/` and `runtime\/policy\/` before changing any rule./' \
      -e 's/| Changing the contract \/ regen[[:space:]]*| `runtime\/AGENTS.md` |/| Changing the contract \/ regen                        | `runtime\/schema\/`, `runtime\/policy\/`, `runtime\/templates\/` |/'
} > AGENTS.md
ok "Activated AGENTS.md ($LANG_CODE)"

rm -rf .agents/skills
mkdir -p .agents/skills/shared-references

SKILL_NAMES=(
  ask check daily-arxiv discover edit exp-design exp-eval exp-run exp-status
  ideate ingest init novelty paper-compile paper-draft paper-plan prefill
  rebuttal refine research reset review setup survey visualize
)

replace_skill_refs() {
  perl -pe 's{(?<![\w.~-])/(ask|check|daily-arxiv|discover|edit|exp-design|exp-eval|exp-run|exp-status|ideate|ingest|init|novelty|paper-compile|paper-draft|paper-plan|prefill|rebuttal|refine|research|reset|review|setup|survey|visualize)\b}{\$omegawiki-$1}g'
}

rewrite_for_codex() {
  sed \
    -e 's#\.claude/skills#.agents/skills#g' \
    -e 's#\.claude/#.agents/#g' \
    -e 's#\.claude#.agents#g' \
    -e 's/Claude Code/Codex/g' \
    -e "s/Claude's/Codex's/g" \
    -e 's/Claude/Codex/g' \
    -e 's/claude/codex/g' \
    -e 's/ANTHROPIC_API_KEY/OPENAI_API_KEY/g' \
    -e 's/CLAUDE.md/AGENTS.md/g' \
    -e 's/setup\.sh/setup-codex.sh/g' \
    -e 's#\.codex/skills#.agents/skills#g' \
    -e 's#config/setup-guide.md#config/codex-setup-guide.md#g' |
    replace_skill_refs
}

for name in "${SKILL_NAMES[@]}"; do
  src="$I18N_DIR/skills/$name"
  [ -d "$src" ] || continue

  dst=".agents/skills/omegawiki-$name"
  mkdir -p "$dst"

  while IFS= read -r file; do
    rel="${file#$src/}"
    out="$dst/$rel"
    mkdir -p "$(dirname "$out")"
    if [ "$rel" = "SKILL.md" ]; then
      {
        echo "---"
        echo "name: omegawiki-$name"
        desc=$(sed -n 's/^description:[[:space:]]*//p' "$file" | head -n 1)
        if [ -n "$desc" ]; then
          echo "description: $desc" | rewrite_for_codex
        else
          echo "description: Use the OmegaWiki $name workflow in Codex."
        fi
        sed -n 's/^argument-hint:[[:space:]]*/argument-hint: /p' "$file" | head -n 1
        echo "---"
        awk 'BEGIN { frontmatter = 0 } /^---$/ { frontmatter++; next } frontmatter >= 2 { print }' "$file" | rewrite_for_codex
      } > "$out"
    else
      rewrite_for_codex < "$file" > "$out"
    fi
  done < <(find "$src" -type f | sort)
done

for ref in "$I18N_DIR/shared-references"/*.md; do
  [ -f "$ref" ] || continue
  rewrite_for_codex < "$ref" > ".agents/skills/shared-references/$(basename "$ref")"
done

echo "$LANG_CODE" > .agents/.current-lang
ok "Activated Codex skills under .agents/skills ($LANG_CODE)"

echo ""
info "Verifying installation..."
ERRORS=0
WARNINGS=0

check_python_snippet() {
  local label="$1"
  local snippet="$2"
  if "$VENV_PYTHON" -c "$snippet" >/dev/null 2>&1; then
    ok "$label"
  else
    fail "$label missing"
    ERRORS=$((ERRORS+1))
  fi
}

check_tool_import() {
  local label="$1"
  local import_stmt="$2"
  if (cd tools && "$VENV_PYTHON" -c "$import_stmt") >/dev/null 2>&1; then
    ok "$label"
  else
    fail "$label import error"
    ERRORS=$((ERRORS+1))
  fi
}

check_python_snippet "PyMuPDF (fitz)" "import fitz"
check_python_snippet "requests" "import requests"
check_python_snippet "feedparser" "import feedparser"
check_tool_import "tools/init_discovery.py" "from init_discovery import prepare_inputs"
check_tool_import "tools/fetch_s2.py" "from fetch_s2 import search"
check_tool_import "tools/fetch_arxiv.py" "from fetch_arxiv import fetch_recent"
check_tool_import "tools/research_wiki.py" "from research_wiki import slugify"
check_tool_import "tools/lint.py" "from lint import check_missing_fields"

if "$VENV_PYTHON" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >/dev/null 2>&1; then
  if "$VENV_PYTHON" -c "import deepxiv_sdk" >/dev/null 2>&1; then
    ok "deepxiv-sdk (optional)"
  else
    warn "deepxiv-sdk unavailable; DeepXiv features will degrade but setup can continue"
    WARNINGS=$((WARNINGS+1))
  fi
else
  warn "Python < 3.10 detected inside .venv; deepxiv-sdk may be unavailable"
  WARNINGS=$((WARNINGS+1))
fi

echo ""
echo "============================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "  ${GREEN}Codex setup complete!${NC}"
elif [ $ERRORS -eq 0 ]; then
  echo -e "  ${YELLOW}Codex setup complete with $WARNINGS warning(s)${NC}"
else
  echo -e "  ${YELLOW}Codex setup complete with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
fi
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Start Codex from this repository root: codex"
echo "  2. Use \$omegawiki-setup to configure optional API keys."
echo "  3. Put papers in raw/papers/ and use \$omegawiki-init <topic>."
echo ""

exit "$ERRORS"
