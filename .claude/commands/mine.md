You are running as the **Session Miner** for this project. Your job is to read new session notes and append structured entries to `context/mine.md` — the permanent content artifact that feeds the changelog, content map, and any other downstream outputs.

## Step 1 — Bootstrap check

Check whether `context/mine.md` exists.
- If it does NOT exist, create it with the header below and treat every session as unprocessed:

```
# Content Mine

> The single source of truth for what was built and why. Every downstream output (CHANGELOG, content map, release notes, product brief) is generated from here — not re-mined from scratch.
>
> **Do not edit entries by hand** unless correcting a factual error. Let `/mine` append; let downstream tools generate.

Last processed: (none)

---
```

- If it DOES exist, read it and find the `Last processed:` line to identify where to resume.

## Step 2 — Identify new sessions

List all files in `context/sessions/`. They are named `YYYY-MM-DD-HH-MM-slug.md` and sort chronologically by filename.

Find every file that comes **after** the `Last processed` marker (compare slugs alphabetically / lexicographically — the date prefix makes this reliable). If `Last processed: (none)`, all files are new.

If there are no new sessions, tell the user "Nothing new to mine — `context/mine.md` is up to date." and stop.

Otherwise, tell the user how many new sessions you found and which ones, then proceed.

## Step 3 — Mine each session

For each new session file, in chronological order:

1. Read the full session note.
2. Extract the following fields:

**Surface** — What changed that a user (or consumer of the project — could be an end user, a developer using a library, an API caller) would notice? Be concrete, not vague. If nothing user-facing changed, write "No user-facing changes."

**Process** — What was interesting about *how* this was built? Decisions made, tools used, problems hit, vault/session-discipline moves, architecture choices. This is the build-story material. Be honest about friction, not just wins.

**Decisions** — List any ADRs that were written or referenced. Format: `ADR-XXXX: title`. If none, write "None."

**Hook** — One sentence. The most interesting or shareable thing about this session — the angle you'd use to open a post or video. Should be specific and concrete, not generic.

**Worthiness** — Your assessment of content potential:
- `high` — a clear story, interesting moment, or milestone worth its own post/video
- `medium` — supporting material, useful for context, probably part of a larger episode
- `low` — housekeeping, plumbing, not interesting to a general audience

3. Write the entry in this format:

```
## YYYY-MM-DD — [Short title derived from the slug]
**Session:** `context/sessions/YYYY-MM-DD-HH-MM-slug.md`
**Surface:** [what changed for users/consumers]
**Process:** [what was interesting about building it]
**Decisions:** [ADRs written or referenced, or "None"]
**Hook:** [one-sentence angle]
**Worthiness:** high / medium / low
```

Leave one blank line between entries.

## Step 4 — Append and update marker

Append all new entries to `context/mine.md` (after the existing entries, before the end of file).

Update the `Last processed:` line at the top to the slug of the last session you just processed.

## Step 5 — Report

Tell the user:
- How many entries were added
- Which sessions were covered
- How many are `high` worthiness (those are the ones to prioritize for content)
- One line: "Run `/mine` again after adding new session notes to keep this up to date."

Do NOT generate a changelog or content map — that is for future sessions. The mine is the input; the outputs come later.
