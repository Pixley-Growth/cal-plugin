---
name: hotfix
description: "Enter hotfix mode. Creates a worktree-based hotfix branch off main. Parks current feature work safely. Usage: /cal:hotfix [version]"
argument-hint: "version (optional) - Hotfix version number, e.g. 2.1"
---

# Hotfix — Enter Hotfix Mode

**Purpose:** Structured entry into hotfix mode using git worktrees. Parks current feature work and creates an isolated hotfix environment.

## Protocol

### 1. Assess Current State

Before anything, check:

```bash
# Current branch
git branch --show-current

# Uncommitted changes
git status --short

# Existing worktrees
git worktree list
```

**If uncommitted changes exist:** Warn the user. Ask them to commit or stash first. Do NOT proceed with dirty working directory.

**If already in hotfix mode:** Check for `cal/active-hotfix.json`. If it exists, warn: "Already in hotfix mode on `{branch}`. Run `/cal:hotfix-done` first or delete `cal/active-hotfix.json` to override."

### 2. Determine Version

If `$ARGUMENTS` contains a version number, use it. Otherwise:
1. Check git tags for the latest release tag (e.g., `v2.0`)
2. Suggest the next patch version (e.g., `2.1`)
3. Ask user to confirm

### 3. Create Hotfix Branch and Worktree

```bash
# Create the hotfix branch off main
git branch hotfix/$VERSION main

# Create worktree in .worktrees/ directory
git worktree add .worktrees/hotfix-$VERSION hotfix/$VERSION
```

### 4. Record Hotfix State

Write `cal/active-hotfix.json`:

```json
{
  "hotfixBranch": "hotfix/$VERSION",
  "basedOn": "main",
  "basedOnCommit": "<main HEAD short hash>",
  "parkedBranch": "<current branch before hotfix>",
  "worktreePath": ".worktrees/hotfix-$VERSION",
  "mergeChain": ["hotfix/$VERSION", "main", "<parked branch if not main>"],
  "started": "<ISO date>"
}
```

### 5. Update CLAUDE.md

Update the `## Current Work` section in CLAUDE.md to reflect hotfix mode:

```markdown
## Current Work
**Branch:** `hotfix/$VERSION`
**Mode:** hotfix
**Hotfix:** `hotfix/$VERSION` (parked: `<previous branch>`)
**Merge chain:** hotfix/$VERSION -> main -> <feature branches>
**Active:** Hotfix in progress
```

### 6. Add to .gitignore

Ensure `.worktrees/` is in `.gitignore`:

```bash
grep -q '.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore
```

### 7. Output Briefing

Tell the user:

```
Hotfix worktree created.

  Branch: hotfix/$VERSION
  Worktree: .worktrees/hotfix-$VERSION/
  Based on: main ($COMMIT)
  Parked: $PREVIOUS_BRANCH (untouched)

Work in the worktree directory or switch to the hotfix branch.
When done, run `/cal:hotfix-done`.
```

## Important Notes

- The feature branch is **untouched**. No WIP commits needed.
- The hotfix worktree is a full checkout — you can cd into it and work normally.
- `cal/active-hotfix.json` is the source of truth for hotfix state.
- The SessionStart hook reads this file and includes hotfix info in the briefing.
- **Do NOT delete the worktree manually** — use `/cal:hotfix-done` which handles merges and cleanup.
