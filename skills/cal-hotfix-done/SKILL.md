---
name: cal-hotfix-done
description: "Exit hotfix mode. Guided merge chain: hotfix -> main -> feature branches. Cleans up worktree. Usage: /cal:hotfix-done"
---

# Hotfix Done — Exit Hotfix Mode

**Purpose:** Structured exit from hotfix mode with guided merge chain, tagging, and worktree cleanup.

## Protocol

### 1. Verify Hotfix State

Check `cal/active-hotfix.json` exists. If not, say: "No active hotfix found. Nothing to do."

Read the state file:
```bash
cat cal/active-hotfix.json
```

### 2. Check for Uncommitted Work

```bash
# Check the hotfix worktree for uncommitted changes
git -C .worktrees/hotfix-$VERSION status --short
```

**If uncommitted changes:** Warn and ask to commit first. Do NOT proceed.

### 3. Walk the Merge Chain

The merge chain from `active-hotfix.json` defines the order. Walk it step by step with user confirmation at each stage.

#### Step 1: Merge hotfix -> main

Show the user what will merge:

```bash
# Show commits that will merge
git log main..hotfix/$VERSION --oneline

# Show file summary
git diff main..hotfix/$VERSION --stat
```

**Ask:** "Merge `hotfix/$VERSION` into main? ($N commits, $M files changed)"

If confirmed:
```bash
git checkout main
git merge hotfix/$VERSION -m "[hotfix-merge] Merge hotfix/$VERSION into main"
```

**On conflict:**
1. Show which files conflict: `git diff --name-only --diff-filter=U`
2. Explain why (both branches modified the same file)
3. Offer to help resolve
4. **Do NOT auto-resolve.** Always ask.

#### Step 2: Tag the release

**Ask:** "Tag this as `v$VERSION` on main?"

If confirmed:
```bash
git tag v$VERSION
```

#### Step 3: Merge main -> feature branches

For each feature branch in the merge chain (after main):

```bash
# Show what will merge
git log $FEATURE_BRANCH..main --oneline
git diff $FEATURE_BRANCH..main --stat
```

**Ask:** "Merge main into `$FEATURE_BRANCH`? ($N commits, $M files changed)"

If confirmed:
```bash
git checkout $FEATURE_BRANCH
git merge main -m "Merge main (with hotfix/$VERSION) into $FEATURE_BRANCH"
```

**On conflict:** Same protocol — show, explain, offer help, never auto-resolve.

### 4. Clean Up

After all merges complete:

```bash
# Remove the worktree
git worktree remove .worktrees/hotfix-$VERSION

# Delete the hotfix branch (it's merged)
git branch -d hotfix/$VERSION

# Remove the state file
rm cal/active-hotfix.json
```

### 5. Switch Back

```bash
# Return to the parked branch
git checkout $PARKED_BRANCH
```

### 6. Update CLAUDE.md

Update the `## Current Work` section back to normal mode:

```markdown
## Current Work
**Branch:** `$PARKED_BRANCH`
**Mode:** normal
**Active:** <resume previous ticket or run /cal:next>
```

### 7. Output Summary

```
Hotfix $VERSION complete.

  Merged: hotfix/$VERSION -> main -> $FEATURE_BRANCHES
  Tagged: v$VERSION
  Worktree: cleaned up
  Branch: back on $PARKED_BRANCH

Resume feature work or run `/cal:next` for next ticket.
```

## Edge Cases

### User wants to abort the hotfix
If the user says "abort" or "cancel" during the merge chain:
1. Stop merging immediately
2. Ask: "Abort the remaining merges? The hotfix branch and worktree will be kept for later."
3. If yes: leave everything as-is, don't clean up. They can resume later.

### Hotfix branch has been pushed
If the hotfix branch exists on remote:
```bash
git push origin --delete hotfix/$VERSION
```
Ask before deleting the remote branch.

### Merge chain has extra branches
If new feature branches were created since the hotfix started, they won't be in the merge chain. Cal should check:
```bash
git branch --no-merged main
```
And warn: "These branches don't have the hotfix yet: $BRANCHES. Merge main into them separately."

## Important Notes

- **Never auto-merge.** Every merge step requires explicit user confirmation.
- **Never auto-resolve conflicts.** Show the conflict, explain it, offer help.
- The `[hotfix-merge]` tag in commit messages allows the main-protect hook to pass.
- After cleanup, the hotfix is fully integrated and the worktree is gone.
