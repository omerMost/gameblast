# ADR 0001 — Architecture docs are required, not optional

**Status:** Accepted
**Date:** 2026-10-06
**Supersedes:** _(none)_

## Context

The vault template ships with three architecture files under `context/architecture/`:

- `tech-stack.md` — what's picked for each layer and why.
- `system-design.md` — module boundaries and the shape of the project.
- `data-flow.md` — end-to-end walkthrough of the primary flow.

These are foundational, not speculative. Every project has a stack, a shape, and a flow — even if nobody's written them down. Without explicit files for them, the knowledge lives only in the code and gets rediscovered from scratch by every fresh session. The vault exists to prevent exactly that erosion.

The first real port of this template (2026-04-18) surfaced the failure mode: the folder wasn't part of the template, the rules said "grep `architecture/*.md` (if you have any)," and so the installing Claude silently skipped the discipline. The parenthetical was the escape hatch.

## Decision

**All three architecture files are present in every repo that installs this vault.** `context/architecture/tech-stack.md`, `context/architecture/system-design.md`, and `context/architecture/data-flow.md`.

- `tech-stack.md` is seeded **at install time** (the answers are usually already known).
- `system-design.md` and `data-flow.md` start **blank** and get filled in after the first real code-changing session — premature architecture docs rot fastest.
- The grep rule in `CLAUDE-vault-rules.md` applies to all three with no parenthetical escape.

If a repo genuinely doesn't need one of the three (e.g. a one-function utility library with no meaningful "data flow"), **delete the file and update this ADR** to record which file was deleted and why. Silent omission is not allowed.

## Alternatives considered

- **Leave architecture docs optional (status quo before this ADR).** Lost because the 2026-04-18 port demonstrated that "optional" reads as "skip it" in practice. The vault's entire purpose is preventing silent skipping.
- **Make architecture a single combined file.** Lost because answering three different questions in one file produces walls of text that nobody Cmd-Fs through. Separate files are individually addressable.
- **Per-project-type variants (library vs service vs app starters).** Lost because we only have one data point (one real port). Generic stubs cover the common case; variants wait for real friction.

## Consequences

- Every installed vault ships with the three files. Install instructions require seeding `tech-stack.md` before writing code.
- The grep rule in vault discipline applies to the architecture folder unconditionally. Cross-cutting code changes must check the architecture docs in the same turn.
- If a repo deletes a file, this ADR is the record of why — future maintainers can read it and know the decision was deliberate.
- Changing this decision (e.g. making architecture docs optional again) requires a new ADR that supersedes this one.
