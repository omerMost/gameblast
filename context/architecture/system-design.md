<!--
What this file answers: the shape of the project — what modules exist, where responsibilities live, and why it's drawn this way.
When to update: any new module, renamed boundary, or refactor that moves responsibility across a boundary. Same turn as the code change.
-->

# System design

## Shape (one paragraph)

Today the whole game is one HTML file (`prototype/index.html`), with no build step and no backend. Matter.js runs the physics. A fixed-step simulation (60 Hz, at most 4 steps per animation frame, run slower during slow-mo) is decoupled from the canvas renderer. Gameplay rules sit on top of the engine through two Matter events (`beforeUpdate` and `collisionStart`) and a per-step `step()` function. `mobile/` (Expo) and `site/` are empty scaffolds. The native app will be a Godot 4 port in `godot/` (ADR 0002).

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

## Why this shape

- One file because it was built and published as a claude.ai artifact, which had to be a single page.
- Kills and damage go through `later()` because removing bodies inside `collisionStart` breaks Matter.js.
- The player has infinite inertia (can't rotate). This fixed the "dying for no reason" bug, where launcher recoil tipped the soldier over (see `sessions/2026-10-02-22-31-*`). **Don't remove it.**
