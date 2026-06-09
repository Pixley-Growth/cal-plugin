# Dependencies

Cal is a Claude Code plugin — no package manager dependencies. External dependencies are runtime tools.

| Dependency | Version | Purpose | License |
|-----------|---------|---------|---------|
| **Claude Code** | CLI | Plugin host — executes skills, agents, hooks, rules | Anthropic |
| **gh** (GitHub CLI) | Any | GitHub Projects V2 operations via `scripts/gh-board.sh` | MIT |
| **git** | Any | Version control, branch model, tagging | GPL-2.0 |
| **bash** | 3.2+ | Hook scripts, gh-board.sh | GPL-3.0 |
| **Lisa** (plugin) | Any | Specification interview workflow | — |
| **Ralph Loop** (plugin) | Any | Iterative implementation loop | — |

## Plugin Dependencies

Registered in `claude-code.json`. Installed via Claude Code `/plugin` command.

| Plugin | Purpose | Required? |
|--------|---------|-----------|
| `lisa` | `/lisa:plan` — specification interviews | Optional (Cal suggests, user decides) |
| `ralph-loop` | `/ralph-loop:ralph-loop` — iterative implementation | Optional |

## Scripts

| Script | Purpose | Dependencies |
|--------|---------|-------------|
| `scripts/gh-board.sh` | GitHub Projects V2 CRUD | `gh` CLI, authenticated |
| `scripts/hooks/session-start.sh` | Update CLAUDE.md Current Work section on session start | `git`, `gh` |
| `scripts/hooks/post-compact.sh` | Restore context after memory compaction | `git` |
| `scripts/hooks/ood-enforce.sh` | Block OOD-violating file names on Write/Edit | `bash` |
| `scripts/hooks/main-protect.sh` | Block direct commits to main without `[release]`/`[hotfix-merge]` | `git` |
