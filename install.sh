#!/usr/bin/env bash
set -euo pipefail

# Syscoin Claude Config Installer (SCAFFOLD)
# Usage:
#   bash install.sh /path/to/project
#   bash install.sh --agents /path/to/project   # installs into .agents/ instead of .claude/
#
# NOTE: This is a v0.1.0 scaffold. REPO_URL below is a placeholder until the
# config is published. For local testing, use SYSCOIN_CLAUDE_LOCAL_SRC:
#   SYSCOIN_CLAUDE_LOCAL_SRC=. bash install.sh /tmp/test-project

REPO_URL="${SYSCOIN_CLAUDE_REPO_URL:-https://github.com/PLACEHOLDER/syscoin-claude-config.git}"
SCRIPT_VERSION="dev"
BRANCH="main"

# Parse flags
AGENTS_ONLY=false
TARGET_ARG=""
for arg in "$@"; do
  case "$arg" in
    --agents) AGENTS_ONLY=true ;;
    *) TARGET_ARG="$arg" ;;
  esac
done

TARGET_DIR="${TARGET_ARG:-.}"
mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Set config directory name based on flag
if [ "$AGENTS_ONLY" = true ]; then
  CONFIG_DIR=".agents"
else
  CONFIG_DIR=".claude"
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Local source support for testing
if [ -n "${SYSCOIN_CLAUDE_LOCAL_SRC:-}" ] && [ -d "$SYSCOIN_CLAUDE_LOCAL_SRC/.claude" ]; then
  echo "Using local source: $SYSCOIN_CLAUDE_LOCAL_SRC"
  mkdir -p "$TEMP_DIR/repo"
  cp -r "$SYSCOIN_CLAUDE_LOCAL_SRC/.claude" "$TEMP_DIR/repo/.claude"
  cp "$SYSCOIN_CLAUDE_LOCAL_SRC/CLAUDE-syscoin.md" "$TEMP_DIR/repo/CLAUDE-syscoin.md"
  [ -f "$SYSCOIN_CLAUDE_LOCAL_SRC/.mcp.json" ] && cp "$SYSCOIN_CLAUDE_LOCAL_SRC/.mcp.json" "$TEMP_DIR/repo/.mcp.json"
  [ -f "$SYSCOIN_CLAUDE_LOCAL_SRC/.env.example" ] && cp "$SYSCOIN_CLAUDE_LOCAL_SRC/.env.example" "$TEMP_DIR/repo/.env.example"
  [ -f "$SYSCOIN_CLAUDE_LOCAL_SRC/.gitmodules" ] && cp "$SYSCOIN_CLAUDE_LOCAL_SRC/.gitmodules" "$TEMP_DIR/repo/.gitmodules"
else
  echo "Cloning repository..."
  git clone --recurse-submodules --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/repo" 2>&1 | tail -1 || {
    echo "ERROR: Could not clone $REPO_URL."
    echo "If testing locally, set SYSCOIN_CLAUDE_LOCAL_SRC=/path/to/this/repo and re-run."
    exit 1
  }
fi

# Read version from source
[ -f "$TEMP_DIR/repo/.claude/VERSION" ] && SCRIPT_VERSION="$(awk '{print $NF}' "$TEMP_DIR/repo/.claude/VERSION")"

echo "Installing Syscoin Claude Config v$SCRIPT_VERSION to: $TARGET_DIR ($CONFIG_DIR/)"

# Copy .claude/ as $CONFIG_DIR
echo "Copying $CONFIG_DIR/ configuration..."
mkdir -p "$TARGET_DIR/$CONFIG_DIR"

if [ -d "$TARGET_DIR/$CONFIG_DIR/agents" ]; then
  echo "Warning: $CONFIG_DIR/ already exists, merging..."
fi

# Directories: always overwrite with upstream
for dir in agents skills rules commands bin; do
  if [ -d "$TEMP_DIR/repo/.claude/$dir" ]; then
    cp -r "$TEMP_DIR/repo/.claude/$dir" "$TARGET_DIR/$CONFIG_DIR/"
  fi
done

# VERSION: always overwrite
[ -f "$TEMP_DIR/repo/.claude/VERSION" ] && cp "$TEMP_DIR/repo/.claude/VERSION" "$TARGET_DIR/$CONFIG_DIR/VERSION"

# Protected files: only copy if target doesn't exist
if [ -f "$TEMP_DIR/repo/.claude/settings.json" ] && [ ! -f "$TARGET_DIR/$CONFIG_DIR/settings.json" ]; then
  cp "$TEMP_DIR/repo/.claude/settings.json" "$TARGET_DIR/$CONFIG_DIR/settings.json"
fi

# MCP config: project root
if [ -f "$TEMP_DIR/repo/.mcp.json" ] && [ ! -f "$TARGET_DIR/.mcp.json" ]; then
  cp "$TEMP_DIR/repo/.mcp.json" "$TARGET_DIR/.mcp.json"
fi

# Copy CLAUDE-syscoin.md as CLAUDE.md
echo "Copying CLAUDE.md..."
if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  echo "Warning: CLAUDE.md already exists, backing up to CLAUDE.md.bak"
  cp "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md.bak"
fi
cp "$TEMP_DIR/repo/CLAUDE-syscoin.md" "$TARGET_DIR/CLAUDE.md"

# Add .gitignore entries
GITIGNORE="$TARGET_DIR/.gitignore"
EXT_PATTERN="$CONFIG_DIR/skills/ext/"
if [ -f "$GITIGNORE" ]; then
  if ! grep -qF "$EXT_PATTERN" "$GITIGNORE"; then
    echo "" >> "$GITIGNORE"
    echo "# External Claude skill submodules" >> "$GITIGNORE"
    echo "$EXT_PATTERN" >> "$GITIGNORE"
  fi
else
  echo "# External Claude skill submodules" > "$GITIGNORE"
  echo "$EXT_PATTERN" >> "$GITIGNORE"
fi

if ! grep -qF "CLAUDE.local.md" "$GITIGNORE"; then
  echo "CLAUDE.local.md" >> "$GITIGNORE"
fi

# Copy .env.example (and create .env if missing)
if [ -f "$TEMP_DIR/repo/.env.example" ]; then
  if [ ! -f "$TARGET_DIR/.env.example" ]; then
    cp "$TEMP_DIR/repo/.env.example" "$TARGET_DIR/.env.example"
  fi
  if [ ! -f "$TARGET_DIR/.env" ]; then
    cp "$TEMP_DIR/repo/.env.example" "$TARGET_DIR/.env"
    echo "Created .env from .env.example"
  fi
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET_DIR"
echo "  2. Edit .env to add your RPC URLs and keys"
echo "  3. Run 'claude' to start Claude Code with Syscoin config"
if [ "$AGENTS_ONLY" = true ]; then
  echo ""
  echo "Note: Installed into $CONFIG_DIR/ (--agents mode)."
fi
