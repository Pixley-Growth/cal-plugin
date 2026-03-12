---
name: cal-analyze
description: "Deep investigation with 7 analysis modes. Usage: /cal:analyze [mode] [subject]. Modes: inside-out, cake-walk, rubberneck, burst, bisect, trace, diff-audit."
argument-hint: "mode subject (optional) - Analysis mode and subject to investigate"
---

# Analyze — Deep Investigation

**Purpose:** Structured deep investigation using one of seven analysis modes.

## Available Modes

| Mode | Best For | Shorthand |
|------|----------|-----------|
| **inside-out** | Comprehensive understanding (NOT bug-fixing) | `io` |
| **cake-walk** | Layering bugs (CSS, SwiftUI, z-index) | `cw` |
| **rubberneck** | Focused scan with one suspect in mind | `rn` |
| **burst** | Temporal comparison (snapshots over time) | `burst` |
| **bisect** | Binary search to isolate root cause | `bi` |
| **trace** | Follow one data point end-to-end | `tr` |
| **diff-audit** | Catalog differences between two states | `da` |

## Protocol

### 1. Mode Selection

If no mode specified in `$ARGUMENTS`:
1. Read the user's problem description
2. Suggest the best mode with rationale
3. Wait for user confirmation before proceeding

If mode specified in `$ARGUMENTS`:
1. Load the protocol for that mode from `cal/analysis.md`
2. Begin execution immediately

### 2. Setup

Create an analysis journal at `cal/analyses/[subject-slug].md`:

```markdown
# Analysis: [Subject]

**Mode:** [Selected mode]
**Goal:** [Why we're investigating]
**Started:** [DATE]

---
```

### 3. Execute Mode Protocol

Follow the specific mode's protocol from `cal/analysis.md`. All modes share:

- **Journal everything** — findings, surprises, dead ends, connections
- **Track deltas** — when reality doesn't match expectations, use BELIEVED/ACTUAL/DELTA format
- **Ask questions** — add questions for the user when you need input
- **Stay in mode** — don't drift to fixing, planning, or building. Understanding first.

### 4. Produce Output

When investigation is complete:

```markdown
## Findings

### Core Insight
[One sentence — the thing that matters most]

### Key Discoveries
1. [Finding with evidence]
2. [Finding with evidence]

### Deltas Discovered
- BELIEVED: [X] → ACTUAL: [Y]

### Recommendations
1. [Actionable next step]

### Open Questions
- [Unresolved items]
```

### 5. Save Learnings

Offer to save key deltas and decisions to `cal/cal.md` via `/cal:save`.

## Mode-Specific Protocols

### Inside-Out
1. Start at the **widest** definition of the question
2. Identify all rabbit holes (sub-topics, edge cases, unknowns)
3. Dive into each one, going as deep as possible
4. At the bottom, zoom back up to the top
5. Re-evaluate each layer with the knowledge gained deeper in
6. Produce condensed insight

### Cake Walk
1. Identify all layers in the stack (CSS: reset → base → layout → component → override)
2. Start at the top layer
3. At each layer, verify it behaves correctly in isolation
4. Move to the next layer only when current is verified
5. The bug lives where a layer violates its contract with adjacent layers
6. Report which layer is broken and why

### Rubberneck
1. Name the suspect explicitly: "[X] might be causing [Y]"
2. Do a full code scan of the relevant area
3. For every file, ask: "Could this be related to [suspect]?"
4. Document every connection found (file, line, evidence)
5. Verdict: **confirmed** (with evidence), **ruled out** (with evidence), or **inconclusive** (what's missing)

### Burst Mode
1. Define what you're comparing (data, config, metrics, state)
2. Capture or identify snapshots at different points in time
3. Compare snapshots systematically
4. Catalog: what changed, when, correlation with the problem
5. Identify the temporal trigger

### Bisect
1. Define "works" state and "broken" state
2. Find the midpoint between them
3. Test at midpoint: works or broken?
4. Halve the remaining space
5. Repeat until root cause is isolated
6. Can bisect across: time (git), code (comment out), config (toggle), data (filter)

### Trace
1. Pick ONE data point, event, or request
2. Find its entry point into the system
3. Follow it through every transformation, handoff, and decision point
4. Document the full path: A → B → C → ...
5. The bug lives where the trace breaks or data transforms unexpectedly
6. Report the exact point of divergence

### Diff Audit
1. Identify the two states to compare (branches, deployments, configs, environments)
2. Catalog every difference systematically
3. Classify each diff: **relevant**, **irrelevant**, or **uncertain**
4. Investigate all relevant and uncertain diffs
5. Report which differences explain the problem
