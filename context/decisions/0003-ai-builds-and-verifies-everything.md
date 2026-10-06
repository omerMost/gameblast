# ADR 0003 — The AI builds everything and must be able to check everything it builds

**Status:** Accepted (user, 2026-10-07: "yes too all")
**Date:** 2026-10-07
**Supersedes:** _(none)_

## Context
These methods come from a friend's noamcli game project, RareDrop (`~/Downloads/noamcontext`, its ADRs 0005/0008/0010). In that project the AI writes all the code and content, and a check suite of about 380 tests, bots and validators proves it. The user wants Blast Ranger built the same way. Before this ADR, verification was done ad hoc in each chat, and in Moo Rush's case the tests were lost entirely (they lived only in the claude.ai sandbox).

## Decision
- **Every kind of content has a text format the AI writes and a check the AI runs.** Code gets tests and headless bots. Levels and content are data with a validator. The running game gets screenshots from **many** states, not one.
- **One command checks everything:** `check.sh` at the repo root runs unit tests, simulation tests on the real physics, content validation and bots. It's committed, and it's green before every commit.
- **Bots play the game:** an end-to-end bot plays a new game through to the end, and balance bots measure pace. Their numbers go in the session notes.
- **Specs are numbers** ("fuse 140 ticks", "zombie 1.3× player speed"), so they become assertions.
- **Debug hooks from day one:** a test API (`window.__dbg` in the prototype, and the `Debug` autoload in Godot), a level/chapter skip, and one tuning table.
- **Order of work:** a gray box first to prove the loop is fun, then small verified steps, one feature at a time. Asking for "all" gets items skipped.
- **Fun stays the user's call.** Playtests are the user's job. Their findings go into `context/playtest-YYYY-MM-DD.md` in their own words and then into the backlog, and nothing gets fixed until they say so.
- **Decision cards:** every open design question gets an ID and options (`AIM1: A / B / C`). The answer is recorded with the user's own words in the session note's dialogue trace. Anything Claude decided alone is marked **provisional, pending the user's yes**.

## Alternatives considered
- **Verify ad hoc in each session (the status quo):** checks get lost (Moo Rush) or skipped, and regressions come back.
- **The user playtests everything by hand:** slow, and it misses regressions the bots catch in seconds.

## Consequences
- Tooling comes before features. Each project's first milestone includes `check.sh` and the bots.
- Session notes carry a **Checks** section (what ran, with the counts) and a **Dialogue trace** (the user's words).
