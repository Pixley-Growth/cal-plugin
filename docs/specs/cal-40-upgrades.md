# Cal 4.0: Delivery Pipeline + Modernization

**Status:** Spec Complete
**Date:** 2026-04-14
**Origin:** DockPops hotfix cycle (2.0→2.1) exposed Cal's blindness to branches, releases, merge chains, and tester feedback. Research into April 2026 Claude Code best practices revealed Cal uses zero hooks and loads ~940 lines of always-on context.

---

## Problem Statement

Cal tracks tasks and project knowledge but is blind to the delivery pipeline:
- Doesn't know what branch you're on or what it represents
- Can't detect you parked feature work to do a hotfix
- Has no awareness of merge chains (hotfix → main → feature)
- Can't persist context about who's testing what across sessions
- Uses zero hooks (the single biggest gap vs. 2026 best practices)
- Loads analysis protocols and design system every session regardless of relevance

## Scope

### In Scope
- **Track A: Delivery Pipeline** — `/cal:hotfix`, `/cal:hotfix-done`, branch model enforcement, merge chain guidance
- **Track B: Modernization** — 4 hooks, CLAUDE.md restructure (kill NOW.md, add dynamic section), agent frontmatter, analysis mode split

### Out of Scope
- Tester registry (project-specific, not Cal-generic)
- Feedback/TestFlight tracking (project-specific)
- Managed Agents / cloud-hosted Cal
- Agent Teams (experimental, evaluate post-4.0)
- LSP plugins
- `/loop` or cloud routines

---

## Architecture Decisions

### AD-1: Branch Model — GitHub Flow + Tags
- **Main = latest shipped version.** Always shippable.
- **Tags mark releases** (v2.0, v2.1).
- **Feature branches** fork off main, merge back when ready.
- **Hotfix branches** fork off main → fix → merge to main → tag → merge forward into feature branches.
- **Enforced:** PreToolUse hook blocks commits to main unless message contains `[release]` or `[hotfix-merge]`. Override available.

### AD-2: Kill NOW.md
- NOW.md is redundant. GitHub board tracks work items. Git tracks branches.
- Replace with dynamic `## Current Work` section in project CLAUDE.md.
- Cal skills write meaningful state transitions.
- SessionStart hook syncs from git + GitHub.
- PostCompact hook re-injects after context compression.

### AD-3: CLAUDE.md Restructure
- OOD.md stays always-loaded (~200 lines). It's Cal's identity.
- Analysis mode **selection guide** stays (~15 lines). Full protocols move to `cal-analyze` skill.
- Design system (DESIGN.md, ~400 lines) moves to a skill.
- Preferences (~40 lines) stays — small and always relevant.
- Dynamic `## Current Work` section added.

### AD-4: Hotfix Uses Worktrees
- `/cal:hotfix` creates a git worktree for the hotfix branch. No WIP commits needed.
- Feature branch stays untouched in the main worktree.
- Leverages native Claude Code worktree support.

### AD-5: Hybrid CLAUDE.md Updates
- Cal skills (`/cal:hotfix`, `/cal:next`, `/cal:hotfix-done`) write intentional state transitions.
- SessionStart hook reads git + GitHub and refreshes the Current Work section.
- PostCompact hook re-injects the section after context compression.

### AD-6: Guided Merge Chain
- On `/cal:hotfix-done`, Cal walks the merge chain step by step.
- At each merge: shows what will merge, asks for confirmation, attempts the merge, reports conflicts.
- Never auto-resolves conflicts. Always asks.

### AD-7: Agent Isolation
- Coder agent gets `isolation: worktree` for feature work.
- Quick fixes and hotfixes run inline (no worktree overhead).
- Cal decides based on task complexity.

---

## User Stories

### US-1: CLAUDE.md Restructure
**Description:** Restructure Cal's CLAUDE.md to remove always-loaded context that should be on-demand, and add a dynamic Current Work section.

**Acceptance Criteria:**
- [ ] Analysis mode full protocols removed from `cal/analysis.md` import, moved into `skills/cal-analyze/SKILL.md`
- [ ] Analysis mode selection guide (~15 lines: table + "when user says X, suggest mode Y") remains in CLAUDE.md
- [ ] DESIGN.md import removed from CLAUDE.md, accessible via new `cal-design` skill
- [ ] OOD.md import remains unchanged
- [ ] PREFERENCES.md import remains unchanged
- [ ] `## Current Work` section placeholder added to CLAUDE.md
- [ ] NOW.md deleted (or moved to archive)
- [ ] CLAUDE.md total imported lines reduced by ~700 lines

### US-2: SessionStart Hook
**Description:** A hook that fires on session start, reads git + GitHub state, and writes the Current Work section in CLAUDE.md.

**Acceptance Criteria:**
- [ ] Hook defined in `.claude/settings.local.json` under `hooks.SessionStart`
- [ ] Hook reads: current branch name, last commit (short hash + message), list of local branches with last commit dates
- [ ] Hook reads GitHub board state via `scripts/gh-board.sh` (active ticket, current column)
- [ ] Hook writes `## Current Work` section in project CLAUDE.md with: active ticket, branch, mode (normal/hotfix), merge debt if any
- [ ] If hotfix state file exists (`cal/active-hotfix.json`), includes hotfix briefing
- [ ] Section is idempotent — running twice produces same output

### US-3: PostCompact Hook
**Description:** After context compression, re-inject the Current Work section so pipeline state is never lost mid-session.

**Acceptance Criteria:**
- [ ] Hook defined in `.claude/settings.local.json` under `hooks.PostCompact`
- [ ] Hook reads the `## Current Work` section from CLAUDE.md
- [ ] Outputs the section content so it's injected into the compressed context
- [ ] Lightweight — just reads a file section, no git/GitHub calls

### US-4: PreToolUse Hook — OOD Enforcement
**Description:** Block creation of files matching OOD anti-patterns.

**Acceptance Criteria:**
- [ ] Hook defined for `PreToolUse` on `Write` and `Edit` tools
- [ ] Rejects file creation when path matches: `*Utils.*`, `*Helper.*`, `*Service.*`, `*Manager.*`, `*Calculator.*`
- [ ] Returns clear error: `OOD VIOLATION: [filename] — logic belongs on domain objects, not in utility files`
- [ ] Does not fire on file reads, only writes/creates

### US-5: PreToolUse Hook — Main Branch Protection
**Description:** Block direct commits to main unless explicitly tagged.

**Acceptance Criteria:**
- [ ] Hook defined for `PreToolUse` on `Bash` tool
- [ ] Detects `git commit` commands when current branch is `main`
- [ ] Blocks unless commit message contains `[release]` or `[hotfix-merge]`
- [ ] Returns clear message: `Main is protected. Commit to a feature or hotfix branch. Override with [release] or [hotfix-merge] in commit message.`
- [ ] Does not block `git merge` commands (merging into main is the intended flow)

### US-6: Stop Hook — Verification
**Description:** When an agent finishes, verify the work before reporting success.

**Acceptance Criteria:**
- [ ] Hook defined for `Stop` event, type `agent` (multi-turn with tool access)
- [ ] Runs after coder agent completes
- [ ] Checks: no OOD violations in changed files, tests pass (if test command exists), no `*Utils.*` files created
- [ ] Reports findings back — does not auto-fix, just flags issues

### US-7: `/cal:hotfix` Skill
**Description:** Structured entry into hotfix mode using git worktrees.

**Acceptance Criteria:**
- [ ] Skill defined at `skills/cal-hotfix/SKILL.md`
- [ ] Detects current branch and uncommitted changes
- [ ] If uncommitted changes: warns and asks to commit or stash first
- [ ] Creates hotfix branch off main: `hotfix/<version>` (e.g., `hotfix/2.1`)
- [ ] Creates git worktree at `.worktrees/hotfix-<version>/`
- [ ] Records hotfix state in `cal/active-hotfix.json`:
  ```json
  {
    "hotfixBranch": "hotfix/2.1",
    "basedOn": "main",
    "basedOnCommit": "abc1234",
    "parkedBranch": "3.0",
    "worktreePath": ".worktrees/hotfix-2.1",
    "mergeChain": ["hotfix/2.1", "main", "3.0"],
    "started": "2026-04-14"
  }
  ```
- [ ] Updates `## Current Work` in CLAUDE.md to reflect hotfix mode
- [ ] Outputs briefing: "Hotfix worktree created. You're on `hotfix/2.1`. Feature branch `3.0` is untouched. When done, run `/cal:hotfix-done`."

### US-8: `/cal:hotfix-done` Skill
**Description:** Structured exit from hotfix mode with guided merge chain.

**Acceptance Criteria:**
- [ ] Skill defined at `skills/cal-hotfix-done/SKILL.md`
- [ ] Reads `cal/active-hotfix.json` for merge chain
- [ ] Walks the merge chain step by step:
  1. Merge hotfix branch → main (with confirmation)
  2. Tag the release on main (e.g., `v2.1`) (with confirmation)
  3. Merge main → each feature branch in the chain (with confirmation per branch)
- [ ] At each merge: shows file count and summary, asks for confirmation, runs merge, reports conflicts if any
- [ ] On conflict: shows conflicting files, explains why, offers to help resolve, does NOT auto-resolve
- [ ] After all merges: removes worktree, deletes `cal/active-hotfix.json`
- [ ] Updates `## Current Work` in CLAUDE.md to reflect normal mode
- [ ] Outputs summary: "Hotfix 2.1 merged to main, tagged v2.1, merged forward to 3.0. Worktree cleaned up."

### US-9: Agent Frontmatter Upgrades
**Description:** Update agent definitions with modern Claude Code frontmatter fields.

**Acceptance Criteria:**
- [ ] Coder agent (`.claude/agents/coder.md`) updated:
  - `isolation: worktree` added (Cal passes this for feature work, omits for quick fixes)
  - `effort: high` added
  - `initialPrompt` added with OOD reminder
- [ ] Reviewer agent (`.claude/agents/reviewer.md`) updated:
  - `effort: high` added
  - `maxTurns` set appropriately
- [ ] Architect agent (`.claude/agents/architect.md`) updated:
  - `effort: max` added
  - `maxTurns` set appropriately
- [ ] Agent roster (`cal/agents.md`) updated to reflect new fields

### US-10: Design System Skill
**Description:** Move DESIGN.md content from always-loaded to on-demand skill.

**Acceptance Criteria:**
- [ ] New skill created at `skills/cal-design/SKILL.md`
- [ ] Contains full content of current `cal/DESIGN.md` (Liquid Glass reference)
- [ ] Coder agent's read order updated: invoke `cal-design` skill instead of reading `cal/DESIGN.md` directly
- [ ] CLAUDE.md no longer imports `@cal/DESIGN.md`
- [ ] `cal/DESIGN.md` file retained (not deleted) but no longer auto-loaded

---

## Implementation Phases

### Phase 1: CLAUDE.md Restructure + Kill NOW.md
**Stories:** US-1, US-10
**Tasks:**
- [ ] Create `skills/cal-design/SKILL.md` with DESIGN.md content
- [ ] Split analysis.md: selection guide stays in CLAUDE.md, full protocols move to `skills/cal-analyze/SKILL.md`
- [ ] Update CLAUDE.md: remove DESIGN.md import, add analysis selection guide, add `## Current Work` placeholder
- [ ] Update coder agent read order (skill instead of direct file read)
- [ ] Delete or archive NOW.md
**Verification:** `grep -c "@cal/DESIGN.md" CLAUDE.md` returns 0. `cat CLAUDE.md | wc -l` shows reduction. `skills/cal-design/SKILL.md` exists and contains design system.

### Phase 2: Hooks
**Stories:** US-2, US-3, US-4, US-5, US-6
**Tasks:**
- [ ] Create/update `.claude/settings.local.json` with all 4 hook definitions
- [ ] Write SessionStart hook script (`scripts/hooks/session-start.sh`)
- [ ] Write PostCompact hook script (`scripts/hooks/post-compact.sh`)
- [ ] Implement PreToolUse OOD enforcement (inline or script)
- [ ] Implement PreToolUse main branch protection (inline or script)
- [ ] Implement Stop verification hook (agent type)
**Verification:** Start a new session — Current Work section appears in CLAUDE.md. Try creating `TestUtils.swift` — blocked. Try committing on main — blocked. Run coder agent — Stop hook fires.

### Phase 3: Hotfix Flow
**Stories:** US-7, US-8
**Tasks:**
- [ ] Create `skills/cal-hotfix/SKILL.md`
- [ ] Create `skills/cal-hotfix-done/SKILL.md`
- [ ] Define `cal/active-hotfix.json` schema
- [ ] Integrate with SessionStart hook (detect active hotfix, include in briefing)
- [ ] Integrate with `## Current Work` section (hotfix mode indicator)
- [ ] Add `.worktrees/` to `.gitignore`
**Verification:** Run `/cal:hotfix` — worktree created, state file written, CLAUDE.md updated. Run `/cal:hotfix-done` — merge chain walked, worktree cleaned, CLAUDE.md reset.

### Phase 4: Agent Modernization
**Stories:** US-9
**Tasks:**
- [ ] Update `.claude/agents/coder.md` frontmatter
- [ ] Update `.claude/agents/reviewer.md` frontmatter
- [ ] Update `.claude/agents/architect.md` frontmatter
- [ ] Update `cal/agents.md` roster table
**Verification:** Dispatch coder agent for a feature — runs in worktree. Dispatch for a quick fix — runs inline. Agent frontmatter fields visible in definitions.

---

## Files Changed

### New Files
- `skills/cal-design/SKILL.md` — Design system skill (moved from always-loaded)
- `skills/cal-hotfix/SKILL.md` — Hotfix entry skill
- `skills/cal-hotfix-done/SKILL.md` — Hotfix exit skill
- `scripts/hooks/session-start.sh` — SessionStart hook script
- `scripts/hooks/post-compact.sh` — PostCompact hook script

### Modified Files
- `CLAUDE.md` — Remove DESIGN.md import, split analysis import, add Current Work section
- `skills/cal-analyze/SKILL.md` — Add full analysis protocols (moved from analysis.md)
- `.claude/agents/coder.md` — New frontmatter fields, updated read order
- `.claude/agents/reviewer.md` — New frontmatter fields
- `.claude/agents/architect.md` — New frontmatter fields
- `cal/agents.md` — Updated roster
- `.claude/settings.local.json` — Hook definitions
- `.gitignore` — Add `.worktrees/`

### Deleted Files
- `cal/NOW.md` — Replaced by dynamic CLAUDE.md section

### Retained but Unlinked
- `cal/DESIGN.md` — Content preserved, no longer imported by CLAUDE.md
- `cal/analysis.md` — Selection guide extracted to CLAUDE.md, full protocols to skill

---

## Definition of Done

- [ ] All user stories pass acceptance criteria
- [ ] All 4 phases verified
- [ ] New session starts with Current Work briefing
- [ ] PostCompact re-injects state
- [ ] OOD violations blocked by hook
- [ ] Main branch protected by hook
- [ ] `/cal:hotfix` and `/cal:hotfix-done` complete full worktree + merge cycle
- [ ] Agent definitions use modern frontmatter
- [ ] CLAUDE.md is leaner (no DESIGN.md import, analysis protocols moved to skill)

---

## Anti-Patterns to Avoid

From the DockPops RFC:
- **Don't auto-merge without asking.** Merges can have conflicts. Always confirm.
- **Don't block feature work during hotfix.** Worktrees exist to allow both.
- **Don't over-structure.** Lightweight persistence, not project management software.
- **Don't duplicate git's job.** Cal reads git state, adds interpretation. Git is source of truth.
