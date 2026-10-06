# Blast Ranger

Blast Ranger — physics bazooka shooter game for Android/iOS

Author: Omer Evan.

## Repo layout

- `mobile/` — the mobile app ("Blast Ranger", Expo). Icons live in `mobile/assets/images/` (regenerate: `node scripts/generate-icons.js`).
- `prototype/` — the playable game: a single-file HTML5 + Matter.js web build with 40 levels (`prototype/index.html`). Copied from the claude.ai artifact on 2026-10-06. Run it with the `prototype` config in `.claude/launch.json` (port 8080).
- `godot/` — (planned) the Godot 4 port that will become the native Android app (ADR 0002). Built stage by stage by the `godot-porter` agent.
- `site/` — the web surface (marketing, app, docs — whatever it turns out to be; surface scaffold, fill in the stack when it is chosen).
- `context/` — the project vault (state, decisions, sessions, backlog). Project-wide, not per-surface.
- `.claude/agents/` — the agent team. `.claude/settings.json` sets `"agent": "root-orchestrator"`, so every session runs as the **Root Orchestrator**. It plans the work, hands tasks to `gameplay-engineer`, `level-designer`, `qa-playtester` and `godot-porter`, checks their results, and owns the vault. Subagents never write to `context/` and never commit.
- `scripts/generate-icons.js` — icon generator (committed on purpose; re-run after editing the mark).

## Installed knowledge packs

_(none yet — packs installed by noamcli are listed here with one-liners; their skills live in `.claude/skills/`)_

# Vault discipline

The `context/` vault is the project memory. It only works if it stays current. These rules are non-negotiable — every shortcut around them costs more later than the discipline does now.

## How to read this repo on a fresh session

If you're starting cold, read in this order. Stop when you have enough context for the task.

1. **`CLAUDE.md`** (this file) — the working rules.
2. **`context/STATE.md`** — single-page snapshot of what the project actually looks like right now. Faster than reading every architecture doc.
3. **`context/architecture/tech-stack.md`** — locked-in choices per layer. Read this before suggesting a new dependency or touching an existing one.
4. **`context/decisions/`** — read the most recent ADRs first. They tell you *why* the code looks how it does. ADRs are append-only — if one is marked Superseded, follow the link to its replacement. `0001-architecture-docs-required.md` locks in the architecture folder's contents — check it if any architecture file appears missing.
5. **`context/sessions/`** — most recent 2–3 only. Older ones are history. The latest sessions tell you what the in-flight work feels like.
6. **`context/architecture/system-design.md`** and **`data-flow.md`** — for the "how does X happen end-to-end" question, in depth. Read when the task spans modules.
7. **`context/tasks/backlog.md`** — what's queued. `Now` is mid-flight; `Next` is approved but not started; `Later / stretch` is parking lot.

## Working rules

1. **Update `STATE.md` and drop a session note at the end of every code-changing turn.** Not just "big" chunks — every turn that ships code needs a record. Group related small iterations into a single note for the day if they happen back-to-back. The bar is *lower* than you think it is. **Also applies to non-code sessions** that produce durable artifacts (backlog grooming, planning, research) — the vault convention is broader than "code-changing". If you wrote to `backlog.md`, `STATE.md`, an ADR, or anything in `context/`, the session note is owed.

   **Session filename convention: `YYYY-MM-DD-HH-MM-slug.md`**.

   **Mandatory procedure for the timestamp — do not skip:**
   1. Immediately before creating or renaming the session-note file, run `date +%Y-%m-%d-%H-%M` via the Bash tool.
   2. Use that command's output verbatim as the filename prefix.
   3. **Never synthesize the timestamp from memory, and never reuse the timestamp from the start of the conversation.** That is the known failure mode this rule exists to prevent. The HH-MM must be the moment the note is **written**, not when the session started.
   4. If the session continues past the first write and you update the note later, re-run `date`, rename the file to the new end-time, and keep the content.

   Why it matters: `/mine` reads session files in lexicographic filename order and treats that order as the true chronological order of the work. Any timestamp drift corrupts the content pipeline downstream (`/changelog`, `/content-map`).

2. **Write an ADR when:**
   - You're about to override or contradict an existing ADR (write a new one and link both ways with `Supersedes` / `Status: Superseded by`).
   - You're making an architectural choice with at least two reasonable alternatives — even if it feels like a "feature" rather than "architecture".
   - You're locking in a workaround that future-you would otherwise be tempted to "clean up" without knowing why it exists.
   - **Threshold check**: if you're about to "silently change course" on something that was previously decided differently, that's an ADR — even if no formal decision was ever written down.

3. **After cross-cutting code changes, update the architecture docs in the same turn.** Practical rule: after writing code, grep `context/architecture/*.md` for terms that appear in your diff. If anything matches, update it. The architecture folder is mandatory per ADR 0001 — don't treat this rule as optional, and don't skip it because a file "looks blank." Blank files are cues to fill them in, not permission to ignore them.

4. **Backlog hygiene is part of the work.** When a backlog item is done, **move it to `done.md` with the date in the same turn**. When new work emerges (a follow-up, a known limitation, a "we'll need to fix this later"), add it to backlog **in the same turn**. No "I'll clean it up later" passes. The backlog must reflect current reality.

5. **`STATE.md` is a snapshot, not history.** Rewrite it (don't append to it) at the end of any session that meaningfully changes the project's surface. Sessions are append-only history; ADRs are decision records; STATE is "what does this look like right now."

6. Keep notes terse — they exist so future-you can pick up cold.

7. **Claude commits its own verified work and pushes `main` after every landing (ADR 0004).** Only after the checks pass and the vault is updated. Only its own files, staged by path, on its branch; a worktree merges into `main`, then pushes. It never commits, stashes, resets or merges over another session's uncommitted work. Force-pushing, rewriting history, deleting branches and merging PRs stay the user's call. Commit format: a conventional-commit subject (`feat:` / `fix:` / `chore:` / `docs:`) plus a short bullet list.

8. **The AI builds and verifies everything (ADR 0003).** `check.sh` must be green before a commit. Bots play the game. Specs are numbers. Playtest findings go in `context/playtest-YYYY-MM-DD.md` in the user's words. Open questions become **decision cards** with IDs and options, and each session note carries a **Checks** section and a **Dialogue trace** with the user's words. Anything Claude decided alone is marked *provisional*.

9. **Overnight runs (ADR 0005):** a north star in `context/runs/`, the branch `run/<slug>` with one commit per step, and a `context/morning-page-YYYY-MM-DD.md` for the user to review before merging.

## What "done" looks like for a feature

- The change is verified to actually work (not just type-checks / compiles).
- A session note in `context/sessions/` summarizes what changed and why.
- `context/STATE.md` reflects the new surface (rewrite the relevant paragraph, don't append).
- Any architecture docs the change touches are also updated.
- `tasks/backlog.md` and `tasks/done.md` reflect the new state (cross off, append).
- If a non-obvious decision was made, an ADR exists.
