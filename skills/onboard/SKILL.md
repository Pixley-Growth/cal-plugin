---
name: onboard
description: "Project setup - scan codebase, create Cal structure, generate or improve CLAUDE.md"
---

# Onboard — Project Setup

**Purpose:** Set up Cal for a new project or improve an existing setup.

## Protocol

### 1. Scan Codebase

Glob for common patterns to understand the project:

```
package.json      → Node.js/JavaScript
tsconfig.json     → TypeScript
Cargo.toml        → Rust
pyproject.toml    → Python
go.mod            → Go
Package.swift     → Swift
next.config.js    → Next.js
vite.config.ts    → Vite
supabase/         → Supabase
prisma/           → Prisma
```

Report what was detected:

```markdown
## Codebase Overview

**Languages:** [detected]
**Frameworks:** [detected]
**Database:** [detected]
**Structure:** [key directories]
```

### 2. CLAUDE.md Generation

**If CLAUDE.md does not exist:**
Generate an optimized CLAUDE.md with:
- Project name and description
- Detected stack and frameworks
- Build/test/lint commands (detected from package.json, Makefile, etc.)
- Cal plugin configuration (commands table, brain files, team reference)
- @imports for cal/ reference files

**If CLAUDE.md exists:**
Scan it and suggest improvements:
- Missing build commands
- Stale references
- Missing Cal sections (commands, brain, team)
- Opportunities for @imports

Present suggestions to user for approval. Do not overwrite without confirmation.

### 3. Create Cal Structure

Create the cal/ directory if it doesn't exist:

```
cal/
├── cal.md              # Permanent learnings journal
├── agents.md           # Team roster
├── NOW.md              # Current focus + pipeline
├── analysis.md         # Analysis mode protocols
├── memories/           # Ephemeral session context
├── OOD.md              # Code principles
├── DESIGN.md           # Visual design system
├── PREFERENCES.md      # Infrastructure stack
└── analyses/           # Analysis journals
```

Only create files that don't already exist. Never overwrite existing cal/ files.

Also create:

```
ideas/
└── hopper.md           # Idea parking lot (unstructured)
```

### 4. Create Behavioral Rules

Create `.claude/rules/` with Cal behavioral rules if they don't exist:
- `coordinator.md` — Dispatch behavior + approval gates
- `tone-awareness.md` — Frustration/joy detection
- `squirrel.md` — Drift/scope creep detection
- `delta.md` — Wrong assumption detection

### 5. Create Agent Definitions

Create `.claude/agents/` with default team if they don't exist:
- `coder.md` — Implementation agent (Sonnet)
- `reviewer.md` — Code review agent (Opus)
- `architect.md` — Architecture advisor (Opus)

### 6. Suggest Additional Agents

Based on detected patterns:

| Pattern Detected | Agent Suggested | Why |
|------------------|-----------------|-----|
| TypeScript | typescript-checker | Type verification |
| Supabase | supabase-validator | RLS and schema validation |
| Large codebase | atomizer | Extraction and size limits |
| Security-sensitive | security-auditor | Security scanning |

### 7. GitHub Project Boards

Create the two tracking boards on the repo's GitHub Project:

```bash
scripts/gh-board.sh ensure-boards
```

This creates:
- **Epics** board with columns: Idea, In Progress, Ready to Ship, Released
- **Features** board with columns: Cal, Lisa, Ralph, QA, Cleanup

If boards already exist, this is a no-op. If `gh` CLI is not authenticated or no remote exists, warn and skip — boards are optional for Cal to function.

Report board status:
- `Boards: created Epics, Features` (new)
- `Boards: already exist` (idempotent)
- `Boards: skipped (gh not configured)` (graceful failure)

### 8. User Profile (Optional)

Offer to set up a user profile at `~/.claude/cal/USER-PROFILE.md`:
- Professional background
- Technical proficiency
- Communication preferences

## Re-Onboarding

Running `/cal:onboard` again:
- Re-scans codebase (patterns may have changed)
- Does NOT overwrite existing cal/ files
- Suggests CLAUDE.md improvements
- Updates agent suggestions based on new patterns

## Output

After onboarding:

```
## Onboarding Complete

**Project:** [name]
**Stack:** [detected]
**Created:** [list of new files]
**CLAUDE.md:** [generated / improved / unchanged]
**Agents:** [list]
**Boards:** [created / already exist / skipped]
**Next:** Run /cal:next to start working
```
