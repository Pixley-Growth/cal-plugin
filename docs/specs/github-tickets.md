# Spec: GitHub Tickets

**Feature:** GitHub Project Board integration for Cal
**Date:** 2026-03-11
**Status:** Ready for implementation

---

## Overview

Integrate Cal with GitHub Projects V2 to track work through the Cal → Lisa → Ralph → QA → Cleanup pipeline. Two boards per repo. Three levels of hierarchy. GitHub is source of truth — Cal reads and writes but respects manual changes.

## Hierarchy

| Level | GitHub Mechanism | Board | Columns |
|-------|-----------------|-------|---------|
| **Release** | Milestone | — | — |
| **Epic** | Issue + label | Epics | Idea → In Progress → Ready to Ship → Released |
| **Feature** | Issue + `epic:slug` label | Features | Cal → Lisa → Ralph → QA → Cleanup |

A Release contains Epics. An Epic contains Features. Features have an `epic:slug` label linking them to their parent Epic.

## Scope

### In Scope
- Shell script wrapper (`scripts/gh-board.sh`) with 11 commands
- `/cal:onboard` creates both boards with correct columns
- `/cal:meet` creates Epic/Feature issues at wrap-up
- `/cal:next` moves Feature issues across columns at approval gates
- Epic auto-advancement based on Feature progress
- Feature auto-close when clearing Cleanup
- Graceful failure when gh CLI not configured

### Out of Scope
- GitHub Actions / CI integration
- PR auto-linking to issues
- Notifications / webhooks
- Cross-repo board views
- Analytics / burndown charts

---

## User Stories

### US-1: Board Setup via Onboard

**Description:** As a Cal user, I want `/cal:onboard` to create the two GitHub Project boards so tracking is ready from the start.

**Acceptance Criteria:**
- [ ] Running `/cal:onboard` on a repo with no boards creates "Epics" board with columns: Idea, In Progress, Ready to Ship, Released
- [ ] Running `/cal:onboard` on a repo with no boards creates "Features" board with columns: Cal, Lisa, Ralph, QA, Cleanup
- [ ] Running `/cal:onboard` on a repo that already has both boards skips creation (idempotent)
- [ ] If `gh` CLI is not authenticated, Cal warns and continues onboarding without boards

### US-2: Create Feature from Meet

**Description:** As a Cal user, when I wrap up a `/cal:meet` session, Cal creates a Feature issue on the Features board.

**Acceptance Criteria:**
- [ ] At meeting wrap-up, Cal asks "Is this an Epic or Feature?"
- [ ] If Feature: Cal asks "Which Epic does this belong to?" and lists existing Epics
- [ ] Feature issue is created with title from meeting topic, minimal body (one-liner)
- [ ] Feature issue gets `epic:slug` label matching its parent Epic
- [ ] Feature issue is placed in the "Cal" column on the Features board
- [ ] If `gh` is not configured, Cal warns and skips issue creation (meeting still completes)

### US-3: Create Epic from Meet

**Description:** As a Cal user, when I wrap up a `/cal:meet` session about a new feature suite, Cal creates an Epic issue on the Epics board.

**Acceptance Criteria:**
- [ ] If user selects "Epic" at wrap-up, Cal asks "Which Release does this belong to?"
- [ ] Cal lists existing Milestones or offers to create a new one
- [ ] Epic issue is created with title and minimal body
- [ ] Epic issue is placed in the "Idea" column on the Epics board
- [ ] Epic issue is attached to the selected Milestone

### US-4: Advance Feature via Next

**Description:** As a Cal user, when I `/approve` a phase in `/cal:next`, Cal moves the Feature issue to the next column.

**Acceptance Criteria:**
- [ ] Cal reads the Feature's current column from GitHub (source of truth)
- [ ] Cal moves the Feature to the column matching the new phase (name-matched)
- [ ] Phase-to-column mapping: Cal→Lisa, Lisa→Ralph, Ralph→QA, QA→Cleanup
- [ ] If Feature is manually in a different column than expected, Cal works from that position

### US-5: Feature Auto-Close and Epic Advancement

**Description:** When a Feature clears Cleanup, Cal closes it. When all Features for an Epic are closed, Cal advances the Epic.

**Acceptance Criteria:**
- [ ] When a Feature moves past Cleanup, Cal closes the Feature issue
- [ ] When the first Feature for an Epic enters the Features board, the Epic moves to "In Progress"
- [ ] When all Features for an Epic are closed, the Epic moves to "Ready to Ship"
- [ ] Epic "Released" is manual (tied to actual App Store submission)

### US-6: Shell Script Wrapper

**Description:** A shared shell script at `scripts/gh-board.sh` provides atomic GitHub operations for Cal skills.

**Acceptance Criteria:**
- [ ] Script is executable (`chmod +x`) with bash shebang
- [ ] Supports 11 commands: `ensure-boards`, `create-issue`, `move-card`, `get-card-column`, `create-milestone`, `list-epics-for-milestone`, `list-features-for-epic`, `get-board-state`, `get-issue-by-title`, `close-issue`, `set-milestone-on-issue`
- [ ] Each command exits 0 on success, non-zero on failure
- [ ] Returns JSON or plain text output that Cal can parse
- [ ] Gracefully handles: gh not installed, not authenticated, no remote, API errors

---

## Technical Design

### scripts/gh-board.sh

**Location:** `scripts/gh-board.sh` (plugin root)
**Referenced as:** `${CLAUDE_PLUGIN_ROOT}/scripts/gh-board.sh`

**Command interface:**
```bash
gh-board.sh <command> [args...]

# Board management
gh-board.sh ensure-boards                          # Create both boards if missing
gh-board.sh get-board-state <board-name>            # Dump full board state

# Issue operations
gh-board.sh create-issue <title> <body> [labels]    # Create issue, return issue number
gh-board.sh get-issue-by-title <title>              # Find issue by title, return number
gh-board.sh close-issue <issue-number>              # Close an issue
gh-board.sh set-milestone-on-issue <issue> <milestone>

# Card operations
gh-board.sh move-card <issue-number> <board> <column>  # Move issue to column
gh-board.sh get-card-column <issue-number> <board>     # Get current column

# Milestone operations
gh-board.sh create-milestone <title>                # Create milestone, return name
gh-board.sh list-epics-for-milestone <milestone>    # List Epic issues in milestone

# Relationship queries
gh-board.sh list-features-for-epic <epic-slug>      # List Features with epic:slug label
```

**Error handling:** Every command checks `gh auth status` first. If not authenticated, prints warning to stderr and exits 1. Cal skills check exit code and skip board operations on failure.

### Skill Modifications

**`/cal:onboard`** — Add step after agent/rule creation:
```
### 7. GitHub Project Boards
Call scripts/gh-board.sh ensure-boards
Report: boards created / already exist / skipped (gh not configured)
```

**`/cal:meet`** — Add wrap-up sequence after meeting minutes:
```
1. Ask: "Is this an Epic or Feature?"
2. Route to Epic or Feature creation flow
3. Create issue via gh-board.sh create-issue
4. Place on board via gh-board.sh move-card
5. Report: issue created with link, or skipped
```

**`/cal:next`** — Add to approval gate:
```
1. Read current Feature column via gh-board.sh get-card-column
2. Move to next column via gh-board.sh move-card
3. If past Cleanup: close issue via gh-board.sh close-issue
4. Check Epic status: if all Features closed, move Epic to Ready to Ship
5. Report: card moved, or skipped
```

### Label Convention

| Label | Applied to | Purpose |
|-------|-----------|---------|
| `type:epic` | Epic issues | Identify Epics |
| `type:feature` | Feature issues | Identify Features |
| `epic:<slug>` | Feature issues | Link Feature to parent Epic |

---

## Implementation Phases

### Phase 1: Shell Script Foundation
- [ ] Create `scripts/gh-board.sh` with all 11 commands
- [ ] `chmod +x`, add shebang
- [ ] Implement `ensure-boards` (creates both boards with correct columns)
- [ ] Implement basic CRUD: `create-issue`, `close-issue`, `move-card`, `get-card-column`
- [ ] Implement queries: `get-issue-by-title`, `get-board-state`
- [ ] Implement milestone ops: `create-milestone`, `set-milestone-on-issue`, `list-epics-for-milestone`
- [ ] Implement `list-features-for-epic`
- [ ] Error handling: auth check, graceful failures
- **Verification:** Run `gh-board.sh ensure-boards` on this repo. Boards appear on GitHub.

### Phase 2: Onboard Integration
- [ ] Update `skills/cal-onboard/SKILL.md` with board creation step
- [ ] Cal calls `ensure-boards` during onboard
- [ ] Reports board status in onboard output
- **Verification:** Run `/cal:onboard` on this repo. Boards created.

### Phase 3: Meet Integration
- [ ] Update `skills/cal-meet/SKILL.md` with wrap-up issue creation flow
- [ ] Epic creation: asks Release, creates Milestone if needed, creates Epic issue, places on Epics board
- [ ] Feature creation: asks Epic, creates Feature issue with `epic:slug` label, places on Features board
- [ ] Graceful skip if gh not configured
- **Verification:** Run `/cal:meet`, wrap up. Issue appears on board.

### Phase 4: Next Integration
- [ ] Update `skills/cal-next/SKILL.md` with card advancement at approval gates
- [ ] Read current column from GitHub (source of truth)
- [ ] Move to next column (name-matched)
- [ ] Auto-close Feature when clearing Cleanup
- [ ] Auto-advance Epic when all Features closed
- [ ] Graceful skip if gh not configured
- **Verification:** Run `/cal:next`, approve. Card moves on board.

---

## Definition of Done

This feature is complete when:
- [ ] All user stories pass acceptance criteria
- [ ] `scripts/gh-board.sh` handles all 11 commands
- [ ] `/cal:onboard` creates boards on a fresh repo
- [ ] `/cal:meet` creates issues at wrap-up
- [ ] `/cal:next` moves cards at approval gates
- [ ] Dogfooded: this feature is tracked on its own board on the Cal repo

---

## Open Questions

*None remaining — resolved during interview.*

---

## Implementation Notes

*To be filled during implementation.*
