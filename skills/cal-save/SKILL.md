---
name: cal-save
description: "Context preservation - route learnings to cal.md (permanent) or memories/ (ephemeral)"
argument-hint: "type content - Save type (delta, aha, memory, decision, session) and content to preserve"
---

# Save — Context Preservation

**Purpose:** Preserve learnings and context with appropriate routing.

Arguments provided: $ARGUMENTS

## Core Principle

**Extract the learning, let the output vanish.**

Agent outputs are scaffolding. Once you've acted on them, the output doesn't matter — only the extracted insight does.

## Routing

| Type | Destination | Lifespan |
|------|-------------|----------|
| `delta` | `cal/cal.md` | Permanent |
| `aha` | `cal/cal.md` | Permanent |
| `memory` | `cal/cal.md` | Permanent |
| `decision` | `cal/cal.md` | Permanent |
| `session` | `cal/memories/YYYY-MM-DD.md` | Prunable |

## Usage

```bash
# Permanent learnings → cal/cal.md
/cal:save delta "BELIEVED: X, ACTUAL: Y, DELTA: Z"
/cal:save aha "scope creep happens when..."
/cal:save memory "user prefers Socratic method"
/cal:save decision "chose X over Y because..."

# Ephemeral context → cal/memories/
/cal:save session  # Full context dump for resume
```

## Entry Schema

All entries follow this format:

```markdown
## [ISO-8601-DATE] [TYPE] — [TOPIC]

[Content]

---
```

## Session Save Template

Session saves go to `cal/memories/YYYY-MM-DD.md`:

```markdown
## [TIME] SESSION — [Topic]

**Working on:** [Current task]
**Branch:** [Git branch]
**Uncommitted:** [Yes/No]

### This Session
- [What was accomplished]

### Resume With
- [Next steps]

### Hot Context
- [Critical details needed to continue]
```

## What Does NOT Get Saved

| Output Type | Example | Do |
|-------------|---------|-----|
| Routine checks | "typescript: 0 errors" | Let vanish |
| Confirmations | "spec looks clean" | Let vanish |
| Agent reviews | 200-line review output | Extract learning, discard output |

## Location Check

On save, verify `cal/cal.md` exists. If not, create it with header.

## Size Guidance

If `cal/cal.md` exceeds 300 lines, review and consolidate entries.
