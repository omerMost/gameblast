# ADR 0006 — Godot physics parity rules (Matter.js → GodotPhysics2D)

**Status:** Accepted
**Date:** 2026-10-07
**Supersedes:** _(none)_. Refines ADR 0002 ("retune until it feels like the prototype").

## Context

Stage 1 of the port (`godot/`) copies the prototype's numbers 1:1 (unit conversion in `scripts/consts.gd`). Running the same 256 single shots on levels 1–5 in both engines (the prototype through `__dbg`, Godot through `tests/grid.gd`) showed that a straight copy made Godot noticeably harder: only 220/256 outcomes matched (the prototype matches itself on 251/256), and one-shot clears were 15 vs 24. Tracing showed concrete engine differences, not noise. These fixes look like arbitrary magic numbers, so they're written down here before someone "cleans them up".

## Decision

1. **Inertia = 4 × Matter's geometric inertia.** Matter.js sets `Body._inertiaScale = 4`, and a compound body's inertia is the plain sum of its parts' (no parallel-axis term). `GBody.matter_inertia()` reproduces this for blocks, boulders, barrels, characters, rags and grenades. Without it, towers and enemies tip over far too easily.
2. **Per-shape contact events.** Matter fires `collisionStart` per *part* pair, so `GBody` uses `body_shape_entered`, not `body_entered`.
3. **Impact speed uses the velocity from before the step.** `prev_v` is cached at the end of `_physics_process`, because Matter's `collisionStart` sees velocities from before the solver runs.
4. **Grenade bounce 0.40, not 0.45.** Godot applies restitution exactly; Matter's solver loses energy (measured flat-ground bounce ratios of 0.36–0.44 for 0.45).
5. **Rocket "lift" = `gravity_scale 0.2`, bullets `gravity_scale 0`** instead of per-step counter-forces. Rockets get CCD (`CCD_MODE_CAST_SHAPE`), as do bullets.
6. **Mass = Matter mass (area × density)**, so the formulas `min(power·f, 20·m)`, the mass-ratio kill checks and the `J/m` velocities stay as they are. Velocities convert as px/s = px/step × 60.

After 1–4: 229/256 outcomes match and one-shot clears are 16 vs 24. Rocket self-damage matches exactly (47/61 on the same shots).

## Alternatives considered

- **Pure 1:1 copy, no retuning.** Measurably harder and tippier than the prototype. Rejected: the prototype is the spec for feel.
- **Port Matter.js's solver or use a custom physics step.** Exact parity, but it gives up Godot's CCD, performance and the reason for the port (ADR 0002).
- **Scale every level's ammo/par to Godot's difficulty.** It treats the symptom and changes the spec. Level tuning belongs in stage 3.

## Consequences

- Remaining known gaps: Matter treats circles as 10–25-gons, so corner hits (e.g. a grenade clipping a narrow pillar) deflect differently. Matter's spinning grenades also grip the ground harder on a bounce. On level 2, debris more often kills the bottom enemy in the prototype (a flat rocket clears it 5/32 times in the prototype vs 0 in Godot). Every level 1–5 is still clearable at par.
- Godot's physics is reproducible between runs, but a shot's outcome depends on what was simulated earlier in the same process. Chaotic shots can flip, so tests must not rely on one exact outcome.
- Any new body type must call `matter_inertia()`. Stage 2/3 should re-run `tests/grid.gd` against the prototype when adding mechanics.
