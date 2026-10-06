# Blast Ranger: web prototype

A playable single-file HTML5 game built with Matter.js physics. It has 40 levels.

- **Source of truth:** this file was copied from the public claude.ai artifact https://claude.ai/artifact/UbwwHgS9yqQbwwpup9xNoE on 2026-10-06. From now on, edit it here.
- **Run it:** open `index.html` in a browser, or serve this folder (`python3 -m http.server 8080 -d prototype`).
- **Works offline:** all dependencies are vendored next to `index.html`.
  - `vendor/matter.min.js`: Matter.js **0.19.0** (MIT), from https://cdnjs.cloudflare.com/ajax/libs/matter-js/0.19.0/matter.min.js
  - `fonts/lilita-one-latin.woff2`: Lilita One 400, latin subset, and `fonts/nunito-latin-var.woff2`: Nunito variable font covering 800 and 900, latin subset (both SIL OFL). Downloaded from Google Fonts (`fonts.gstatic.com`, lilitaone v17 / nunito v32) on 2026-10-06. The `@font-face` rules are at the top of the `<style>` block.
- **Test hook:** the bottom of the script exposes `window.__dbg` (`build`, `step`, `fire`, `startLevel`, `setAim`, `predict`, …) that was used for headless auto-play testing.
- History: `context/sessions/2026-10-02-22-31-*`, `2026-10-03-22-00-*`, `2026-10-04-14-35-*`.
