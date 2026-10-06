# ADR 0009 — Resolve delayed body callbacks before invocation

**Status:** Provisional — AI lifecycle fix pending human review
**Date:** 2026-10-07
**Supersedes:** none

## Context / decision
Stage3 Siege/Monster mash searches reproduced a delayed archer callback whose enemy had been removed/freed during its18tick draw. Godot rejects a freed Object argument before entering a typed GBody function, so its existing in-world guard never runs. `Game.later_body` stores a weak reference, resolves it when due, and invokes the typed callback only while the body is still in the world. Apply it to arrow/nade/sword/smash/gulp, contact missile/rocket/balloon and delayed barrel callbacks. Preserve original timing and all live-body behavior; target removal cancels the action. Secondary flame-contact targets stay untyped and are checked for validity.

## Alternatives / evidence
Untype every callback and scatter validity checks: works but loses typed interfaces and permits repeat mistakes. Globally prune queue entries: requires callback argument introspection and may discard coordinate-only events such as delayed fuel explosions. A common body scheduler keeps these distinct. Lifecycle test removes/frees a drawing archer before release and proves no arrow/error; stage3 real-input replays cover previously failing paths. Existing actor-specific checks remain useful after the generic guard.
