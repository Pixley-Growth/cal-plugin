# Cal 5.0: Agentic Trends Implementation Spec

**Status:** Ready for Implementation
**Date:** 2026-04-16
**Origin:** [Agentic Trends Improvements Design Doc](agentic-trends-improvements.md)
**Epic:** #3 Agentic Trends Improvements
**Branch:** `cal-5.0`

---

## Problem Statement

Cal 4.0 established the coordinator model. The Agentic Trends design doc identified 7 improvements. Features #1 (Escalation Protocol) and #2 (gh-board.sh) are shipped. This spec covers the remaining 6 features (#5, #6, #7, #8, #9, #10) as a single phased implementation.

## Scope

### In Scope

| # | Feature | GitHub Issue |
|---|---------|-------------|
| 5 | Auto-Review Pipeline | #5 |
| 6 | Parallel Agent Dispatch | #6 |
| 7 | Auto-Journal on Phase Completion | #7 |
| 8 | Enhanced Onboarding Artifacts | #8 |
| 9 | Security-Aware Review | #9 |
| 10 | Papercuts Command | #10 |

### Out of Scope

- Features #1 and #2 (already shipped)
- Agent SDK / cloud-hosted agents
- Generic OWASP checklist (deferred until app code exists in managed projects)
- Two-Coder parallel dispatch (deferred — only Review+Implement parallelism in v1)
- NOW.md file (GitHub board is the state source of truth)
- Automated test suite for plugin verification

---

## Architecture Decisions

### AD-1: Auto-Review Always Runs
Every Coder dispatch triggers Reviewer. No skip mechanism. Simplicity over optimization.

### AD-2: FAIL Reports to User
When auto-review returns FAIL, Cal reports both implementation and review findings to the user. No auto-re-dispatch loop. User decides next action.

### AD-3: GitHub Board Is State
No local NOW.md file. The GitHub board column is the source of truth for current state. Cal reads board position via `scripts/gh-board.sh get-card-column` when it needs current state.

### AD-4: Modify Coordinator Directly
Auto-review changes go into `.claude/rules/coordinator.md` directly. Single source of truth for dispatch flow.

### AD-5: Immediate Journal Writes
Deltas, squirrels, decisions, and phase completions write to `cal/cal.md` the moment they fire. No batching. Cap at 200 lines — when exceeded, move oldest entries to saved memories.

### AD-6: Parallel Results Report Immediately
When parallel agents finish at different times, Cal reports each result as it arrives. No waiting for all agents to complete.

### AD-7: Onboarding Overwrites
When `/cal:onboard` runs and artifacts already exist, regenerate from scratch. The codebase is the source of truth.

### AD-8: Papercuts Is General-Purpose
`/cal:papercuts` scans the project Cal is managing (user's codebase), not Cal itself. Code hygiene only: TODOs, FIXMEs, dead code, inconsistent naming.

### AD-9: Security Is Cal-Specific
Security checklist focuses on real Cal risks: shell injection in scripts, secrets in prompts, agent permission boundaries. Generic OWASP deferred.

---

## User Stories

### US-1: Auto-Review After Coder Dispatch

**Description:** As Cal (coordinator), after every Coder dispatch that returns, I automatically dispatch Reviewer on the changed files so quality control is a standard step.

**Acceptance Criteria:**
- [ ] Coordinator rule includes auto-review step between Coder return and user report
- [ ] Reviewer receives only the diff/changed files, not full codebase
- [ ] Reviewer output is one of: PASS, PASS WITH NOTES, FAIL
- [ ] On PASS: Cal reports implementation success + clean review
- [ ] On PASS WITH NOTES: Cal reports implementation success + review notes
- [ ] On FAIL: Cal reports implementation + review findings, does NOT report success
- [ ] Escalation in Reviewer response is surfaced to user (not swallowed by auto-review)

### US-2: Parallel Review + Implement

**Description:** As Cal, I can dispatch Reviewer on one task while Coder works on a different independent task, using Claude Code's native parallel Agent tool calls.

**Acceptance Criteria:**
- [ ] Coordinator rule includes parallel dispatch option for independent tasks
- [ ] Cal identifies when tasks are independent (no file overlap, no data dependency)
- [ ] Reviewer (read-only) and Coder (write, worktree) can run in parallel
- [ ] Results from each agent are reported as they finish (not held until both complete)
- [ ] If either agent escalates, Cal surfaces it without waiting for the other

### US-3: Auto-Journal — Phase Completions

**Description:** As Cal, when a phase is approved and the board advances, I automatically write a structured entry to `cal/cal.md`.

**Acceptance Criteria:**
- [ ] Phase completion writes entry: `## YYYY-MM-DD PHASE — [Feature] Phase N complete`
- [ ] Entry includes: what was done (1-2 lines), what's next
- [ ] Entry is appended to `cal/cal.md` (not overwritten)
- [ ] Works even if `cal/cal.md` doesn't exist yet (creates it)

### US-4: Auto-Journal — Deltas and Squirrels

**Description:** As Cal, when a delta or squirrel fires, I immediately write a structured entry to `cal/cal.md`.

**Acceptance Criteria:**
- [ ] Delta entries use existing format: `## YYYY-MM-DD DELTA — [Topic]` with BELIEVED/ACTUAL/DELTA/ENCODED
- [ ] Squirrel entries use existing format: `## YYYY-MM-DD SQUIRREL — [Topic]` with Was doing/Interrupted by/Decision
- [ ] Entries written immediately when detected, not deferred
- [ ] Architecture decisions also journaled: `## YYYY-MM-DD DECISION — [Topic]`

### US-5: Auto-Journal — Overflow to Memories

**Description:** As Cal, when `cal/cal.md` exceeds 200 lines, I move the oldest entries to the memory system.

**Acceptance Criteria:**
- [ ] Before writing a new journal entry, check line count of `cal/cal.md`
- [ ] If >200 lines, move oldest entries (enough to get back under 200) to `cal/memories/` as dated archive files
- [ ] Archive files named `cal/memories/YYYY-MM-DD-journal-archive.md`
- [ ] cal.md retains the most recent entries

### US-6: Enhanced Onboarding — Architecture Map

**Description:** As a user running `/cal:onboard`, I get an Architecture Map (`docs/ARCHITECTURE.md`) that identifies module boundaries and data flow.

**Acceptance Criteria:**
- [ ] `/cal:onboard` produces `docs/ARCHITECTURE.md` in addition to CLAUDE.md
- [ ] Architecture map identifies: module boundaries, key abstractions, data flow between modules
- [ ] Generated via Explore agent deep codebase scan
- [ ] Overwrites existing file if present (AD-7)

### US-7: Enhanced Onboarding — Domain Glossary

**Description:** As a user running `/cal:onboard`, I get a Domain Glossary (`docs/GLOSSARY.md`) that maps domain terms to code locations.

**Acceptance Criteria:**
- [ ] `/cal:onboard` produces `docs/GLOSSARY.md`
- [ ] Glossary extracted from: model names, enum cases, computed properties, key constants
- [ ] Each term includes: definition, code location (file:line), related terms
- [ ] Overwrites existing file if present

### US-8: Enhanced Onboarding — Dependency Overview

**Description:** As a user running `/cal:onboard`, I get a Dependency Overview (`docs/DEPENDENCIES.md`) listing external dependencies.

**Acceptance Criteria:**
- [ ] `/cal:onboard` produces `docs/DEPENDENCIES.md`
- [ ] Parsed from package manifests (Package.swift, package.json, Podfile, etc.)
- [ ] Each dependency includes: name, version, purpose, license if detectable
- [ ] Overwrites existing file if present

### US-9: Security-Aware Review — Cal-Specific Checks

**Description:** As Reviewer, I check for Cal-specific security risks in addition to OOD compliance.

**Acceptance Criteria:**
- [ ] Reviewer prompt includes security section with Cal-specific checks
- [ ] Shell injection: flags unquoted variables in shell scripts, unsanitized user input in Bash commands
- [ ] Secrets: flags hardcoded API keys, tokens, passwords in any file
- [ ] Permissions: flags agent prompts that could escalate beyond intended scope
- [ ] Security findings have severity: CRITICAL / HIGH / MEDIUM / LOW
- [ ] CRITICAL findings auto-FAIL the review (same as OOD violations)

### US-10: Papercuts Command — Scan Mode

**Description:** As a user, I can run `/cal:papercuts` to scan my project for small code hygiene wins.

**Acceptance Criteria:**
- [ ] `/cal:papercuts` scans the current project (not Cal itself)
- [ ] Scan categories: TODO/FIXME/HACK comments, unused imports, dead code, inconsistent naming
- [ ] Uses Grep + Glob for scanning (no external tools)
- [ ] Findings grouped by category
- [ ] Each finding includes: file, line, category, description
- [ ] Output is a readable report, not raw grep output

### US-11: Papercuts Command — Fix Mode

**Description:** As a user, I can run `/cal:papercuts fix` to auto-fix findings with per-item approval.

**Acceptance Criteria:**
- [ ] `/cal:papercuts fix` presents each finding and asks for approval before fixing
- [ ] Fix mode dispatches Coder for each approved fix (behavioral fence)
- [ ] Declined fixes are skipped, not re-reported in future scans
- [ ] Fixed items tracked to avoid re-reporting

---

## Implementation Phases

### Phase 1: Pipeline Foundation (Features #5, #7)

Auto-review and auto-journal — the two features that improve every subsequent dispatch.

**Tasks:**
- [ ] Modify `.claude/rules/coordinator.md`: add auto-review step (after step 7, before step 9)
- [ ] Modify `.claude/rules/coordinator.md`: remove NOW.md references, use GitHub board as state
- [ ] Modify `.claude/rules/delta.md`: add auto-journal write after delta detection
- [ ] Modify `.claude/rules/squirrel.md`: add auto-journal write after squirrel resolution
- [ ] Add journal overflow check (200-line cap) to coordinator's journal write logic
- [ ] Create `cal/cal.md` if it doesn't exist (with header)

**Verification (manual walkthrough):**
1. Simulate a Coder dispatch → confirm Reviewer auto-triggers on the result
2. Trigger a delta → confirm entry appears in `cal/cal.md`
3. Trigger a squirrel → confirm entry appears in `cal/cal.md`
4. Verify coordinator.md no longer references NOW.md

**User Stories:** US-1, US-3, US-4, US-5

---

### Phase 2: Security + Onboarding (Features #9, #8)

Security review and enhanced onboarding — extend existing capabilities.

**Tasks:**
- [ ] Add security section to `.claude/agents/reviewer.md` with Cal-specific checks
- [ ] Add severity levels (CRITICAL/HIGH/MEDIUM/LOW) to security findings
- [ ] Add CRITICAL auto-FAIL rule alongside existing OOD auto-FAIL
- [ ] Extend `skills/onboard/SKILL.md` with three new artifact generation phases
- [ ] Architecture Map: dispatch Explore agent, write to `docs/ARCHITECTURE.md`
- [ ] Domain Glossary: extract from models/enums/properties, write to `docs/GLOSSARY.md`
- [ ] Dependency Overview: parse manifests, write to `docs/DEPENDENCIES.md`

**Verification (manual walkthrough):**
1. Run Reviewer on a file with a hardcoded secret → confirm CRITICAL FAIL
2. Run Reviewer on a shell script with unquoted variables → confirm security finding
3. Run `/cal:onboard` on Cal itself → confirm 4 artifacts generated
4. Verify each artifact has meaningful content (not just headers)

**User Stories:** US-9, US-6, US-7, US-8

---

### Phase 3: Parallel Dispatch + Papercuts (Features #6, #10)

New capabilities — parallel execution and codebase hygiene scanning.

**Tasks:**
- [ ] Add parallel dispatch logic to `.claude/rules/coordinator.md`
- [ ] Add independence detection heuristic (no file overlap, no data dependency)
- [ ] Implement immediate result reporting for parallel agents
- [ ] Create new skill: `skills/papercuts/SKILL.md`
- [ ] Implement scan mode: Grep/Glob for TODOs, dead code, naming inconsistencies
- [ ] Implement fix mode: per-item approval + Coder dispatch
- [ ] Add papercuts command to CLAUDE.md command table

**Verification (manual walkthrough):**
1. Set up two independent tasks → confirm Cal dispatches in parallel
2. Confirm first-finished agent result is reported immediately
3. Run `/cal:papercuts` on a project with known TODOs → confirm findings report
4. Run `/cal:papercuts fix` → confirm per-item approval flow works

**User Stories:** US-2, US-10, US-11

---

## Definition of Done

This spec is complete when:
- [ ] All 11 user stories pass their acceptance criteria
- [ ] All 3 phases verified via manual walkthrough
- [ ] CLAUDE.md command table updated with new commands
- [ ] All 6 feature issues (#5-#10) closed on GitHub board
- [ ] Epic #3 moved to "Ready to Ship"

## Ralph Loop Command

```
/ralph-loop "Implement Cal 5.0 Agentic Trends per spec at docs/specs/as-much-as-is-responsible-from-features-1-10.md

PHASES:
1. Pipeline Foundation (#5, #7): Auto-review in coordinator.md, auto-journal in delta/squirrel rules, journal overflow, remove NOW.md refs - verify by reading modified files and confirming new sections exist
2. Security + Onboarding (#9, #8): Security section in reviewer.md, severity levels, extend onboard skill with 3 artifacts - verify by reading modified files
3. Parallel + Papercuts (#6, #10): Parallel dispatch in coordinator.md, new papercuts skill - verify by reading modified files and confirming skill structure

VERIFICATION (after each phase):
- Read each modified file and confirm changes match spec
- Check no *Utils.*, *Helper.*, *Service.*, *Manager.* files created
- Confirm OOD compliance (logic on objects, not scattered)

ESCAPE HATCH: After 20 iterations without progress:
- Document what's blocking in the spec file under 'Implementation Notes'
- List approaches attempted
- Stop and ask for human guidance

Output <promise>COMPLETE</promise> when all phases pass verification." --max-iterations 30 --completion-promise "COMPLETE"
```

## Open Questions

None — all decisions resolved during interview.

## Implementation Notes

- The existing [Agentic Trends Design Doc](agentic-trends-improvements.md) contains background rationale, architecture decisions AD-1 through AD-3, and the original rollout order. This spec extends it with concrete user stories, acceptance criteria, and implementation phases.
- Feature #4 (Agent Escalation) and #2 (gh-board.sh) are already shipped — agent prompts contain escalation protocol, gh-board.sh is operational.
- The coordinator rule currently references `cal/NOW.md` in steps 4 and 10 — these references must be removed (AD-3).
