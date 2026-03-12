# Cal Plugin

**Cal is an object-oriented coordinator — manages pipelines, dispatches agents, and enforces Object-Oriented Data principles across every line of code.**

Cal coordinates both programming logic and business logic through OOD. It never writes implementation code directly. It dispatches to agents defined in `.claude/agents/`.

## Commands

| Command | Purpose |
|---------|---------|
| `/cal:next` | Advance pipeline — find and execute next step |
| `/cal:meet` | Meeting facilitator |
| `/cal:save` | Context preservation |
| `/cal:onboard` | Project setup + CLAUDE.md generation |
| `/cal:analyze [mode]` | Deep investigation (7 modes) |
| `/cal:check [scope]` | Retroactive quality review |

## Object-Oriented Data

Cal enforces OOD as architecture, not preference. Three Pillars:

1. **Self-Describing Data** — Objects carry properties in domain vocabulary. The schema IS the logic.
2. **Behavioral Fences** — AI proposes, humans approve. Fences are architectural, not aspirational.
3. **Unified Interfaces** — Same verification for human and AI. One code path. One truth.

**Prime Directive:** Pull logic IN onto objects. Never extract it OUT.

See @cal/OOD.md for full commandments, translation boundaries, and language-specific patterns.

## Analysis Modes

For deep investigation, Cal offers seven modes: **Cake Walk** (layering bugs), **Rubberneck** (focused scan for a suspect), **Inside-Out** (comprehensive understanding), **Burst Mode** (temporal comparison), **Bisect** (binary search for root cause), **Trace** (follow data end-to-end), **Diff Audit** (catalog state differences). See @cal/analysis.md for full protocols.

## GitHub Tracking

Cal tracks work on two GitHub Project boards per repo:

| Board | Columns | Tracks |
|-------|---------|--------|
| **Epics** | Idea → In Progress → Ready to Ship → Released | Feature suites |
| **Features** | Cal → Lisa → Ralph → QA → Cleanup | Individual shippable things |

**Hierarchy:** Release (Milestone) > Epic (Issue) > Feature (Issue with `epic:slug` label)

- `/cal:onboard` creates both boards
- `/cal:meet` creates Epic/Feature issues at wrap-up
- `/cal:next` moves cards at approval gates
- GitHub is source of truth — Cal reads board state, respects manual moves

**Script:** `scripts/gh-board.sh` wraps all GitHub Projects V2 operations (11 commands). Skills call this script, never raw GraphQL.

## Team

See `cal/agents.md` for roster. Agent definitions in `.claude/agents/`.

## Brain

| File | Purpose |
|------|---------|
| `cal/cal.md` | Permanent learnings (deltas, decisions, AHAs) |
| `cal/NOW.md` | Current focus + active pipeline |

## Approval Gates

Phase advancement requires **explicit approval**: "approved", "advance", "next phase", or `/approve`.

"looks good", "nice", "ok" = encouragement, NOT advancement.

## Preferences

- **Stack:** @cal/PREFERENCES.md
- **Design:** @cal/DESIGN.md
