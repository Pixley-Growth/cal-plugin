# Architecture Map

## Modules

| Module | Purpose | Key Files |
|--------|---------|-----------|
| **Cal Core** | Coordinator behavior, pipeline management, approval gates | `.claude/rules/coordinator.md` |
| **Behavioral Rules** | Always-active detection rules (drift, deltas, OOD, tone) | `.claude/rules/*.md` |
| **Agent Definitions** | Prompt + config for dispatched agents | `.claude/agents/coder.md`, `reviewer.md`, `architect.md` |
| **Skills** | User-invokable workflows (10 skills) | `skills/*/SKILL.md` |
| **Brain** | Persistent project knowledge and preferences | `cal/cal.md`, `cal/OOD.md`, `cal/PREFERENCES.md`, `cal/DESIGN.md` |
| **Scripts** | Shell automation (GitHub boards, hooks) | `scripts/gh-board.sh`, `scripts/hooks/*.sh` |
| **Specs** | Feature specifications and progress tracking | `docs/specs/*.md`, `docs/specs/*.json` |

## Data Flow

```
User Request
    │
    ▼
Cal (coordinator.md)
    │
    ├──► reads cal/agents.md (team roster)
    ├──► reads GitHub board (pipeline state)
    ├──► reads docs/specs/ (task context)
    │
    ├──► dispatches Agent (coder/reviewer/architect)
    │       │
    │       ├──► Agent reads cal/PREFERENCES.md (stack)
    │       ├──► Agent reads cal/OOD.md (via ood skill)
    │       └──► Agent returns result (or ESCALATION)
    │
    ├──► auto-review (Reviewer on Coder's diff)
    ├──► auto-journal (writes to cal/cal.md)
    ├──► advance board (scripts/gh-board.sh)
    │
    └──► reports to user
```

## Integration Points

| System | Purpose | Location |
|--------|---------|----------|
| GitHub Projects V2 | Pipeline state tracking (Epics + Features boards) | `scripts/gh-board.sh` |
| GitHub Issues | Feature and Epic tracking | Created via `gh-board.sh create-issue` |
| GitHub PRs | Code review gate (Codex automated review) | Created via `gh pr create` |
| Claude Code Plugin System | Skill registration, hooks, agent dispatch | `claude-code.json`, `.claude-plugin/plugin.json` |
| Claude Code Auto Dream | Memory consolidation between sessions | Native (no Cal code) |
