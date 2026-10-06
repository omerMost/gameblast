# ADR 0007 — Sparse stage-2 levels and distance constraints

**Status:** Provisional — pending user review of the morning page
**Date:** 2026-10-07
**Supersedes:** none; refines ADRs 0002 and 0006

## Context
Stage 2 ports introduction levels before stage 3 fills all 40. Original level numbers must keep matching the prototype. Matter ropes retain a finite distance between attachment points; a Godot PinJoint collapses them to one pivot, and spring-only connections can stretch under the balloon raft's load.

## Decision
- Retain original level-index positions with `null` for unavailable levels. A shared available-level list drives UI, progression and tests; next/restart/start never select a placeholder. This implements run-plan provisional call P1.
- Use a small `WorldMechanics` distance-constraint solver for ropes/bridge links, with mass/inertia weighting and angular attachment offsets. Run eight constraint iterations per tick, retaining prototype attachment points, lengths, stiffness and damping. Ropes remain cuttable by shots and blasts. Godot owns rigid-body contact simulation.
- Bouncy-pad contacts correct the outgoing normal component to the pre-step incoming speed: Godot adds material restitution while Matter takes its maximum. Preserve tangential velocity.
- Default verification replays stored winning inputs through the real game; the exhaustive sweep remains available to discover replacements. A newly playable level must have a successful replay before landing.

## Alternatives
- Renumber introduction levels contiguously: confuses prototype references and later content import.
- Enable all unported levels: exposes missing content.
- Native PinJoint: changes finite-length ropes into pivot connections.
- DampedSpringJoint alone: does not enforce the prototype's rope length under steady lift; alternative if later tuning proves equivalent.
- Run exhaustive sweeps on every commit: grows with levels and ammo; still useful as a diagnostic but unnecessary when stored solutions prove current content.

## Evidence and consequences
World mechanics tests cover rope support/cutting, bridges, balloon lift/pop, pad restitution, well acceleration/preview/swallowing and progression gaps. Levels 21–24 clear with original ammo/par and player survival; Sky raft retains all targets for 300 idle ticks with ~2.4px drift. This establishes stability and clearability, not exact Matter solver parity. Custom constraint feel and pad corner contacts remain provisional; compare against the prototype before final difficulty tuning in stage 3.
