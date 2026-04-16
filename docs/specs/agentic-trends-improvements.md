# Cal 5.0: Agentic Trends Improvements

**Status:** Spec Draft
**Date:** 2026-04-16
**Origin:** Anthropic's "2026 Agentic Coding Trends Report" mapped against Cal's current architecture. Seven concrete improvement areas identified.

---

## Problem Statement

Cal 4.0 established the coordinator model — Cal orchestrates, agents implement, humans approve. The 2026 Agentic Coding Trends Report reveals Cal is already aligned with the industry direction (human as orchestrator, agents as implementers) but has gaps in:

1. Agents don't self-escalate when uncertain — they push through ambiguity
2. No auto-review after agent implementation — quality checks are manual
3. Sequential-only agent dispatch — no parallel execution
4. Weak cross-session state persistence — journal is empty, `/cal:save` requires manual invocation
5. Onboarding produces CLAUDE.md only — no architecture maps or domain glossaries
6. No security review in the pipeline
7. No mechanism for low-risk "papercut" work

## Scope

### In Scope

Seven features, each independently shippable:

| # | Feature | Trend Source | Priority |
|---|---------|-------------|----------|
| 1 | Agent Escalation Protocol | Trend 4: Intelligent collaboration | High |
| 2 | Auto-Review Pipeline | Trend 4: Agentic quality control | High |
| 3 | Parallel Agent Dispatch | Trend 2: Coordinated teams | Medium |
| 4 | Auto-Journal on Phase Completion | Trend 3: Long-running coherent state | High |
| 5 | Enhanced Onboarding Artifacts | Trend 1: Onboarding revolution | Medium |
| 6 | Security-Aware Review | Trend 8: Security-first architecture | Medium |
| 7 | Papercuts Command | Trend 6: Productivity gains | Low |

### Out of Scope
- Agent SDK / cloud-hosted agents
- Non-technical user workflows (Trend 7 — Cal is developer-focused)
- Agentic cyber defense systems (Trend 8 — full security platform)

---

## Feature Specifications

### Feature 1: Agent Escalation Protocol

**Problem:** When Coder hits an ambiguous requirement, risky refactor, or uncertain architecture decision, it guesses and keeps going. This produces work that needs rework.

**Solution:** Add an escalation protocol to all agent prompts. Agents return to Cal with structured questions instead of guessing.

**Design:**

```markdown
## Escalation Protocol

When you encounter any of these, STOP and return to Cal with a structured question:

- **Ambiguous requirement** — Multiple valid interpretations, no clear winner
- **Risky refactor** — Change touches >3 files or modifies public interfaces
- **Missing context** — Need info not available in codebase or spec
- **Architecture decision** — Choice between patterns with non-obvious tradeoffs
- **Behavioral fence** — Action could be destructive or hard to reverse

Format:
ESCALATION: [category]
QUESTION: [specific question]
OPTIONS: [what you've considered]
RECOMMENDATION: [your best guess and why]
BLOCKED: [yes/no — can you continue on other work while waiting?]
```

**Implementation:**
- Add escalation protocol section to `coder.md`, `reviewer.md`, `architect.md`
- Cal's coordinator rule checks for ESCALATION in agent responses
- Cal surfaces the question to the user and re-dispatches after answer

**Acceptance criteria:**
- [ ] All three agent prompts include escalation protocol
- [ ] Cal recognizes ESCALATION format in agent responses
- [ ] Escalated questions are surfaced to user, not swallowed

---

### Feature 2: Auto-Review Pipeline

**Problem:** After Coder returns work, Cal does an "OOD spot-check" per the coordinator rule — but it's manual and inconsistent. The report says quality control should be a standard automated step.

**Solution:** After every Coder dispatch that produces code changes, Cal automatically dispatches Reviewer on the diff.

**Design:**

```
Coder finishes → Cal checks for code changes → Reviewer runs on diff → Cal reports combined result
```

Cal's coordinator dispatch flow becomes:
1. Dispatch Coder with task
2. Coder returns
3. If code was changed: auto-dispatch Reviewer on the diff
4. If Reviewer finds issues: report both implementation and review findings
5. If Reviewer passes: report clean result

**Implementation:**
- Modify coordinator rule to add auto-review step
- Reviewer gets a new "diff review" mode (vs. full codebase review)
- Add flag to skip auto-review for trivial changes (e.g., docs-only)
- Auto-review result format: PASS / WARN (suggestions) / FAIL (blocking issues)

**Acceptance criteria:**
- [ ] Coder completion triggers automatic Reviewer dispatch
- [ ] Reviewer runs in "diff review" mode on changed files only
- [ ] FAIL findings block reporting success to user
- [ ] Skip flag works for docs-only or trivial changes

---

### Feature 3: Parallel Agent Dispatch

**Problem:** Cal dispatches one agent at a time. For work that spans multiple concerns (e.g., architecture review + implementation scaffold), this is unnecessarily sequential.

**Solution:** Cal can dispatch multiple agents in parallel when their work is independent.

**Design:**

Parallel dispatch is valid when:
- Tasks have no data dependency (one doesn't need the other's output)
- Tasks touch different files or concern different aspects
- Both agents are read-only, OR they work in separate worktrees

Examples:
- Architect designs module A while Coder implements already-approved module B
- Reviewer checks PR while Coder writes tests for a different feature
- Two Coder instances in separate worktrees for independent features

**Implementation:**
- Coordinator rule gets a "parallel dispatch" option
- Cal identifies independent work items and groups them
- Uses Claude Code's native parallel Agent tool calls
- Results are collected and synthesized before reporting to user

**Acceptance criteria:**
- [ ] Cal can dispatch 2+ agents in a single tool call
- [ ] Independent tasks are identified and parallelized
- [ ] Results from parallel agents are synthesized into one report
- [ ] Worktree isolation used when parallel agents modify code

---

### Feature 4: Auto-Journal on Phase Completion

**Problem:** `cal/cal.md` is mostly empty. Cross-session context relies on the user calling `/cal:save`. The report emphasizes that long-running agents need "coherent state throughout complex projects."

**Solution:** Cal auto-journals at natural milestones — phase completion, squirrel resolution, delta discovery, significant decisions.

**Design:**

Auto-journal triggers:
- Feature moves to a new board column (via `gh-board.sh move-card`)
- A delta is surfaced
- A squirrel is called and resolved
- An architecture decision is made
- A phase is approved

Journal entry format:
```markdown
## 2026-04-16 [TYPE] — [Topic]

[Structured content per type: delta, decision, phase-complete, etc.]
```

**Implementation:**
- Modify skills that trigger state changes (`/cal:next`, board moves) to append to `cal/cal.md`
- Add auto-journal call after coordinator dispatch completes
- Keep entries concise (3-5 lines max)
- Memory system handles cross-conversation persistence; journal handles within-project history

**Acceptance criteria:**
- [ ] Phase completions auto-logged to `cal/cal.md`
- [ ] Deltas and squirrels auto-logged when they occur
- [ ] Journal entries are concise and structured
- [ ] New conversations can read journal for project context

---

### Feature 5: Enhanced Onboarding Artifacts

**Problem:** `/cal:onboard` generates CLAUDE.md. The report says onboarding should produce architecture maps, dependency graphs, and domain glossaries that accelerate all subsequent work.

**Solution:** Expand `/cal:onboard` to produce additional artifacts beyond CLAUDE.md.

**Design:**

New onboarding artifacts:
1. **Architecture Map** (`docs/ARCHITECTURE.md`) — Module boundaries, data flow, key abstractions
2. **Domain Glossary** (`docs/GLOSSARY.md`) — Domain terms with definitions, mapped to code locations
3. **Dependency Overview** (`docs/DEPENDENCIES.md`) — External dependencies, their purpose, version constraints

These feed into agent dispatch: Cal includes relevant glossary terms when dispatching to Coder, so agents use consistent domain vocabulary.

**Implementation:**
- Extend `skills/onboard/SKILL.md` with three new generation phases
- Architecture map uses Explore agent for deep codebase scan
- Glossary extracted from model names, enum cases, computed properties
- Dependency overview parsed from package manifests

**Acceptance criteria:**
- [ ] `/cal:onboard` produces 4 artifacts (CLAUDE.md + 3 new)
- [ ] Architecture map identifies module boundaries and data flow
- [ ] Glossary maps domain terms to code locations
- [ ] Dependency overview lists external deps with purpose

---

### Feature 6: Security-Aware Review

**Problem:** Reviewer checks OOD compliance but has no security mandate. The report says security must be embedded from the earliest stages, not bolted on.

**Solution:** Expand Reviewer's prompt with a security checklist, OR create a dedicated Security agent.

**Design:**

Option A (preferred — extend Reviewer):
Add a security section to Reviewer's prompt covering:
- Input validation at system boundaries
- Injection risks (SQL, command, XSS)
- Secrets in code (API keys, tokens)
- Auth/authz bypass paths
- Unsafe deserialization
- OWASP Mobile Top 10 (for iOS projects)

Option B (dedicated agent):
Create `auditor.md` agent that runs security-focused analysis.

**Implementation:**
- Add security checklist to `reviewer.md`
- Security findings use severity levels: CRITICAL / HIGH / MEDIUM / LOW
- CRITICAL findings auto-fail the review
- For iOS projects, integrate with Axiom security/privacy scanner agent

**Acceptance criteria:**
- [ ] Reviewer checks OWASP Top 10 categories
- [ ] Security findings have severity levels
- [ ] CRITICAL findings block approval
- [ ] iOS projects get mobile-specific security checks

---

### Feature 7: Papercuts Command

**Problem:** Small quality-of-life improvements (TODOs, deprecated APIs, minor inconsistencies) never get addressed because they're not worth a ticket. The report says 27% of AI-assisted work is stuff that "wouldn't have been done otherwise."

**Solution:** `/cal:papercuts` scans the codebase for small wins and either reports them or auto-fixes with user approval.

**Design:**

Scan categories:
- `TODO` / `FIXME` / `HACK` comments
- Deprecated API usage
- Dead code (unused imports, unreachable branches)
- Inconsistent naming
- Missing error handling at boundaries
- Trivial type safety improvements

Modes:
- `scan` — Report findings only (default)
- `fix` — Auto-fix with per-item approval (behavioral fence)

**Implementation:**
- New skill: `skills/papercuts/SKILL.md`
- Uses Grep + Glob for scanning
- Groups findings by category and severity
- Fix mode dispatches Coder for each approved fix
- Tracks what was fixed to avoid re-reporting

**Acceptance criteria:**
- [ ] `/cal:papercuts` scans and reports findings
- [ ] Findings grouped by category
- [ ] Fix mode requires per-item approval
- [ ] Fixed items tracked to avoid re-reporting

---

## Architecture Decisions

### AD-1: Extend Reviewer vs. New Security Agent
Extend Reviewer. One review pass, not two. Keeps the pipeline simple. A dedicated security agent can be added later for deep security audits, but the standard review should always include security basics.

### AD-2: Auto-Review Scope
Auto-review runs on diff only, not full codebase. Full codebase reviews are a separate concern. This keeps the feedback loop tight.

### AD-3: Journal vs. Memory
Journal (`cal/cal.md`) tracks project-level history within the repo. Memory (`memories/`) tracks user preferences and cross-project context. They serve different purposes and both persist.

---

## Rollout Order

1. **Feature 1: Agent Escalation** — Highest impact, lowest effort. Just prompt changes.
2. **Feature 4: Auto-Journal** — Enables everything else by improving state persistence.
3. **Feature 2: Auto-Review Pipeline** — Biggest quality improvement.
4. **Feature 6: Security-Aware Review** — Natural extension of Feature 2.
5. **Feature 3: Parallel Agent Dispatch** — Optimization after the pipeline is solid.
6. **Feature 5: Enhanced Onboarding** — Nice-to-have, not blocking.
7. **Feature 7: Papercuts** — Bonus feature, implement when stable.
