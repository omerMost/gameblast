# ADR 0004 — Claude commits its own verified work and pushes main after every landing

**Status:** Accepted (user, 2026-10-07: "yes too all")
**Date:** 2026-10-07
**Supersedes:** vault rule 7 as scaffolded by noamcli ("suggest a commit message for the user to run manually … do not run `git commit` unless explicitly asked"). AGENTS.md rule 7 is rewritten to match.

## Context
Parallel sessions in worktrees start from `main`'s last commit. When work sat uncommitted in `main`'s checkout, the 2026-10-06 sessions started from the bare scaffold: the Godot session had no `prototype/` until it was told to merge. The friend's project hit the same problem and fixed it with its ADR 0050 (Claude commits) and ADR 0110 (push after every landing).

## Decision
- **When:** at the end of every step that's **verified** (`check.sh` green, or the step's own checks) **and recorded** (the vault is updated).
- **What:** only its own files, staged **by path**. Never `git add -A` over another session's work.
- **Where:** on its own branch. A worktree session merges into `main` (fast-forward when possible), and `main` is **pushed to GitHub after every landing**.
- **Never:** commit, stash, reset or merge over another session's uncommitted work.
- **Still the user's call:** force-pushing, rewriting history, deleting branches, and merging PRs.
- Commit messages: a conventional-commit subject, a short bullet list, and the Co-Authored-By trailer.

## Alternatives considered
- **The user commits by hand (the old rule):** that's exactly the friction that left worktrees on a stale `main`.
- **Commit without pushing:** GitHub falls behind. The friend's repo ended up 2,196 commits behind before it adopted pushing.

## Consequences
- Every finished step leaves a commit, so sessions start from current work.
- Parallel sessions can collide in `main`'s checkout. The "never over another session's work" rule handles it: the work stays on its branch until `main` is clean.
