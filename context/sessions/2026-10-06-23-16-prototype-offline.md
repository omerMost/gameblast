# 2026-10-06 — Prototype works offline (vendored Matter.js + fonts)

- Downloaded Matter.js **0.19.0** from cdnjs to `prototype/vendor/matter.min.js` (80,807 bytes, header says 0.19.0).
- Got the Google Fonts CSS2 response (Chrome UA) and took the **latin** woff2 files: `prototype/fonts/lilita-one-latin.woff2` (lilitaone v17) and `prototype/fonts/nunito-latin-var.woff2` (nunito v32). Google serves Nunito as a variable font, so 800 and 900 come from the **same file**. One `@font-face` uses `font-weight:800 900`.
- `index.html`: removed the preconnect and the Google Fonts `<link>`. The `<script>` now points at `vendor/matter.min.js`. Two `@font-face` rules (font-display:swap) sit at the top of the `<style>`. The existing fallback font stacks are unchanged, and nothing else in the game changed.
- `prototype/README.md`: replaced the "Needs internet" line with the vendored versions and source URLs.
- Verified in the browser pane (python http.server :8080):
  - Network shows only 4 requests, all to localhost: the page, matter.min.js and the 2 woff2 files.
  - `document.fonts` shows Lilita One 400 and Nunito 800–900 loaded, and the title screen renders in Lilita One.
  - `__dbg.levels.length === 40`. Running `startLevel(i)` and 60 `step()` calls for all 40 levels gave no errors, with console errors trapped and the console checked.
  - Level 1 grenade sweep: a=-0.5, p=0.35 still **won**, and 14 aim/power combos won in total.
- Worktree quirk: this session ran in a worktree that only has the scaffold commit. The prototype and vault are uncommitted in the main checkout, so all edits went to `/Users/omer/prod/blast/gameblast` directly. The preview needed a throwaway `.claude/launch.json` in the worktree, pointing at the main checkout's `prototype/`.
- Vault: STATE (stack + known gaps), tech-stack, data-flow (failure path + trust boundary), backlog (the leftover storage/icons/orientation/keep-awake work is its own line), done.
- Not checked: opening `index.html` over `file://`. Some browsers block `@font-face` there, but text would just fall back to the system stacks. Serving over http works.
