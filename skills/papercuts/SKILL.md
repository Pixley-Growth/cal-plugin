---
name: papercuts
description: "Scan codebase for small code hygiene wins — TODOs, dead code, naming issues. General-purpose tool for any project."
---

# Papercuts — Code Hygiene Scanner

**Purpose:** Find and optionally fix small code quality issues that individually aren't worth a ticket but collectively degrade the codebase.

## Modes

| Mode | Command | Behavior |
|------|---------|----------|
| **Scan** (default) | `/cal:papercuts` | Report findings only |
| **Fix** | `/cal:papercuts fix` | Auto-fix with per-item approval |

## Scan Categories

Papercuts scans for **code hygiene only** — safe, language-agnostic patterns:

### 1. TODO / FIXME / HACK Comments

Search for unresolved markers:
```
Grep: TODO|FIXME|HACK|XXX|TEMP|WORKAROUND
```

Report: file, line, full comment text.

### 2. Dead Code Indicators

Search for common dead code patterns:
```
Grep: // unused|// deprecated|// old|// remove|// delete
Grep: #if false|#if 0
```

For languages with import analysis:
- TypeScript/JavaScript: imports not referenced elsewhere in the file
- Swift: `import` statements for unused frameworks

### 3. Inconsistent Naming

Look for naming pattern violations within each file:
- Mixed camelCase and snake_case in the same file
- Abbreviated names alongside spelled-out equivalents (e.g., `btn` and `button` in the same scope)
- Single-letter variable names outside of loop iterators

### 4. Empty Catch / Error Swallowing

```
Grep: catch\s*\{?\s*\}|catch\s*\(\s*_|// swallow|// ignore
```

## Scan Protocol

1. **Detect project language** from file extensions (Glob for `*.swift`, `*.ts`, `*.py`, etc.)
2. **Run each scan category** using Grep + Glob
3. **Group findings** by category
4. **Format report:**

```markdown
## Papercuts Report

**Project:** [directory name]
**Scanned:** [N files across M categories]
**Findings:** [total count]

### TODOs / FIXMEs ([count])

| File | Line | Text |
|------|------|------|
| [path] | [line] | [comment text] |

### Dead Code ([count])

| File | Line | Indicator |
|------|------|-----------|
| [path] | [line] | [what suggests it's dead] |

### Naming Issues ([count])

| File | Line | Issue |
|------|------|-------|
| [path] | [line] | [what's inconsistent] |

### Error Swallowing ([count])

| File | Line | Pattern |
|------|------|---------|
| [path] | [line] | [what's swallowed] |
```

## Fix Protocol

When invoked with `fix`:

1. Run the scan (same as above)
2. For each finding, present it to the user:
   ```
   [Category] [file:line]
   [description]

   Fix? (yes / no / skip all in category)
   ```
3. For approved fixes, dispatch Coder with the specific fix task
4. Track fixed items in `cal/memories/papercuts-fixed.md` to avoid re-reporting
5. Declined fixes are noted but will appear again on next scan (user may change their mind)

## Behavioral Fence

Fix mode requires **per-item approval**. Papercuts never auto-fixes without asking. This is architectural, not aspirational — the scan/fix separation enforces it.

## Scope

Papercuts scans the **current project directory** (the codebase Cal is managing), not Cal's own files. It's a general-purpose tool that works on any project.
