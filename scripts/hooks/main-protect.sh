#!/bin/bash
# Cal 4.0 — PreToolUse hook for main branch protection
# Blocks git commit on main unless message contains [release] or [hotfix-merge].
# Reads tool input from stdin (JSON).
# Exit 0 = allow, Exit 2 = block.

set -euo pipefail

INPUT="$(cat)"

# Extract the bash command from tool input
COMMAND="$(echo "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    cmd = data.get('tool_input', {}).get('command', '')
    print(cmd)
except:
    print('')
" 2>/dev/null || echo '')"

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Only care about git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Check if we're on main
BRANCH="$(git branch --show-current 2>/dev/null || echo '')"
if [[ "$BRANCH" != "main" ]]; then
  exit 0
fi

# On main with a git commit — check for override tags
if echo "$COMMAND" | grep -qE '\[release\]|\[hotfix-merge\]'; then
  exit 0
fi

echo "Main is protected. Commit to a feature or hotfix branch instead. Override with [release] or [hotfix-merge] in commit message." >&2
exit 2
