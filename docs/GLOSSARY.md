# Domain Glossary

| Term | Definition | Code Location | Related |
|------|-----------|---------------|---------|
| **OOD** | Object-Oriented Data — architectural pattern where AI collaborates through self-describing data | `cal/OOD.md:1` | Three Pillars, Prime Directive |
| **Three Pillars** | Self-Describing Data, Behavioral Fences, Unified Interfaces — the foundation of OOD | `cal/OOD.md:8` | OOD |
| **Prime Directive** | "Pull logic IN onto objects. Never extract it OUT." | `cal/OOD.md:6` | OOD, Commandments |
| **Behavioral Fence** | Architectural constraint: AI proposes, humans approve. No destructive actions without confirmation | `cal/OOD.md:30` | Approval Gates |
| **Naturalization** | Translation boundary pattern: foreign data → extract → naturalize → citizen | `cal/OOD.md:100` | Translation Boundary, Citizen |
| **Citizen** | A domain object that has been naturalized — self-describing, with computed properties | `cal/OOD.md:100` | Naturalization |
| **Delta** | A wrong assumption detected and corrected. BELIEVED/ACTUAL/DELTA/ENCODED format | `.claude/rules/delta.md:1` | Auto-Journal |
| **Squirrel** | Task drift or scope creep detection. Calibration, not criticism | `.claude/rules/squirrel.md:1` | Delta |
| **Approval Gate** | Explicit user approval required for phase advancement. "looks good" ≠ approval | `.claude/rules/coordinator.md:33` | Behavioral Fence |
| **Auto-Review** | Automatic Reviewer dispatch after every Coder return | `.claude/rules/coordinator.md:80` | Reviewer, Coder |
| **Auto-Journal** | Immediate write to cal.md when events fire (deltas, squirrels, phase completions) | `.claude/rules/coordinator.md:96` | Delta, Squirrel |
| **Escalation** | Agent returns structured question to Cal instead of guessing | `.claude/agents/coder.md:109` | Coordinator |
| **Hopper** | Idea parking lot — unstructured ideas not yet ready for active work | `ideas/hopper.md:1` | Pipeline |
| **Pipeline** | Dynamic sequence of phases for an idea (assessed per task, not fixed) | `.claude/rules/coordinator.md:24` | Approval Gate |
| **Papercuts** | Small code hygiene wins — TODOs, dead code, naming issues | `skills/papercuts/SKILL.md:1` | — |
| **Hot Potato** | Pattern for crossing server/client boundary: DTO → JSON → hydrate to class | `cal/OOD.md:82` | OOD |
| **Liquid Glass** | iOS 26 design system — glass effects, depth, tactility | `cal/DESIGN.md` | Design |
| **Ralph Loop** | Iterative implementation loop — same prompt fed back until completion | Plugin: `ralph-loop` | Lisa |
| **Lisa** | Specification interview tool — produces implementable specs | Plugin: `lisa` | Ralph Loop |
