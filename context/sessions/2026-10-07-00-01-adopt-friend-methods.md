# 2026-10-07 — Adopted the friend's working methods (RareDrop, ~/Downloads/noamcontext)

- I read the friend's vault: 137 sessions and 53+ ADRs from RareDrop, a Godot 4.7 pixel RPG built on noamcli. Mapped his methods onto this project.
- **The user, word for word:** "yes too all" to three questions: (1) Claude commits its own work, (2) push after every step, (3) overnight runs. Also "yes install" for the Godot session's Android toolchain, relayed to that session.
- **ADRs written:**
  - the AI builds and verifies everything: `check.sh`, bots, specs as numbers, decision cards, playtest files, Checks and Dialogue trace sections in session notes;
  - Claude commits and pushes its verified work (supersedes noamcli's rule 7);
  - overnight runs: `context/runs/`, the `run/<slug>` branch, one commit per step, `morning-page-<date>.md`.
- **AGENTS.md:** rule 7 is rewritten, and rules 8–9 are added. The Root Orchestrator has a "Working methods" section.
- Backlog: `check.sh` and the bots come first.
- Not adopted (for now): his art pipeline (GPT concepts, painted maps, PixelLab).

## Checks
- Docs only. No code changed.

## Dialogue trace
- User: "i want to work in his methods to create and develop my blast game"
- Claude: summarized his methods and asked 3 cards: commits, pushes, overnight.
- User: "yes too all and yes install"
