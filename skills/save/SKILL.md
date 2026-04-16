---
name: save
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

| Type | Destination | Section in cal.md | Lifespan |
|------|-------------|-------------------|----------|
| `delta` | `cal/cal.md` | `## Deltas` | Permanent (Auto Dream prunes resolved) |
| `aha` | `cal/cal.md` | `## Principles Learned` | Permanent |
| `memory` | `cal/cal.md` | `## Active Context` | Prunable by Auto Dream when stale |
| `decision` | `cal/cal.md` | `## Decisions` | Permanent |
| `session` | `cal/memories/YYYY-MM-DD.md` | — | Prunable |

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

Entries are **atomic bullets** appended to the correct section in `cal/cal.md`:

```markdown
- **[topic] ([YYYY-MM-DD]):** BELIEVED: X. ACTUAL: Y. DELTA: Z.
- **[topic] ([YYYY-MM-DD]):** CHOICE: X. RATIONALE: Y. REVISIT-IF: Z.
- **[topic] ([YYYY-MM-DD]):** [principle or context]
```

One insight per bullet. Date in parentheses for Auto Dream pruning. No heading blocks.

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

On save, verify `cal/cal.md` exists. If not, create it with the full template including all four sections:

```markdown
# Cal Brain

Cal's persistent project knowledge. Organized by topic, not chronologically.
Auto Dream consolidates entries between sessions — keep entries atomic and topical.

---

## Principles Learned

*Patterns promoted from repeated experience.*

---

## Deltas

*Wrong assumptions corrected. BELIEVED / ACTUAL / DELTA format.*

---

## Decisions

*Architectural choices with rationale. CHOICE / RATIONALE / REVISIT-IF format.*

---

## Active Context

*Current state that helps orient new sessions. Auto Dream prunes when stale.*
```

## Size Guidance

If `cal/cal.md` exceeds 300 lines, review and consolidate entries.

## Dream-Friendly Format

`cal/cal.md` is organized by **topic** (Principles, Deltas, Decisions, Active Context) not chronologically. This structure supports Auto Dream consolidation:

- **Principles Learned** — Patterns promoted from experience. Dream may merge related principles.
- **Deltas** — Wrong assumptions. Dream prunes when the correction is no longer relevant.
- **Decisions** — Choices with rationale. Dream preserves unless explicitly revisited.
- **Active Context** — Current state. Dream prunes when stale.

When saving, append to the correct section. Keep entries atomic — one insight per bullet.
