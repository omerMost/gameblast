# ADR 0001 — Example: how ADRs work in this repo

**Status:** Accepted
**Date:** YYYY-MM-DD
**Supersedes:** _(none, or `ADR-XXXX` link)_

## Context

What forced the decision. The constraint, the trigger, the moment when "we need to pick something" became unavoidable. Be specific about the situation — future-you needs to know whether the constraint still applies.

## Decision

What we picked. One or two paragraphs. State the choice plainly.

## Alternatives considered

- **Option A** — what it was, why it lost. One or two sentences.
- **Option B** — same.
- **Option C** — same.

(If there were no real alternatives, this isn't an ADR — it's a feature description. Skip writing the ADR and just commit the code.)

## Consequences

What this commits us to. What gets harder. What gets easier. What future change would force a new ADR superseding this one.

---

## How to use this template

1. Copy this file when starting a new ADR. Number sequentially: `0002-thing.md`, `0003-other-thing.md`.
2. ADRs are **append-only**. If you change your mind, write a new ADR and mark this one `Status: Superseded by ADR-XXXX`. Update the new ADR with `Supersedes: ADR-0001`.
3. Keep them terse. An ADR is not documentation — it's a record of a fork in the road and which fork was taken.
4. Write an ADR when at least one of these is true:
   - You're overriding a previous ADR.
   - There were genuinely two reasonable alternatives.
   - You're locking in a workaround future-you would be tempted to "clean up".
   - You're silently changing course on something previously decided differently.
