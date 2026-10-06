# Done

Append-only log of completed backlog items. Newest at the top. Date format: `YYYY-MM-DD`.

When you complete a backlog item, move its bullet from `backlog.md` to here in the same turn — prepend the completion date and (optionally) a one-line note on what shipped.

---

- 2026-10-07 — Stage-2 step 2 on the run branch: FX/blood parity audit, ongoing ragdoll bleeding, clipped decals, proportional low-HP bar and headless FX regression coverage. Added level-data validator and `context/build-guide.md`.

- 2026-10-07 — Godot port stage 1 (core loop + levels 1–5) in `godot/`, Godot 4.7.2. Headless checks pass with no script errors: all 5 levels stay stable for 300 idle ticks; a sweep finds a winning shot within ammo for each (levels 1, 2, 4, 5 in one shot, level 3 in two = par); shooters fire on line of sight and are blocked by stone; every player death has a cause; no fall/crush damage without an explosion. Feel compared with the prototype over 256 shots: 229/256 match after the ADR 0006 retuning.
- 2026-10-07 — Installed Godot 4.7.2 (`brew install --cask godot`). The Android part of the toolchain is still open.
- 2026-10-06 — Prototype works offline (the CDN part of "Make the game work offline"). Matter.js 0.19.0 is vendored at `prototype/vendor/matter.min.js`, and Lilita One plus Nunito 800/900 (latin woff2) are in `prototype/fonts/` with local `@font-face` rules. Checked: no external requests, 40 levels × 60 steps with no errors, and level 1 still won by a grenade at a=-0.5, p=0.35. The storage, icons, orientation and keep-awake parts stay in the backlog.
- 2026-10-06 — Engine decided: Godot 4, Android first (ADR 0002).
- 2026-10-06 — Brought the prototype source into the repo as `prototype/index.html`, copied from the claude.ai artifact. Checked locally: 40 levels load, no console errors, and level 1 can be cleared with one grenade.
