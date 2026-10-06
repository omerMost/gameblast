<!--
What this file answers: what did we pick for each layer of the project, and why.
When to update: any time a new dependency is locked in, swapped, or removed — same turn as the code change.
Example entry: "UI framework: Expo Router 7 — file-based routing, already Expo-blessed."
Seed this file during install (don't leave blank) — stack choices are usually known up-front. If you genuinely don't have an answer for a section yet, write "TBD" instead of deleting the section.
-->

# Tech stack

One section per layer. For each choice: what we picked + one-line rationale. Resist writing prose — this is a lookup table, not an essay.

> Status 2026-10-06: the only working code is `prototype/index.html`. Engine decided: Godot 4 (ADR 0002). The port hasn't started.

## Runtime / language

- Prototype (`prototype/index.html`): vanilla JavaScript in the browser, one file, no build step. Matter.js 0.19.0 is vendored at `prototype/vendor/matter.min.js`, and the fonts (Lilita One 400, Nunito variable 800–900, latin woff2) are in `prototype/fonts/` with local `@font-face` rules. It needs no network (source URLs are in `prototype/README.md`).
- App: **Godot 4 + GDScript** in `godot/`, Android first (ADR 0002). Not built yet. Record the exact Godot version once it's installed.

## UI / presentation layer

- Prototype: HTML5 canvas 2D, hand-drawn particles/effects. Physics: **Matter.js** (needs retuning if the engine changes).

## Data layer

- Levels are coded as coordinate data in JS (40 levels). There is no backend.

## Auth / storage / persistence

- Prototype: localStorage (progress, toggles). Native: TBD (Capacitor Preferences was suggested). No auth.

## External integrations

- None yet. Planned: AdMob (rewarded + interstitial, no banners), Firebase Analytics. TBD.

## Tooling (build, test, lint, CI)

- Prototype was verified with headless auto-play (random shots across all levels, checking stability, clearability, and causeless deaths). The test hook is `window.__dbg`. Local dev: the `prototype` config in `.claude/launch.json` runs `python3 -m http.server` on port 8080. Repo tooling: TBD.

## What we deliberately did NOT pick

_(Things that were on the table and lost. Each entry: what it was, why it lost. Saves future-you from re-litigating.)_

- **Capacitor wrapper, Expo/React Native, Unity, Phaser.** All lost to Godot 4 for the native app. See ADR 0002.
