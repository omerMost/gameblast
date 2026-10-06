# ADR 0005 — Overnight autonomous runs with a north star and a morning page

**Status:** Accepted (user, 2026-10-07: "yes too all")
**Date:** 2026-10-07
**Supersedes:** _(none)_

## Context
The friend's project uses overnight runs (`autonomous-run.md`, `morning-page-*.md`). The user gives a north-star goal at night. Claude works on its own, one verified commit per step, and leaves a one-page summary for the morning. The user wants the same.

## Decision
- **Kick-off:** the user states a north star ("by morning I can play X end to end"). The orchestrator writes `context/runs/YYYY-MM-DD-<slug>.md` containing the goal, a numbered checklist of small verifiable steps, and the rules for the night: what needs the user, and what Claude may decide provisionally.
- **During the run:**
  - Work goes on the branch `run/<slug>`, with **one commit per step** so any step can be reverted.
  - `check.sh` runs after every step.
  - The orchestrator may split independent steps across sessions.
  - Anything outward-facing (store consoles, purchases, installing on the user's phone, accepting terms) waits for the user.
- **Morning page:** `context/morning-page-YYYY-MM-DD.md`, at most one screen:
  - **Is the goal met?** Yes or no, with the evidence: the check counts and the bot results.
  - **How to try it:** the build or APK path, and the commands.
  - **What landed**, grouped.
  - **Provisional calls to confirm or reject.** A rejection gets reverted.
  - **Open decision cards.**
  - **Known weak spots.**
- **Merging:** the run's branch merges into `main` only after the user reviews the morning page, or says "merge".
- **Budget:** report how much of the weekly usage the run used. Stop and leave a morning page before hitting the limit.

## Alternatives considered
- **Only interactive sessions:** progress stops whenever the user is away.
- **Work straight on `main` overnight:** a bad night is hard to undo. The branch plus per-step commits makes every step reversible.

## Consequences
- The first overnight run should come after `check.sh` and the bots exist, because a run can only be trusted as far as its checks.
