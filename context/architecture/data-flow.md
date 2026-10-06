<!--
What this file answers: the happy-path walkthrough of the project's primary flow, from user input (or request) to final output.
When to update: any change that alters the sequence, adds a step, or changes where a step runs. Same turn as the code change.
-->

# Data flow

## Primary flow: aim → fire → blast → level result (`prototype/index.html`)

1. The player picks a level, and `startLevel(i)` calls `build(i)`. That creates a new Matter engine and runs `LEVELS[i].build(makeBuilder())`. It then spawns the player, settles the world for 80 steps, and zeroes all velocities so structures start at rest.
2. The player drags back on the canvas, which sets `aim` (direction and power). `predict()` draws the dotted path, and that path follows portals and bends around black holes.
3. On release, `fire()` checks `canFire()` (state is `play`, the player is alive, no projectile is in flight, ammo is left) and spawns a grenade or rocket with `launchVel()`.
4. `frame()` advances the simulation with `step()` at a fixed 60 Hz. During each step:
   - `beforeUpdate` applies the extra forces (rocket lift, black-hole pull, balloon lift, enemy upright/hover).
   - `collisionStart` → `hit()` defers kills and damage with `later()`.
   - Then come grenade fuses, dragon mouth gulps, enemy AI and the `later()` queue.
5. `explode()` applies a mass-aware, distance-falloff impulse (blocked by stone and walls), damages the player, cuts ropes, sets off barrels, breaks blocks and plays FX/SFX.
6. `checkEnd()`: if every enemy is dead the level is **won**; stars come from shots used against par, and progress is saved to localStorage. If the player hits 0 HP or falls off-map, or runs out of ammo with no movement left, the level is **lost** and the death screen shows the cause from `CAUSES`.

### Same flow in the Godot port (`godot/`)

`main.gd` → `Game.start_level(i)` replays `Levels.LEVELS[i].build` through `LevelBuilder`, spawns the player (`lock_rotation`), then **settles for 30 physics ticks** (state `settle`, input off) and zeroes velocities. Godot can't step physics synchronously, so this can't be done invisibly like the prototype's 80 steps. Drag → `aim`, `View` draws `predict()`; release → `Game.fire()`. Each tick: Godot flushes contact signals (`GBody` → `Game.hit()`, which only sets flags and calls `later()`), then `Game._physics_process` runs the step (portals, fuses, `later()` queue, enemy upkeep and AI, end check) and finally `_before_update()` (enemy upright torque, cache `prev_v` for the next impact-speed check), then Godot steps physics. Moving ragdoll parts emit blood/debris every third tick; particle updates create oriented blood decals, and View clips blood/scorch polygons to static ground. `explode()` uses the body AABB plus a ray query (statics and stone) for occlusion and `apply_impulse`. On win, stars go to `user://save.json` after the 1.7 s result delay.

## Failure paths

- **Missing vendored files** (`vendor/matter.min.js` not served next to `index.html`): `Matter` is undefined and the game doesn't start. Missing `fonts/*.woff2` only makes the text fall back to the system font stacks. The game doesn't need internet.
- **localStorage blocked** (private mode): every read and write is wrapped in try/catch, so progress just isn't saved.

## Trust boundaries

None. It's a client-only game with no network input. All scripts and fonts are served from the same origin.

Stage-2 additions: LevelBuilder resolves named bodies for hang/tether/balloon ops. Each physics tick updates ropes/well swallowing, arrow lifetimes and delayed archer releases and knight sword hits and jet grenade releases/fuses. Jet deaths queue the source14tick tank blast; ring telegraphs follow live grenade positions. Knight locomotion runs only when alerted; death queues physical sword/shield drops before removing its character. WorldMechanics applies constraints/lift/nonzero well acceleration before the next step; predict and enemy lob planning use its same acceleration function. Arrows are removed only from the deferred queue and can embed visual marks in living bodies or terrain. Game's sound_requested/player_hurt/result signals feed RangerAudio; explosion ducking runs on audio real time, independent of physics slow motion. Results unlock the next available level across placeholder gaps.

Boss flow: beforeUpdate stabilizes titan rotation and drives dragon hover. Alerted BossAI schedules titan smash16ticks/38HP, or dragon charge65/fire70 with a sensor flame every3ticks. Contacts defer5HP fire damage with9tick cooldown. A grenade within30px of an open mouth is removed and queues boss death40ticks later; any blast within32px can also kill while mouth is open, matching executable source. Titan blast core radius40; armor impulse multipliers0.12/0.15 for titan/dragon. Boss death creates ragdolls, FX, labels and audio.

Stage3 flow: prototype level declarations → recording builder/expanded operations → generated `Levels.LEVELS` → source-fidelity check + validator →40-level builder/UI/progression → recorded real-input bot. Every numeric level is available; next_level becomes consecutive1–40 while preserving existing saves and original indices. Delayed body actions enter later_body, resolve weak references when due and skip removed targets; coordinate-only events retain normal later. Test input selects the intended weapon before polling readiness, avoiding600tick idle when the previous weapon is exhausted.


Android packaging: source + imported icons → standard Godot Android template → signed debug APK in ignored `godot/build/` → `adb install -r` → launcher activity `com.godot.game.GodotAppLauncher`. Touch is emulated as mouse input, so the existing drag/release path drives firing. Save writes go to the app-private `files/save.json`; level1 three-star unlock was observed on the device. Debug-only `BR_PERF` logs report five-second FPS, worst frame interval and body/particle/decal counts.
