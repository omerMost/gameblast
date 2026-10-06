# STATE — current snapshot

**Rewritten (not appended to) at the end of every session.** Sessions are append-only history; ADRs are decision records; STATE is the snapshot of "what does this project actually look like right now."

If this is out of sync with the code, the code wins — but raise it as a bug, because keeping STATE current is part of the working discipline (see CLAUDE.md).

**Last updated:** 2026-10-06

---

## At a glance

Blast Ranger — physics bazooka shooter game for Android/iOS

_See `architecture/` for the shape of the system — STATE is a moving snapshot; architecture docs hold the stable frame._

## Surfaces / components / modules

_(Per-area summary of what exists. For an app: per-screen. For a library: per-module. For a service: per-endpoint or per-job. Keep each entry to a few lines — link to the file/path, describe what it does and any non-obvious behavior.)_

## Stack

_(Languages, frameworks, key dependencies, version-pinning rationale. Anything a contributor needs to know before installing.)_

## Known gaps (not bugs, just not done)

_(Things that aren't broken but aren't built. Separate from the backlog — these are the "we know it's missing" items.)_
