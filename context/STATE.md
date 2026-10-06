# STATE — current snapshot

**Rewritten (not appended to) at the end of every session.** Sessions are append-only history; ADRs are decision records; STATE is the snapshot of "what does this project actually look like right now."

If this is out of sync with the code, the code wins — but raise it as a bug, because keeping STATE current is part of the working discipline (see CLAUDE.md).

**Last updated:** 2026-10-07

---

## At a glance

**Working methods (ADRs 0003–0005, adopted 2026-10-07, taken from the friend's RareDrop project):** the AI builds and verifies everything (`check.sh`, bots, decision cards, playtest notes). Claude commits its own verified work and pushes `main` after every landing. Overnight runs leave a morning page.

Blast Ranger — physics bazooka shooter game for Android/iOS.

- **The game lives in [`prototype/index.html`](../prototype/index.html).** It's a single-file HTML5 + Matter.js browser game with 40 levels, built in a claude.ai chat on 2026-10-02 → 04 and copied into the repo on 2026-10-06. **The repo copy is now the source of truth.** The old public claude.ai artifact (https://claude.ai/artifact/UbwwHgS9yqQbwwpup9xNoE) is what friends still play, and it **does not update from the repo**. History: `sessions/2026-10-02-22-31-*`, `2026-10-03-22-00-*`, `2026-10-04-14-35-*`.
- **Native app: Godot 4, Android first (ADR 0002). Stage 1 of 4 is done** (`godot/`, Godot 4.7.2): core loop plus levels 1–5, verified headlessly. Stage 2 (all enemies and features) is next. Godot is installed; the Android toolchain (export templates, JDK 17, SDK) is not.
- `mobile/` is an untouched Expo template, unused since ADR 0002. `site/` is empty.

## Surfaces / components / modules

- **`prototype/index.html`** — the whole game in one file. Its sections are LEVELS, STATE, BUILDERS, FORCES, CHARACTERS, EXPLOSIONS, PORTALS/ROPES/WELLS, FIRING, SIM STEP, FX, SOUND & MUSIC, DRAWING, LOOP, INPUT and UI. `window.__dbg` exposes `build`, `step`, `fire`, `startLevel`, `setAim`, `predict` and `alive` for headless testing. The game has drag-back aim with trajectory preview (follows portals, curves around black holes). Weapons: grenade (arc, bounce, fuse), rocket (straight, impact). Mass-aware blast impulse with falloff, stone occludes blasts, wood/ice fracture, ragdolls/gibs, chain-reacting barrels. Player has 100 HP with self-damage; dies only at 0 HP or off-map, and the death screen names the cause. Enemies: basic, rifleman (line of sight), archer, sword+shield knight, jetpack trooper, titan (belly-only weak spot), dragon (grenade-in-mouth only). Level objects: portals (velocity-preserving), ropes, balloons, black holes, bouncy walls. 3-star scoring, localStorage progress, blood toggle, light music with ducking + toggle.
- **`godot/`** — Godot 4.7.2 port, stage 1. It has a title screen, a level select (levels 1–5), the camera fitted to each level's `view` rect, drag-back aim with the dotted trajectory (follows portals), grenade (arc, bounce, 140-tick fuse) and rocket (straight, 0.2 g, CCD, explodes on impact). `explode()` gives a mass-aware falloff impulse occluded by statics and stone. Wood/stone/sand/ice have fracture. There are basic and shooter enemies (line-of-sight bullets), ragdolls/gibs, chain-reacting barrels, portals (level 5 needs one), player HP with death causes, a HUD, win/lose with 3 stars, and save to `user://save.json`. The `Debug` autoload mirrors `window.__dbg`. Layout: `architecture/system-design.md`. Physics-parity rules (inertia ×4, per-shape contacts, grenade bounce 0.40): ADR 0006. Tests: `godot/tests/run.sh smoke|sweep|shooters|selfharm`. **Not yet:** sound, archers/knights/jet/titan/dragon, ropes/balloons/black holes/pads in levels, levels 6–40, Android export.
- **`mobile/`** — Expo scaffold, not yet run.
- **`site/`** — empty surface scaffold.

## Stack

- Prototype: vanilla HTML5 canvas + Matter.js 0.19.0 (vendored in `prototype/vendor/`), local woff2 fonts in `prototype/fonts/`, Web Audio, localStorage. **Runs fully offline.**
- App: Godot 4.7.2 + GDScript (ADR 0002, 0006), `gl_compatibility` renderer, built-in 2D physics. Headless tests need `--fixed-fps 60` (`tests/run.sh` adds it). `mobile/` Expo scaffold unused.

## Known gaps (not bugs, just not done)

- The public artifact link is a frozen copy and won't pick up changes made in the repo.
- No native build (no Android export yet), no ads, no analytics, no store listings, no privacy policy.
- The Godot port is silent and a bit harder than the prototype in edge cases (ADR 0006 lists the gaps). Decals aren't clipped to the ground.
- Prototype isn't app-ready: it uses localStorage (no reliable storage), and has no icons/splash, orientation lock or keep-awake.
