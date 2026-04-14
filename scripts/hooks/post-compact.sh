#!/bin/bash
# Cal 4.0 — PostCompact hook
# Re-injects Current Work section after context compression.
# Lightweight — just reads from CLAUDE.md, no git/GitHub calls.

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"

if [[ ! -f "$CLAUDE_MD" ]]; then
  exit 0
fi

# Extract everything from "## Current Work" to end of file
python3 -c "
with open('$CLAUDE_MD', 'r') as f:
    content = f.read()
idx = content.find('## Current Work')
if idx >= 0:
    print(content[idx:].strip())
" 2>/dev/null || exit 0
