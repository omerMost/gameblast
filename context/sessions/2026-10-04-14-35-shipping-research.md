# 2026-10-04 — Shipping research: native apps, engine choice, ads, publishing

> **Imported** from the claude.ai chat (see `2026-10-02-22-31-prototype-v1-to-v3.md`). Planning only — no code changed. **No decision was taken in the chat**; the open questions are in `tasks/backlog.md`.

## Native app path (recommended in chat)

- Wrap the existing HTML game with **Capacitor** (no rewrite). Needs: Play account $25 once, Apple $99/yr, Mac + Xcode (or Codemagic), Android Studio.
- Required game changes: bundle Matter.js + fonts locally (offline; Apple may reject otherwise), Capacitor Preferences instead of localStorage, icons/splash, orientation lock + keep-awake, optional Haptics.
- Store needs: privacy policy, age rating (~12+–16+ due to blood; blood toggle helps), screenshots, name/trademark check on "Blast Ranger".
- Cheapest: PWA (no store, poor discovery).

## Engine options discussed

| Option | Verdict in chat |
|---|---|
| Keep + Capacitor (JS) | Fastest ship, works today |
| Phaser + Capacitor | Cleaner web structure, medium effort |
| Godot 4 (GDScript/C#) | Free, great 2D; rewrite (~2k lines of logic), physics retune; gains perf, CCD, visual level editor, shaders, native export, store plugins; loses instant web link |
| Unity (C#) | Best for monetized mobile; user knows C#; check license terms |

Chat's plan: ship current game via Capacitor now → if traction, rebuild in Unity (or Godot). Offered staged Godot port (core + L1–5 → rest of enemies → all 40).

## Ads / publishing / growth

- **AdMob** first (later LevelPlay/AppLovin MAX mediation). Rewarded video (+1 grenade, continue, skip level); interstitial ≤ every 2–3 levels; **no banners** (cover aim area). Test ad IDs in dev. Needs privacy policy, `app-ads.txt` on a site, EU consent (UMP), iOS ATT.
- Publish order: web portals (CrazyGames, Poki, itch.io) → rewarded ads → Play closed test (~12 testers × 14 days for new personal accounts) → Play public → App Store (TestFlight → review).
- Growth: short videos (TikTok/Reels/Shorts — ragdolls, titan belly shots, dragon gulps), Reddit (r/WebGames, r/playmygame, r/IndieGaming), Israeli gamedev groups; review prompt after a win; Firebase analytics for D1/D7 retention before paid UA.
