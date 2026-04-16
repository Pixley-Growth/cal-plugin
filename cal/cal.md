# Cal Brain

Cal's persistent project knowledge. Organized by topic, not chronologically.
Auto Dream consolidates entries between sessions — keep entries atomic and topical.

---

## Principles Learned

*Patterns promoted from repeated experience. These shape how Cal approaches new work.*

- Lean into Claude Code native features (Auto Dream, hooks, memory) rather than building Cal-specific layers. Custom layers compete with native behavior and drift as Claude Code evolves.

---

## Deltas

*Wrong assumptions corrected. BELIEVED / ACTUAL / DELTA format. Auto Dream prunes resolved deltas.*

- **gh-board.sh owner type (2026-04-16):** BELIEVED find_project could use user() for any repo owner. ACTUAL: Pixley-Growth is an org, needs organization(). DELTA: GitHub APIs often have user/org divergence — always check owner type.

- **gh-board.sh project scope (2026-04-16):** BELIEVED querying org-wide projects was safe. ACTUAL: returned boards from other projects (SimCinema). DELTA: always scope project queries to the repository, not the owner.

- **Branch workflow (2026-04-16):** BELIEVED feature PRs merge directly to main. ACTUAL: user wants release branches (cal-5.0) as integration points. DELTA: multi-feature releases use a release branch before main.

---

## Decisions

*Architectural choices with rationale. CHOICE / RATIONALE / REVISIT-IF format.*

- **PR workflow (2026-04-16):** CHOICE: All merges go through PRs. RATIONALE: Enables Codex automated review at no human cost — caught real bugs on first PR. REVISIT-IF: Codex review stops adding value.

- **Release branches (2026-04-16):** CHOICE: Feature branches merge to release branch (cal-5.0), release branch merges to main. RATIONALE: Accumulate features before shipping, each PR gets Codex review. REVISIT-IF: single-feature releases become the norm.

- **Auto-Journal approach (2026-04-16):** CHOICE: Lean into Claude Code Auto Dream for memory consolidation instead of building Cal-specific journaling. RATIONALE: Prompt-based journaling was inconsistent in past Cal versions. Hook-based is better but native Auto Dream already does the consolidation cycle. REVISIT-IF: Auto Dream proves insufficient for project-level context.

---

## Active Context

*Current state that helps orient new sessions. Auto Dream prunes when stale.*

- Cal 5.0 in progress on `cal-5.0` branch. 7 features planned, Epic #3. Features #4 and #7 merged. Lisa interview for #5+#9 (Auto-Review + Security) in progress — 5 questions asked, awaiting answers.
