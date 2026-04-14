---
name: ood
description: "Object-Oriented Data principles, violation patterns, and compliance test. Use when reviewing code for OOD compliance, designing domain objects, checking for scattered logic in utils/helpers/services, or when user mentions object-oriented data, domain modeling, or translation boundaries."
license: MIT
compatibility: "Claude Code CLI with cal-plugin installed"
metadata:
  author: Cal
  version: 3.5.0
---

# OOD Code-Time Checklist

> The data is the API. Pull logic IN onto objects. Never extract it OUT.

## Before Writing Code — 8 Questions

1. **Does this logic describe what the object IS?** Put it ON the object.
2. **Can AI understand capabilities from schema alone?** If no, logic is scattered.
3. **Am I creating a file that "helps" domain objects?** STOP. Logic belongs on them.
4. **Is the first parameter a domain object?** That logic belongs ON it.
5. **Would I need to import a utility to use this object?** Those should be getters/computed properties.
6. **Is this foreign data entering the domain?** Naturalize it first. Then it's a citizen.
7. **Does this action modify or delete user data?** Needs permission (modify) or double confirmation (delete). Fences are architectural.
8. **Am I building a separate AI-specific endpoint or interface?** Same interface serves human and AI. One code path.

All 8 must pass. If any fails, restructure before writing code.

## Red-Flag File Patterns (Auto-Reject)

`*Utils.*`, `*Helper.*`, `*Service.*`, `*Manager.*`, `*Calculator.*`

If a file matches these patterns, the logic belongs on a domain object instead.

## Translation Boundaries

Foreign data must be naturalized before entering the domain:

Foreign Source → Extract (raw data) → Naturalize (domain vocabulary) → Citizen (self-describing object)

After naturalization, AI reads citizens without parsers.

## Full Reference

For complete OOD philosophy, code examples (Swift + TypeScript), the Five Commandments, and translation boundary patterns, see `cal/OOD.md`.

For language-specific code patterns, see `references/swift-patterns.md` and `references/typescript-patterns.md`.
