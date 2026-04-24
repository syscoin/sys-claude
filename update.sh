#!/usr/bin/env bash
# Deprecation wrapper — delegates to .claude/bin/update.sh once implemented.
set -euo pipefail

if [ -f ".claude/bin/update.sh" ]; then
  exec bash .claude/bin/update.sh "$@"
fi

echo "update.sh: .claude/bin/update.sh not yet implemented (v0.1.0 scaffold)."
echo "For manual update, re-run install.sh from the syscoin-claude-config source."
exit 1
