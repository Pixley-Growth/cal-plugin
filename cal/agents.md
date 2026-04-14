# Team Roster

Cal dispatches work to these agents. Definitions live in `.claude/agents/`.

## Active Agents

| Agent | Role | Model | Effort | When to Use |
|-------|------|-------|--------|-------------|
| **Coder** | Implementation | Sonnet | High | Write code, fix bugs, run tests |
| **Reviewer** | Code review | Opus | High | Check quality, security, OOD compliance |
| **Architect** | Technical design | Opus | Max | System design, data flow, boundaries |

## Agent Definitions

Full prompts and tool configurations:
- `.claude/agents/coder.md` — Skills: ood, design. Initial prompt loads preferences.
- `.claude/agents/reviewer.md` — Skills: ood. Auto-FAILs OOD violations.
- `.claude/agents/architect.md` — Skills: ood. Max effort for thorough analysis.

## Isolation

- **Feature work:** Coder runs with `isolation: worktree` (Cal passes this when dispatching).
- **Quick fixes / hotfixes:** Coder runs inline (no worktree overhead).
- **Reviews / architecture:** Always inline (read-only, no isolation needed).

## Adding Agents

Create a new `.md` file in `.claude/agents/` with YAML frontmatter:

```yaml
---
name: agent-name
description: "What this agent does"
tools: Read, Edit, Write, Bash, Grep, Glob
model: sonnet
effort: high
initialPrompt: "First instruction for the agent"
---

System prompt goes here.
```

Then add a row to the table above so Cal knows about it.
