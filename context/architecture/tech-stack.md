<!--
What this file answers: what did we pick for each layer of the project, and why.
When to update: any time a new dependency is locked in, swapped, or removed — same turn as the code change.
Example entry: "UI framework: Expo Router 7 — file-based routing, already Expo-blessed."
Seed this file during install (don't leave blank) — stack choices are usually known up-front. If you genuinely don't have an answer for a section yet, write "TBD" instead of deleting the section.
-->

# Tech stack

One section per layer. For each choice: what we picked + one-line rationale. Resist writing prose — this is a lookup table, not an essay.

> Status 2026-10-07: the prototype is still the spec. The Godot port has reached stage 1 (core loop, levels 1–5), verified headlessly. Android toolchain is not installed yet.

## Runtime / language

- Prototype (`prototype/index.html`): vanilla JavaScript in the browser, one file, no build step. Matter.js 0.19.0 is vendored at `prototype/vendor/matter.min.js`, and the fonts (Lilita One 400, Nunito variable 800–900, latin woff2) are in `prototype/fonts/` with local `@font-face` rules. It needs no network (source URLs are in `prototype/README.md`).
- App: **Godot 4.7.2.stable.official (ed1daf0bf) + GDScript** in `godot/`, Android first (ADR 0002). Installed with `brew install --cask godot` (`/Applications/Godot.app`, CLI `/opt/homebrew/bin/godot`). Renderer `gl_compatibility` (widest Android support), built-in GodotPhysics2D at 60 ticks with 16 solver iterations, gravity 1000 px/s². Physics-parity rules are in ADR 0006.
- Not installed yet (stage 4): Godot export templates, JDK 17, Android SDK/NDK, debug keystore.

## UI / presentation layer

- Prototype: HTML5 canvas 2D, hand-drawn particles/effects. Physics: **Matter.js**.
- Godot: everything is drawn procedurally in `_draw()` (`scripts/view.gd`, `background.gd`), mirroring the canvas code. No sprites or particle nodes yet. UI is built in code (`scripts/hud.gd`) with the Lilita One font copied to `godot/assets/fonts/`.

## Data layer

- Levels are coded as coordinate data in JS (40 levels). There is no backend.

## Auth / storage / persistence

- Prototype: localStorage (progress, toggles). Godot: `user://save.json` (`autoload/save.gd`, same shape `{unlocked, stars, blood, music}`). No auth.

## External integrations

- None yet. Planned: AdMob (rewarded + interstitial, no banners), Firebase Analytics. TBD.

## Tooling (build, test, lint, CI)

- Prototype was verified with headless auto-play (random shots across all levels, checking stability, clearability, and causeless deaths). The test hook is `window.__dbg`. Local dev: the `prototype` config in `.claude/launch.json` runs `python3 -m http.server` on port 8080. Godot tests: `godot/tests/run.sh <smoke|sweep|shooters|selfharm>` runs a test scene headless with `--fixed-fps 60` (without it, headless runs in real time) and a watchdog (a script error doesn't make Godot exit). Diagnostics: `trace`, `trace_enemies`, `grid` (prints JSON lines to compare against the prototype's `__dbg`), `shot` (needs a window; saves PNGs). Root `./check.sh` runs scenes registered in `godot/tests/suites.txt`, checks exits/errors/PASS markers and saves logs under ignored `.check-logs/`. Level-data validation rejects invalid opcodes, arity, numeric geometry, materials and missing named-body references; FX/death/knight regression suites are included. Porting settings and unit rules are recorded in `context/build-guide.md`.

## What we deliberately did NOT pick

_(Things that were on the table and lost. Each entry: what it was, why it lost. Saves future-you from re-litigating.)_

- **Capacitor wrapper, Expo/React Native, Unity, Phaser.** All lost to Godot 4 for the native app. See ADR 0002.

## Stage-2 audio and verification

- Godot audio: generated mono 22.05 kHz AudioStreamWAV cached in RangerAudio, AudioStreamPolyphonic buses (32 SFX / 64 music voices), 112 BPM prototype score, real-time duck hold/envelope. Approximate filters and discrete echo repeats preserve score/effect timings; audition remains outstanding.
- Tests refresh Godot imports before running and reject general engine ERROR lines as well as script failures. Physics bots skip repeated canvas redraws; screenshot scenes opt in. Scene teardown gives the async audio mixer 60 ms to release voices. Stored real-input shots use passive settling on levels 1–5 and active firing on hostile levels; a bounded ammo/angle sweep can replace a chaotic replay (ADR 0006).

- Stage2 registers quantitative knight/jet/boss suites and fourteen original-numbered levels. Flame missiles use RigidBody2D movement plus Area2D sensors; no extra dependencies or installs.
