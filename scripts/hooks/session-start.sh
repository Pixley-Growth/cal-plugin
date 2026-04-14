#!/bin/bash
# Cal 4.0 — SessionStart hook
# Reads git + GitHub state, updates Current Work section in CLAUDE.md, outputs briefing.

set -euo pipefail

# Find the project root (where CLAUDE.md lives)
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
HOTFIX_STATE="$PROJECT_ROOT/cal/active-hotfix.json"

# Bail if no CLAUDE.md (not a Cal project)
if [[ ! -f "$CLAUDE_MD" ]]; then
  exit 0
fi

# --- Gather git state ---
BRANCH="$(git branch --show-current 2>/dev/null || echo 'detached')"
LAST_COMMIT="$(git log --oneline -1 2>/dev/null || echo 'no commits')"
BRANCHES="$(git branch --format='%(refname:short)' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')"

# --- Check for hotfix state ---
MODE="normal"
HOTFIX_INFO=""
MERGE_DEBT=""
if [[ -f "$HOTFIX_STATE" ]]; then
  MODE="hotfix"
  HOTFIX_BRANCH="$(python3 -c "import json; print(json.load(open('$HOTFIX_STATE'))['hotfixBranch'])" 2>/dev/null || echo 'unknown')"
  PARKED_BRANCH="$(python3 -c "import json; print(json.load(open('$HOTFIX_STATE'))['parkedBranch'])" 2>/dev/null || echo 'unknown')"
  HOTFIX_INFO="**Hotfix:** \`$HOTFIX_BRANCH\` (parked: \`$PARKED_BRANCH\`)"

  # Check merge debt
  HOTFIX_COMMITS="$(git log main.."$HOTFIX_BRANCH" --oneline 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$HOTFIX_COMMITS" -gt 0 ]]; then
    MERGE_DEBT="**Merge debt:** $HOTFIX_COMMITS commits on \`$HOTFIX_BRANCH\` not yet in main"
  fi
fi

# --- Check for active GitHub ticket (best effort) ---
TICKET_INFO="_No active ticket. Run \`/cal:next\` to pick up work._"
GH_BOARD_SCRIPT="$PROJECT_ROOT/scripts/gh-board.sh"
if [[ -x "$GH_BOARD_SCRIPT" ]]; then
  # Try to get board state, but don't fail if gh isn't configured
  BOARD_STATE="$("$GH_BOARD_SCRIPT" get-board-state "Features" 2>/dev/null || echo '')"
  if [[ -n "$BOARD_STATE" ]]; then
    # Extract items in active columns (Cal, Lisa, Ralph, QA)
    ACTIVE="$(echo "$BOARD_STATE" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for col in ['Cal', 'Lisa', 'Ralph', 'QA']:
        items = data.get(col, [])
        for item in items:
            title = item.get('title', 'Unknown')
            num = item.get('number', '?')
            print(f'#{num} — {title} ({col})')
except:
    pass
" 2>/dev/null || echo '')"
    if [[ -n "$ACTIVE" ]]; then
      TICKET_INFO="$ACTIVE"
    fi
  fi
fi

# --- Build the Current Work section ---
SECTION="## Current Work

<!-- Cal maintains this section. Updated by skills and SessionStart hook. -->
**Branch:** \`$BRANCH\`
**Last commit:** $LAST_COMMIT
**Branches:** $BRANCHES
**Mode:** $MODE"

if [[ -n "$HOTFIX_INFO" ]]; then
  SECTION="$SECTION
$HOTFIX_INFO"
fi

if [[ -n "$MERGE_DEBT" ]]; then
  SECTION="$SECTION
$MERGE_DEBT"
fi

SECTION="$SECTION
**Active:** $TICKET_INFO"

# --- Update CLAUDE.md ---
# Replace everything from "## Current Work" to the end of file
if grep -q "^## Current Work" "$CLAUDE_MD"; then
  # Use python for reliable multiline replacement
  python3 -c "
import re
with open('$CLAUDE_MD', 'r') as f:
    content = f.read()
new_section = '''$SECTION'''
content = re.sub(r'## Current Work.*', new_section, content, flags=re.DOTALL)
with open('$CLAUDE_MD', 'w') as f:
    f.write(content)
"
fi

# --- Output briefing to conversation context ---
echo "$SECTION"
