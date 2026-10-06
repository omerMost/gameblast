# STATE — current snapshot

**Rewritten (not appended to) at the end of every session.** Sessions are append-only history; ADRs are decision records; STATE is the snapshot of "what does this project actually look like right now."

If this is out of sync with the code, the code wins — but raise it as a bug, because keeping STATE current is part of the working discipline (see CLAUDE.md).

**Last updated:** 2026-10-06

---

## At a glance

Blast Ranger — physics bazooka shooter game for Android/iOS.

- **The game lives in [`prototype/index.html`](../prototype/index.html).** It's a single-file HTML5 + Matter.js browser game with 40 levels, built in a claude.ai chat on 2026-10-02 → 04 and copied into the repo on 2026-10-06. **The repo copy is now the source of truth.** The old public claude.ai artifact (https://claude.ai/artifact/UbwwHgS9yqQbwwpup9xNoE) is what friends still play, and it **does not update from the repo**. History: `sessions/2026-10-02-22-31-*`, `2026-10-03-22-00-*`, `2026-10-04-14-35-*`.
- **Native app: Godot 4, Android first (ADR 0002).** The port goes into `godot/` (not created yet), done in stages by the `godot-porter` agent. None of the toolchain is installed yet (Godot, JDK, Android SDK).
- `mobile/` is an untouched Expo template, unused since ADR 0002. `site/` is empty.

## Surfaces / components / modules

- **`prototype/index.html`** — the whole game in one file. Its sections are LEVELS, STATE, BUILDERS, FORCES, CHARACTERS, EXPLOSIONS, PORTALS/ROPES/WELLS, FIRING, SIM STEP, FX, SOUND & MUSIC, DRAWING, LOOP, INPUT and UI. `window.__dbg` exposes `build`, `step`, `fire`, `startLevel`, `setAim`, `predict` and `alive` for headless testing. The game has drag-back aim with trajectory preview (follows portals, curves around black holes). Weapons: grenade (arc, bounce, fuse), rocket (straight, impact). Mass-aware blast impulse with falloff, stone occludes blasts, wood/ice fracture, ragdolls/gibs, chain-reacting barrels. Player has 100 HP with self-damage; dies only at 0 HP or off-map, and the death screen names the cause. Enemies: basic, rifleman (line of sight), archer, sword+shield knight, jetpack trooper, titan (belly-only weak spot), dragon (grenade-in-mouth only). Level objects: portals (velocity-preserving), ropes, balloons, black holes, bouncy walls. 3-star scoring, localStorage progress, blood toggle, light music with ducking + toggle.
- **`mobile/`** — Expo scaffold, not yet run.
- **`site/`** — empty surface scaffold.

## Stack

- Prototype: vanilla HTML5 canvas + Matter.js 0.19.0 (vendored in `prototype/vendor/`), local woff2 fonts in `prototype/fonts/`, Web Audio, localStorage. **Runs fully offline.**
- App: Godot 4 + GDScript (ADR 0002), not started. `mobile/` Expo scaffold unused.

## Known gaps (not bugs, just not done)

- The public artifact link is a frozen copy and won't pick up changes made in the repo.
- No native build, no ads, no analytics, no store listings, no privacy policy.
- Prototype isn't app-ready: it uses localStorage (no reliable storage), and has no icons/splash, orientation lock or keep-awake.
