#!/bin/bash
# Cal 4.0 — PreToolUse hook for OOD enforcement
# Blocks creation of files matching OOD anti-patterns.
# Reads tool input from stdin (JSON).
# Exit 0 = allow, Exit 2 = block (stderr shown to Claude).

set -euo pipefail

# Read the tool input from stdin
INPUT="$(cat)"

# Extract the file path from the tool input
FILE_PATH="$(echo "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    # Handle both Write (file_path) and Edit (file_path) tools
    path = data.get('tool_input', {}).get('file_path', '')
    print(path)
except:
    print('')
" 2>/dev/null || echo '')"

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Extract just the filename
FILENAME="$(basename "$FILE_PATH")"

# Check against OOD anti-patterns (case-insensitive)
PATTERNS=(
  "[Uu]tils\."
  "[Hh]elper[s]?\."
  "[Ss]ervice[s]?\."
  "[Mm]anager[s]?\."
  "[Cc]alculator[s]?\."
)

for PATTERN in "${PATTERNS[@]}"; do
  if echo "$FILENAME" | grep -qE "$PATTERN"; then
    echo "OOD VIOLATION: '$FILENAME' — logic belongs on domain objects, not in utility files. See cal/OOD.md." >&2
    exit 2
  fi
done

exit 0
