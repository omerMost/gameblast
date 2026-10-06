<!--
What this file answers: the shape of the project — what modules exist, where responsibilities live, and why it's drawn this way.
When to update: any new module, renamed boundary, or refactor that moves responsibility across a boundary. Same turn as the code change.
-->

# System design

## Shape (one paragraph)

Today the whole game is one HTML file (`prototype/index.html`), with no build step and no backend. Matter.js runs the physics. A fixed-step simulation (60 Hz, at most 4 steps per animation frame, run slower during slow-mo) is decoupled from the canvas renderer. Gameplay rules sit on top of the engine through two Matter events (`beforeUpdate` and `collisionStart`) and a per-step `step()` function. `mobile/` (Expo) and `site/` are empty scaffolds. The native app is a Godot 4 port in `godot/` (ADR 0002), at stage 1; its layout is below.

## Block diagram

```
LEVELS[] (data + build(b) fns)
      │ build(i)
      ▼
 builder API ──► Matter world (bodies, constraints)
                      │
 input (drag aim) ─► fire() ─► projectiles
                      │
 frame() ─► step() ─► Engine.update ─┬─ beforeUpdate: rocket lift, black holes, balloons, upright/hover AI forces
                │                    └─ collisionStart → hit(): kill/damage/explode/pop
                ├─ portals/ropes/wells, enemy AI, delayed queue (later())
                └─ checkEnd() → won/lost overlays, localStorage progress
      ▼
 render(): canvas 2D + particles/decals ; Web Audio sfx + procedural music
```

## Module boundaries (sections inside `index.html`)

- **LEVELS**: pure data. Each level has a name, a view rectangle, ammo, a par score, optional portals and wells (black holes), and a `build(b)` function that only calls the builder API.
- **BUILDERS**: `makeBuilder()` (ground, platforms, walls, pads, slopes, blocks, enemies, boulders, barrels, hanging ropes, tethers, balloons, bridges) plus the character factories (`makeChar`, `makeTitan`, `makeDragon`). This is the only place that creates level bodies.
- **FORCES / SIM STEP**: all per-step rules. Damage and kills are deferred with `later()` so the physics world isn't mutated in the middle of a collision callback.
- **CHARACTERS / EXPLOSIONS**: death, ragdolls, gibs, player damage, and death causes (`CAUSES`). `explode()` is the single source of blast impulses, damage, rope cutting and barrel chains.
- **FX / DRAWING / SOUND**: render and audio only. They never change the physics.
- **UI / INPUT**: overlays, HUD and the drag-to-aim gesture. Saved progress lives in `localStorage['blastRanger2']`.

## Godot port (`godot/`, stage 1)

Same shape as the prototype, split into files. The prototype stays the spec (ADR 0002); physics-parity rules are in ADR 0006.

```
godot/
  project.godot          2D, landscape (sensor), stretch canvas_items + expand, 60 ticks, gravity 1000
  scenes/main.tscn       -> scripts/main.gd: builds Background, Game(+View), Camera2D, Hud; drag-aim input; camera fit (layout())
  scripts/consts.gd      C: unit conversion, blast radii/powers, MAT table, collision layers, CAUSES
  scripts/gbody.gd       GBody (RigidBody2D): kind + p (Matter plugin) + loc anchors, prev_v, per-shape contacts, Matter inertia
  scripts/gstatic.gd     GStatic (StaticBody2D): ground/plat/wall/pad/slope + crack decoration
  scripts/level_builder.gd  replays level ops; body factories (add_block, make_char, boulder, barrel). Only creator of level bodies
  scripts/game.gd        Game: the sim (step, later() queue, hit(), explode(), shatter(), ragdolls, damage, enemies, portals, fire, predict, end checks, FX particle data)
  scripts/view.gd        world renderer (_draw under the camera); never touches physics
  scripts/background.gd  screen-space sky/sun/clouds/dunes
  scripts/hud.gd         HUD chips, weapon buttons, hint, title/levels/result cards, aim gizmo, flash/hurt overlay
  levels/levels.gd       LEVELS[] as data ({name, view, ammo, par, hint, portals, build:[ops]}); levels 1-5 so far
  autoload/save.gd       Save: user://save.json
  autoload/debug.gd      Debug: window.__dbg mirror (start_level, set_aim, fire, step, alive, state, predict) + event log
  tests/                 headless test scenes + run.sh (see tech-stack.md)
```

Mapping: Matter `collisionStart` → `body_shape_entered` → `Game.hit()` (flags + `later()` only); Matter `beforeUpdate` → `Game._before_update()` at the end of `_physics_process`; Godot flushes contact signals *before* `_physics_process`, so `later(0)` runs in the same tick as in Matter. Bodies are removed only from `_physics_process` (`remove_body()`); the dead player node is detached but kept until the next level so the lose card can read `cause`.

## Why this shape

- One file because it was built and published as a claude.ai artifact, which had to be a single page.
- Kills and damage go through `later()` because removing bodies inside `collisionStart` breaks Matter.js.
- The player has infinite inertia (can't rotate). This fixed the "dying for no reason" bug, where launcher recoil tipped the soldier over (see `sessions/2026-10-02-22-31-*`). **Don't remove it.** The Godot port keeps it as `player.lock_rotation = true` in `Game.start_level()`.
