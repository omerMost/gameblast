# ADR0011 — Cache drawable decal meshes

**Status:** Provisional (AI response to device playtest).
**Date:** 2026-10-07
**Refines:** ADR0010's decal cache.

## Context
The connected phone reported a missile hitch. Debug logs showed38.8–43.6FPS with260decals, including a quiet frame with zero particles. Caching clipping/validity alone still left Godot triangulating each colored polygon on every redraw.

## Decision
Triangulate clipped decal geometry once into a retained ArrayMesh per ellipse/cache key. Draw it with the original color/modulation and ordering. Lifetime follows the existing260-decal list, cleared on level reload. Preserve blood-off filtering and platform clipping. Warm existing procedural SFX during Android startup to avoid generating the first boom during collision handling.

## Alternatives
Dropping marks/reducing blood would change visible effects. A baked decal texture or separate canvas layers could reduce draw calls further but require extra rendering architecture and change overlap/order. Retained meshes remove repeated triangulation without either tradeoff. Cold mesh/clipping creation remains a possible burst cost; device samples are needed.

## Sources
Godot's [CanvasItem documentation](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-draw-colored-polygon) recommends precomputed triangulation and meshes for frequently redrawn polygons.
