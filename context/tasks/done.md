# Done

Append-only log of completed backlog items. Newest at the top. Date format: `YYYY-MM-DD`.

When you complete a backlog item, move its bullet from `backlog.md` to here in the same turn — prepend the completion date and (optionally) a one-line note on what shipped.

---

- 2026-10-06 — Prototype works offline (the CDN part of "Make the game work offline"). Matter.js 0.19.0 is vendored at `prototype/vendor/matter.min.js`, and Lilita One plus Nunito 800/900 (latin woff2) are in `prototype/fonts/` with local `@font-face` rules. Checked: no external requests, 40 levels × 60 steps with no errors, and level 1 still won by a grenade at a=-0.5, p=0.35. The storage, icons, orientation and keep-awake parts stay in the backlog.
- 2026-10-06 — Engine decided: Godot 4, Android first (ADR 0002).
- 2026-10-06 — Brought the prototype source into the repo as `prototype/index.html`, copied from the claude.ai artifact. Checked locally: 40 levels load, no console errors, and level 1 can be cleared with one grenade.
