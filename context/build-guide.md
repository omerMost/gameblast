# Build guide

The web prototype (`prototype/index.html`) is the gameplay spec. Port its rules and numbers before tuning difficulty. The native runtime is Godot 4.7.2, GDScript, built-in GodotPhysics2D and `gl_compatibility` (ADRs 0002, 0006).

## Fixed settings and units

- Landscape sensor orientation, 1280×720 virtual viewport, `canvas_items` stretch with `expand`; `main.gd` fits each level's view between the HUD bars.
- Physics: 60 ticks/s, gravity 1000 px/s², 16 solver iterations, zero global linear/angular damping.
- Matter velocity ×60 = Godot px/s; Matter acceleration ×3600 = Godot px/s². Angular velocity ×60 = rad/s.
- Mass = area × prototype material density. Per-tick Matter force ×`C.FORCE_IMPULSE` becomes a Godot impulse; continuous forces require the additional tick-rate conversion.
- Every new dynamic shape uses `matter_inertia()`: 4× the geometric inertia, summing compound parts without the parallel-axis term. Enemy-specific multipliers apply afterward.
- Player `lock_rotation = true` is mandatory. It preserves the fix for unexplained recoil deaths.
- Rockets: CCD, gravity scale 0.2. Bullets: CCD, gravity scale 0. Grenades: bounce 0.40 (prototype 0.45 loses energy in Matter), fuse 140 ticks.
- Grenade blast radius/power 125/30; rocket 110/32; barrel 150/40. All blast impulses go through `Game.explode()` with mass-aware falloff and stone/static occlusion.

## Boundaries and ordering

`LevelBuilder` owns shape creation. `Game` owns simulation and delayed actions. `View`, `Background` and audio render effects without changing physics. Levels are coordinate data; keep prototype numbering and retain the original ammo/par values.

Godot flushes per-shape contacts before `_physics_process`. Contact handlers set flags and schedule `later()`; defer body removal, kills and explosions until the simulation queue runs. Cache pre-step velocities for impact damage. The dead player remains readable until the next level because the result card reads its cause.

Start each level with 30 settle ticks, then clear velocities and queued actions. The prototype settles synchronously for 80 ticks; this is a known presentation difference. Never run tests against the user's save: `TestUtil.boot()` disables persistence.

## Verification and landing

Run `./check.sh` before every commit. It reads `godot/tests/suites.txt`; each scene must return success and print `RESULT: PASS`, with no script errors or watchdog timeout. Individual scene: `godot/tests/run.sh <suite>`. The runner supplies `--fixed-fps 60`; headless without it runs in real time.

Verify the real simulation: damage has a cause, enemies retain their intended defenses, every ported level can be cleared within ammo, and trajectories use the same forces as projectiles. Add meaningful regression assertions for new mechanics. Idle checks for moving enemies/ropes must check survival and bounded motion rather than demand zero drift. Inspect rendered gameplay states as well as headless results.

After each step, update STATE, affected architecture documents, backlog/done, run checklist and a session note. Generate the session filename with a fresh `date +%Y-%m-%d-%H-%M` immediately before writing it. Stage only owned paths. Overnight work stays on `run/<slug>` with one verified commit per step and a morning page; merge after user review (ADR 0005).

No Android toolchain installation is part of the stage-2 run. Stage 4 must verify installed SDK/JDK/export templates before exporting.

Stage-2 specifics (ADR 0007): sparse level slots stay null until ported; always iterate available_levels and use next_level for progression. WorldMechanics performs eight distance-constraint iterations and only writes velocity for nonzero well acceleration. Pads preserve incoming normal speed rather than add restitution. New enemy missiles live in Game.bodies so wells affect them; their helper arrays must also be cleared when removed. Root check imports new class scripts and rejects any engine ERROR. Default bot replays real shots; passive levels wait for the rolling scenery to settle, hostile levels fire once the launcher is free, and bounded search handles chaotic alternatives.

## Boss and jet source details

Keep original numbered intro levels25/31/33 and original ammo/par. Jet pack blast is14ticks after death (radius80,power20); grenade warning ring follows current position. Titan/dragon compound inertia multipliers are10/6. Flames are sensors (0.15gravity), so they damage via deferred contact without shoving solids. The dragon hint says grenade-only, but executable explode also accepts any blast within32px of its open mouth; preserve that exception.

## Stage3 content and verification

All40 definitions are generated from prototype declarations: run `node scripts/export-levels.js`, and `--check` to reject drift. Do not hand-edit generated coordinates/ammo/par. Original1-based keys in `stage3_early/mixed/monsters.gd` SHOTS feed bot.gd; optional fourth shot field is a real wait in ticks. ContentSearch runs only real launcher inputs and original ammo. Regenerate diagnostics with `content_search.tscn -- --level=N`; stored proof scenes remain available separately. Select the requested weapon before polling can_fire.

Use `later_body` for a typed delayed callback whose body may die during its windup; normal later remains for coordinate-only callbacks. Idle stability excludes bullets/arrows/nades/flames from scenery motion. Knights/hovering bosses/mobile bridges remain bounded; L29/33/35/39 source-alerted attacks produce explicit expected HP78/90/73/84 at300ticks. Player and all enemies must survive with named causes and finite transforms.

On macOS, screenshot diagnostics awaiting RenderingServer.frame_post_draw can stall while the Godot window is occluded even though physics continues. Keep the diagnostic window visible (`--always-on-top`, activate Godot) and use a watchdog; do not interpret an occluded screenshot wait as a game freeze. Fully visible L40 aim/post-shot rendering completed cleanly in7.1s.
