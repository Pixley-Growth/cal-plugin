---
name: cal-onboard
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

#### CLAUDE.md Writing Principles

Every line must pass this test: **"Would removing this cause Claude to make mistakes?"**

**Include (decisions Claude can't reverse-engineer):**
- Style choices invisible in the codebase ("Use ES modules, not CommonJS")
- Boundaries with no code signal ("Don't touch /legacy")
- Workflow restrictions ("Run single tests, not the full suite")
- Approval/process gates with non-obvious semantics

**Exclude (noise that dilutes real instructions):**
- Standard language conventions Claude already knows
- How systems work (Claude can read the code)
- API documentation (link to it instead)
- Aspirational statements ("Write clean code", "Follow best practices")

**The bar:** If Claude could figure it out by reading your files, it doesn't belong in CLAUDE.md. The file should feel uncomfortably short.

**If CLAUDE.md does not exist:**
Generate a lean CLAUDE.md applying the principles above:
- Project name (one line)
- Non-obvious build/test/lint commands (only if not discoverable from package.json/Makefile)
- Cal plugin commands table
- Approval gates
- Brain file pointers
- Any project-specific decisions that have no code signal

**If CLAUDE.md exists:**
Offer to audit it:
1. Read the existing CLAUDE.md
2. Apply the litmus test to every line
3. Present findings: "These N lines pass the test. These M lines could be cut because [reason]."
4. Ask user: "Want me to trim it, suggest improvements, or leave it as-is?"

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
- `ood.md` — OOD violation detection

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

### 7. User Profile (Optional)

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
**Next:** Run /cal:next to start working
```
