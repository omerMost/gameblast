You are running as the **Content Map Generator** for this project. You turn new entries in `context/mine.md` into a menu of content talking points in `context/content-map.md`, organized so the user can sit down to script and pick "I need 20 seconds on X, 3 minutes on Y."

This is **not** a 1:1 session→episode list. Some mine entries become a full episode, some are 30-second beats, some are recurring thematic threads that span many sessions. Your job is to surface all three.

## Step 1 — Bootstrap check

Check whether `context/content-map.md` exists.

- If it does NOT exist, create it with this header:

```
# Content Map

> Generated from `context/mine.md` via `/content-map`. A menu of talking points at different weights — beats, segments, episodes, and recurring themes — drawn from the build history. Use it to script without re-reading every session.
>
> Entries are appended in chronological order (by source session). Do not edit by hand unless correcting an error — regenerate with `/content-map` instead.

Last processed: (none)

---
```

- If it DOES exist, read it and find the `Last processed:` line to identify where to resume.

## Step 2 — Identify new mine entries

Read `context/mine.md`. Find every entry whose session slug is **lexicographically after** the `Last processed` marker in `content-map.md`. If `Last processed: (none)`, all mine entries are new.

If there are no new entries, tell the user "Nothing new to map — `context/content-map.md` is up to date through the last mined session." and stop.

Otherwise, tell the user how many new mine entries you found and proceed.

## Step 3 — Draft new talking points

Read every new mine entry. **Open the linked session files by default** — the mine's `Process` and `Hook` fields are deliberately terse, and scripting from them alone produces shallow, generic talking points. You need the session to actually *understand* what happened: the friction, the decision, the specific thing the user was thinking. That understanding is what makes the difference between a usable content map and a list of titles.

The only time you can skip opening a session is when it's clearly a tiny self-contained beat where the mine's Hook already captures the entire angle. When in doubt, open it. Depth of understanding here is what makes the output worth anything — don't optimize for speed.

For each mine entry (or group of entries — see grouping rules below), produce one content-map row with these fields:

- **Title** — short working title for the talking point
- **Source(s)** — one or more `context/sessions/…` paths (keep the links; they're the drill-back)
- **Angle** — one of: `product-feature` (what the project does) / `dev-process` (how it was built, tools, workflow) / `ai-tooling` (Claude Code, skills, context vault) / `design-choice` (visual / UX reasoning) / `decision` (architectural fork with a why). An entry may list multiple angles if genuinely multi-faceted.
- **Weight** — one of:
  - `beat` — 10–30 seconds, a single visual or point
  - `segment` — 1–3 minutes, part of a larger video
  - `episode` — stands alone, 3–8 minutes
  - `thread` — a recurring theme that spans many sessions, cross-referenced across the map
- **Why it matters** — one or two sentences on what makes this worth saying out loud. The *why*, not the what.
- **Notes** — optional. Script hints, visuals to capture, gotchas, related talking points to pair with.

## Step 4 — Grouping rules (important)

Walk through new mine entries in chronological order. For each one, decide: solo, group with neighbors, or split off from the group?

- **Group** when entries share a clear through-line (same feature shipping in pieces, one decision and its follow-up fix, a recurring thread of design polish). They do NOT need to be adjacent in time. What matters is the through-line, not the proximity. Combined entry lists all sources, single Title/Why.
- **Split** when entries in the same time window are thematically different — if one is at the start of a timestamp range and one is at the end, separate them so the flow in the video looks normal. Don't force cohesion across a gap in subject just because the timestamps are close.
- **Solo** is the default if unsure. Over-grouping is worse than under-grouping — a script can always merge two rows, but a row that bundles unrelated things is harder to unbundle later.
- **Threads** are orthogonal: if you spot a recurring theme across new + existing entries, add or update a `thread` row at the top of the map under a `## Threads` section. Threads aggregate — they cite multiple sources across time.

## Step 5 — Append in chronological order

Append new rows to `context/content-map.md` in chronological order by first source-session timestamp. Format each row as:

```
### YYYY-MM-DD — <Title>
- **Source(s):** `context/sessions/…`[, `context/sessions/…`]
- **Angle:** <angle>[, <angle>]
- **Weight:** <weight>
- **Why it matters:** …
- **Notes:** …  *(omit if empty)*
```

Keep a `## Threads` section at the top of the file (after the header, before the chronological entries). If you add or update a thread, keep its entry brief and link the sources.

Update the `Last processed:` line at the top of `content-map.md` to the session slug of the most recent mine entry you included.

## Step 6 — Report

Tell the user:
- How many new talking points were added
- Breakdown by weight (beats: N, segments: N, episodes: N, threads touched: N)
- The top 2–3 `episode`-weight items from this pass — those are the strongest candidates to script next
- One line: "Run `/content-map` again after `/mine` catches up to new sessions."
