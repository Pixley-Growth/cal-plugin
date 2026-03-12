# Cal Plugin

**Coordination toolkit for Claude Code.** Cal manages the pipeline, not the code.

## What Cal Is

Cal is a **coordinator**, not a coder. It:
- Runs ideas through a dynamic pipeline
- Dispatches work to specialized agents
- Tracks work on GitHub Project boards (Epics + Features)
- Captures learnings
- Detects drift, frustration, and wrong assumptions

## Skills

| Skill | Purpose |
|-------|---------|
| `/cal:next` | Advance pipeline — find and execute next step |
| `/cal:meet` | Meeting facilitator |
| `/cal:save` | Context preservation |
| `/cal:onboard` | Project setup + CLAUDE.md generation |
| `/cal:analyze [mode]` | Deep investigation (7 modes) |
| `/cal:cal-ood` | OOD principles reference |

## Analysis Modes

| Mode | Best For |
|------|----------|
| `inside-out` | Comprehensive understanding |
| `cake-walk` | Layering bugs (CSS, SwiftUI) |
| `rubberneck` | Focused scan with a suspect |
| `burst` | Temporal comparison |
| `bisect` | Binary search for root cause |
| `trace` | Follow data end-to-end |
| `diff-audit` | Catalog state differences |

## Behavioral Rules (Always Active)

These load every session via `.claude/rules/`:

| Rule | Detects |
|------|---------|
| `coordinator` | Implementation requests → dispatches to agents |
| `tone-awareness` | Frustration or joy → adjusts approach |
| `squirrel` | Task drift → pauses and asks |
| `delta` | Wrong assumptions → documents correction |

## Architecture

```
.claude/rules/       → Behavioral rules (auto-loaded)
.claude/agents/      → Agent definitions (coder, reviewer, architect)
cal/                 → Brain (learnings, state, preferences)
skills/              → Skill definitions (cal-ood, cal-analyze, cal-meet, etc.)
scripts/             → Shared utilities (gh-board.sh)
hooks/               → Plugin-level hooks (OOD enforcement)
ideas/               → Parking lot (unstructured)
docs/specs/          → Active work artifacts
```

## Approval Gates

Advancement requires explicit approval:
- "approved", "advance", "next phase", or `/approve`
- Positive feedback is not advancement
