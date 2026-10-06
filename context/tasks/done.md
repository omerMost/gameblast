# Done

Append-only log of completed backlog items. Newest at the top. Date format: `YYYY-MM-DD`.

When you complete a backlog item, move its bullet from `backlog.md` to here in the same turn — prepend the completion date and (optionally) a one-line note on what shipped.

---

- 2026-10-07 — Godot stage3 content complete on `codex/stage3-content`: remaining26 original levels imported, all40 clear through real-input bots within original ammo; source-fidelity exporter/check, 40-level progression/grid and freed-callback/weapon-switch regressions. Full check15 suites green. No gameplay tuning or installs; main awaits review of stage2 ancestry.

- 2026-10-07 — Godot stage2 overnight north star complete on run branch: all enemies/features and original introduction levels, fourteen available levels cleared within original ammo. Titans/dragons preserve source armor, weakpoints, movement, timing and sensor fire. Morning page/vault refreshed; main merge awaits user review.

- 2026-10-07 — Stage-2 step 5: jetpack hover/compound pack, lob grenades, fuse110/toss10, current-position warning ring and pack explosion14ticks after death. Original L25 clears in two rockets (par3); twelve available levels.

- 2026-10-07 — Stage-2 step 4: knights and original L20, frontal shield and rear/overhead bypass, sword delay/cooldown, run/jump/climb and physical dropped weapons. Eleven levels verified with real-input clearance. Content validator now rejects malformed opcodes/geometry/references; enemy missiles follow prototype balloon collision filtering.

- 2026-10-07 — Stage-2 integration checkpoint on the run branch: archers (L19), ropes/balloons/bridges/pads (L21–23), wells/curved preview (L24), 25 procedural sound effects and 112 BPM ducking music. Ten playable levels retain original ammo/par and pass real-input bot clearance. Godot check runner/content validation/bots complete; web checks remain queued.

- 2026-10-07 — Stage-2 step 2 on the run branch: FX/blood parity audit, ongoing ragdoll bleeding, clipped decals, proportional low-HP bar and headless FX regression coverage. Added level-data validator and `context/build-guide.md`.

- 2026-10-07 — Godot port stage 1 (core loop + levels 1–5) in `godot/`, Godot 4.7.2. Headless checks pass with no script errors: all 5 levels stay stable for 300 idle ticks; a sweep finds a winning shot within ammo for each (levels 1, 2, 4, 5 in one shot, level 3 in two = par); shooters fire on line of sight and are blocked by stone; every player death has a cause; no fall/crush damage without an explosion. Feel compared with the prototype over 256 shots: 229/256 match after the ADR 0006 retuning.
- 2026-10-07 — Installed Godot 4.7.2 (`brew install --cask godot`). The Android part of the toolchain is still open.
- 2026-10-06 — Prototype works offline (the CDN part of "Make the game work offline"). Matter.js 0.19.0 is vendored at `prototype/vendor/matter.min.js`, and Lilita One plus Nunito 800/900 (latin woff2) are in `prototype/fonts/` with local `@font-face` rules. Checked: no external requests, 40 levels × 60 steps with no errors, and level 1 still won by a grenade at a=-0.5, p=0.35. The storage, icons, orientation and keep-awake parts stay in the backlog.
- 2026-10-06 — Engine decided: Godot 4, Android first (ADR 0002).
- 2026-10-06 — Brought the prototype source into the repo as `prototype/index.html`, copied from the claude.ai artifact. Checked locally: 40 levels load, no console errors, and level 1 can be cleared with one grenade.
