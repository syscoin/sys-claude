#!/usr/bin/env bash
# Config integrity checker for syscoin-claude-config.
# v0.1.0 scaffold — only checks scaffold files exist. Expand as components land.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0

check() {
  if [ -e "$ROOT/$1" ]; then
    echo "✓ $1"
  else
    echo "✗ $1 (MISSING)"
    FAIL=1
  fi
}

echo "Validating syscoin-claude-config scaffold..."
echo ""

# Top-level
check "CLAUDE.md"
check "CLAUDE-syscoin.md"
check "README.md"
check "QUICK-START.md"
check "LICENSE"
check "install.sh"
check "update.sh"
check "validate.sh"
check ".env.example"
check ".mcp.json"
check ".gitignore"
check ".gitmodules"

# .claude/
check ".claude/VERSION"
check ".claude/CHANGELOG.md"
check ".claude/settings.json"
check ".claude/agents"
check ".claude/bin"
check ".claude/commands"
check ".claude/rules"
check ".claude/skills"
check ".claude/skills/ext"

# tests
check "tests"
check ".github/workflows"

# JSON syntax checks
if command -v jq >/dev/null 2>&1; then
  echo ""
  echo "Checking JSON syntax..."
  for f in .claude/settings.json .mcp.json; do
    if jq empty "$ROOT/$f" 2>/dev/null; then
      echo "✓ $f (valid JSON)"
    else
      echo "✗ $f (INVALID JSON)"
      FAIL=1
    fi
  done
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "✅ Scaffold validation passed."
else
  echo "❌ Scaffold validation failed."
  exit 1
fi
