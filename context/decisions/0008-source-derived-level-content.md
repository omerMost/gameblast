# ADR 0008 — Source-derived level content

**Status:** Provisional — AI implementation choice pending human review
**Date:** 2026-10-07
**Supersedes:** none; completes stage3 content under ADR0007

## Decision
Generate all40 Godot level dictionaries from executable prototype declarations with `scripts/export-levels.js`: run only declarations in a Node VM with a recording builder; expand loops, record named rope loads, convert local points/options and alertAt spelling. Keep original order, geometry, ammo, par and metadata. `--check` compares committed data against a fresh export; `check.sh` requires that check. Existing14 definitions are regenerated alongside26 additions to keep one data format.

## Alternatives / consequences
Manual copies preserve readable bespoke layout but invite coordinate drift and duplicate edits. Runtime JavaScript or JSON loading adds an unnecessary runtime dependency. Generated GDScript retains the established Godot data interface; Node is build/test tooling only (already present for icon scripts), no install or native dependency. The prototype remains authoritative for gameplay; edit it and regenerate instead of hand-tuning generated levels. Sparse progression helpers remain valid with a complete consecutive40-level array. Real-input replays separately prove clearability; fidelity does not prove physics parity.
