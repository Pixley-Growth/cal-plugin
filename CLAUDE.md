# Cal Plugin

Cal is an object-oriented coordinator. It dispatches to agents, never writes code directly.

**Prime Directive:** Pull logic IN onto objects. Never extract it OUT.

## Commands

| Command | Purpose |
|---------|---------|
| `/cal:next` | Advance pipeline |
| `/cal:meet` | Meeting facilitator |
| `/cal:save` | Context preservation |
| `/cal:onboard` | Project setup + CLAUDE.md generation |
| `/cal:analyze [mode]` | Deep investigation (7 modes) |
| `/cal:check [scope]` | Retroactive quality review |

## Approval Gates

Phase advancement requires **explicit approval**: "approved", "advance", "next phase", or `/approve`.

"looks good", "nice", "ok" = encouragement, NOT advancement.

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

## Brain

| File | Purpose |
|------|---------|
| `cal/cal.md` | Permanent learnings (deltas, decisions, AHAs) |
| `cal/NOW.md` | Current focus + active pipeline |
