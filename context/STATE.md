# STATE — current snapshot

**Rewritten (not appended to) at the end of every session.** Sessions are append-only history; ADRs are decision records; STATE is the snapshot of "what does this project actually look like right now."

If this is out of sync with the code, the code wins — but raise it as a bug, because keeping STATE current is part of the working discipline (see CLAUDE.md).

**Last updated:** 2026-10-07

---

## At a glance

**Working methods (ADRs 0003–0005, adopted 2026-10-07, taken from the friend's RareDrop project):** the AI builds and verifies everything (`check.sh`, bots, decision cards, playtest notes). Claude commits its own verified work and pushes `main` after every landing. Overnight runs leave a morning page.

Blast Ranger — physics bazooka shooter game for Android/iOS.

- **The game lives in [`prototype/index.html`](../prototype/index.html).** It's a single-file HTML5 + Matter.js browser game with 40 levels, built in a claude.ai chat on 2026-10-02 → 04 and copied into the repo on 2026-10-06. **The repo copy is now the source of truth.** The old public claude.ai artifact (https://claude.ai/artifact/UbwwHgS9yqQbwwpup9xNoE) is what friends still play, and it **does not update from the repo**. History: `sessions/2026-10-02-22-31-*`, `2026-10-03-22-00-*`, `2026-10-04-14-35-*`.
- **Native app: Godot4, Android first (ADR0002). Stages1–4 are merged into `main` and verified (15 suites green; bot40/40).** All40 original levels, stage2 enemies/world/audio and stage4 Android/device fixes are integrated in `/Users/omer/prod/blast/gameblast`. Signed ARM64 debug APK is installed on the connected Android16 phone; the user confirmed "ok it feels good". Godot4.7.2, JDK17.0.20.1, SDK36/build-tools36.1.0 and matching templates are verified. Development history remains on `run/godot-stage-2` and `codex/stage4-android`; scratch worktrees were not merged.
- `mobile/` is an untouched Expo template, unused since ADR 0002. `site/` is empty.

## Surfaces / components / modules

- **`prototype/index.html`** — the whole game in one file. Its sections are LEVELS, STATE, BUILDERS, FORCES, CHARACTERS, EXPLOSIONS, PORTALS/ROPES/WELLS, FIRING, SIM STEP, FX, SOUND & MUSIC, DRAWING, LOOP, INPUT and UI. `window.__dbg` exposes `build`, `step`, `fire`, `startLevel`, `setAim`, `predict` and `alive` for headless testing. The game has drag-back aim with trajectory preview (follows portals, curves around black holes). Weapons: grenade (arc, bounce, fuse), rocket (straight, impact). Mass-aware blast impulse with falloff, stone occludes blasts, wood/ice fracture, ragdolls/gibs, chain-reacting barrels. Player has 100 HP with self-damage; dies only at 0 HP or off-map, and the death screen names the cause. Enemies: basic, rifleman (line of sight), archer, sword+shield knight, jetpack trooper, titan (belly-only weak spot), dragon (grenade gulp or blast at its open mouth; source hint simplifies this). Level objects: portals (velocity-preserving), ropes, balloons, black holes, bouncy walls. 3-star scoring, localStorage progress, blood toggle, light music with ducking + toggle.
- **`godot/`** — Godot 4.7.2 port, stages1–4 complete on `main`. It has a title screen, a level select (all40 levels, preserving prototype numbers on the stage3 branch), the camera fitted to each level's `view` rect, drag-back aim with the dotted trajectory (follows portals), grenade (arc, bounce, 140-tick fuse) and rocket (straight, 0.2 g, CCD, explodes on impact). `explode()` gives a mass-aware falloff impulse occluded by statics and stone. Wood/stone/sand/ice have fracture. There are basic, shooter, archer, knight, jetpack, titan and dragon enemies (line-of-sight bullets), ragdolls/gibs, chain-reacting barrels, portals (level 5 needs one), player HP with death causes, a HUD, win/lose with 3 stars, and save to `user://save.json`. The `Debug` autoload mirrors `window.__dbg`. Layout: `architecture/system-design.md`. Physics-parity rules (inertia ×4, per-shape contacts, grenade bounce 0.40): ADR 0006. Tests: `./check.sh` verifies source fidelity and runs15 registered headless suites including content validation, smoke, shooters, selfharm, death, FX, archers, knights, jetpacks, bosses, world mechanics, audio and a real-input bot. The bot clears all40 levels; the exhaustive sweep remains a diagnostic. Death cards cover all 10 causes. FX includes ongoing ragdoll bleeding, blood-off debris, clipped blood/scorch decals and proportional overhead HP. Port rules: `context/build-guide.md`. WorldMechanics adds cuttable ropes/bridge links, buoyant balloons, pads and wells with curved previews. RangerAudio adds procedural SFX/music with ducking and toggles. ADR 0007 records provisional constraints and sparse progression. Knights run/jump/climb, delay sword hits, shield frontal blasts and drop physical weapons. Jetpacks hover, lob 110-tick grenades with a position-following ring and explode their pack 14 ticks after death. BossAI adds armored titans with core weakpoints/chase/jump/smash and hovering dragons with charge/fire sensors, open-mouth blast vulnerability and grenade gulp. Stage3 adds all40 source-derived definitions, source-fidelity validation, lifecycle/progression regressions and recorded new-level inputs. Android debug APK at ignored `godot/build/blast-ranger-debug.apk`, package `com.omerevan.blastranger`; landscape/keep-awake, existing launcher artwork and picker SVG pictures. Saved stars/unlocks survive an APK update. Android drawing is capped60FPS; decals retain pretriangulated meshes, weapon styles are cached, Android SFX are prewarmed, and title settings have fixed56px toggle targets.
- **`mobile/`** — Expo scaffold, not yet run.
- **`site/`** — empty surface scaffold.

## Stack

- Prototype: vanilla HTML5 canvas + Matter.js 0.19.0 (vendored in `prototype/vendor/`), local woff2 fonts in `prototype/fonts/`, Web Audio, localStorage. **Runs fully offline.**
- App: Godot 4.7.2 + GDScript (ADR 0002, 0006), `gl_compatibility` renderer, built-in 2D physics. Headless tests need `--fixed-fps 60` (`tests/run.sh` adds it). `mobile/` Expo scaffold unused.

## Known gaps (not bugs, just not done)

- Connected-device playtest accepted by the user on2026-10-07: "ok it feels good" after the toggle/rendering/audio fixes. Phone samples held60FPS with101marks during play and260marks after a win. No permanent missile stall reproduced; if it recurs, capture the level/shot and `BR_PERF`. Broader device coverage remains untested.
- The public artifact link is a frozen copy and won't pick up changes made in the repo.
- Native debug APK installed on one Android16 ARM64 device; release signing/AAB and broader device coverage remain. No ads, no analytics, no store listings, no privacy policy.
- The Godot port is a bit harder than the prototype in edge cases (ADR 0006 lists the gaps). FX uses flat colors instead of web gradients. Rope solver feel and PCM/echo/scheduling parity remain provisional; generated audio has not been auditioned through speakers.
- Prototype isn't app-ready: it uses localStorage (no reliable storage), and has no icons/splash, orientation lock or keep-awake.
