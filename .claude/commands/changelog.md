You are running as the **Changelog Generator** for this project. You turn new entries in `context/mine.md` into a user-facing `CHANGELOG.md` entry for a specific version that is about to be shipped.

Invoking `/changelog` means the user is preparing to push a new version. Do not guess the version number — ask if it isn't in the invocation context.

## Step 1 — Get the version

If the user's `/changelog` invocation includes a version (e.g. `/changelog 1.1.0`), use it.

Otherwise, ask: "What version is this changelog for? (e.g. 1.1.0)" and wait for a reply. Do nothing else until you have it.

## Step 2 — Bootstrap check

Check whether `context/CHANGELOG.md` exists. (The changelog lives inside `context/`, not at the repo root, so the vault stays self-contained. If your project convention puts it at the repo root, adjust the path here.)

- If it does NOT exist, create it with this header:

```
# Changelog

> Generated from `context/mine.md` via `/changelog`. Do not edit by hand — regenerate instead.
>
> Versioning: bump the project's version metadata before each shared build, then run `/changelog <version>` to produce the entry.

Last processed: (none)

---
```

- If it DOES exist, read it and find the `Last processed:` line at the top to identify where to resume.

## Step 3 — Identify new mine entries

Read `context/mine.md`. Each entry starts with a `## YYYY-MM-DD — Title` heading and has a `**Session:**` line pointing to a session file.

Find every mine entry whose session slug is **lexicographically after** the `Last processed` marker in `CHANGELOG.md`. If `Last processed: (none)`, all mine entries are new.

If there are no new entries, tell the user "Nothing new to changelog — `CHANGELOG.md` is up to date through the last mined session." and stop.

Otherwise, tell the user how many new mine entries you found and the version you're generating for, then proceed.

## Step 4 — Draft the changelog entry

Read every new mine entry. **Open the linked session files by default** — the mine fields are deliberately terse and you need the session to understand what actually shipped. The only time you can skip opening a session is when the mine entry is obviously a tiny, self-contained item where the Surface field already says everything a user needs to know. When in doubt, open it.

Group entries into the following categories. A single mine entry may contribute to multiple categories, be merged with other entries into one line, or stand alone — use judgment:

- **Features** — new user-visible capabilities
- **Fixes** — bug fixes users would notice, but **only for bugs in a previously released version**. A bug introduced AND fixed during this version's development cycle is not a "fix" for the changelog — it's just part of landing the feature correctly. Fold user-visible behavior from those intra-version fixes into the relevant **Features** or **Polish** bullet instead. For the very first version (no prior release exists), the Fixes section should be empty.
- **Polish** — UI/UX refinements, copy tweaks, small visual improvements
- **Internals** — notable behind-the-scenes work worth surfacing (dependency upgrades, release infra, architecture shifts). Skip pure housekeeping.

Omit any category that would be empty.

Writing style:
- Plain language. Write for the user/consumer of the project, not the developer. Avoid internal jargon unless it's the clearest way to name something.
- Active voice, past tense. Terse — one line per bullet, no sub-bullets.
- Group tightly related changes into one bullet when the combined line reads more naturally than two.
- **Determining whether a bug is a Fix or belongs in Features/Polish:** check earlier entries in `CHANGELOG.md`. If the broken behavior was described (even implicitly) in a previously released version, it's a Fix. If the feature first lands in the current version and the "fix" was part of making it work, it's part of that feature — no separate Fix bullet. When in doubt, assume intra-version and fold.
- Skip anything with `Worthiness: low` that has no user-facing impact (pure housekeeping, tooling, vault discipline). Internals-worthy items can still appear if they matter for the release story.

**Track what you omit.** Keep a list of every mine entry you decided NOT to include in the changelog, with a one-line reason each. You will report this list to the user in Step 6 so they can pull items back in.

## Step 5 — Prepend to CHANGELOG.md

Insert the new version block **above the previous versions** (newest first), right after the header and the `---` separator. Format:

```
## <version> — YYYY-MM-DD

### Features
- …

### Fixes
- …

### Polish
- …

### Internals
- …
```

Use today's date for the version heading.

Update the `Last processed:` line at the top of `context/CHANGELOG.md` to the session slug of the most recent mine entry you included.

## Step 6 — Report

Tell the user:
- Version and date generated
- Number of mine entries rolled up
- Count per category (Features: N, Fixes: N, …)
- A reminder to bump the project's version metadata before the build, if not already done
- **The omissions list from Step 4** — every mine entry you decided not to include, with a one-line reason each. Format as a short bulleted list so the user can scan it and say "no, add X back in" for any item they want pulled into the changelog. If the user asks to add one, regenerate the relevant section and update the file.

Do not commit. Do not run builds. The user drives the release.
