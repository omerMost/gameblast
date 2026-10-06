# Backlog

Active, actionable work. One bullet = one chunk you could pick up and finish in a session. **Cross items off and move them to `done.md` with the date in the same turn you finish them** — the backlog must reflect current reality.

## Now

_(Mid-flight or top-priority. Usually 1–3 items.)_

- [ ] Install the Godot 4 toolchain: Godot 4 (stable), Android export templates, JDK 17, Android SDK. Record the exact versions in `tech-stack.md`
- [ ] Godot port stage 1 (core loop + levels 1–5), using the `godot-porter` agent (ADR 0002)
- [ ] Decide what to do with the old public artifact link friends use: republish it from `prototype/`, or replace it with a hosted build (for example on `site/` or itch.io)
- [ ] Run `npm install` in `mobile/` and get the Expo app running on a device/simulator
- [ ] Add dev/prod app identities: `noamcli pack add dev-prod-variant`
- [ ] Set up the site in `site/`
- [ ] Replace the placeholder icon mark in `scripts/generate-icons.js` when the brand exists, re-run it

## Next

_(Approved, ready to pick up, not started yet.)_

- [ ] Godot port stage 2 (all enemies and features), stage 3 (all 40 levels), stage 4 (Android `.apk` export)
- [ ] Decide what to do with the unused Expo scaffold in `mobile/` (delete it, or keep it for a companion app)
- [ ] App-readiness polish (rest of the old "work offline" item): use reliable storage instead of localStorage, add icons/splash, lock orientation, keep the screen awake
- [ ] Rewarded-ad hooks (+1 grenade, continue after death) and AdMob with test IDs; interstitial at most every 2–3 levels; no banners
- [ ] Privacy policy + `app-ads.txt` (can live on `site/`)
- [ ] Release on web portals (CrazyGames / Poki / itch.io) for feedback
- [ ] Google Play: $25 account, closed test with ~12 testers for 14 days, then public release
- [ ] App Store: $99/yr account, TestFlight, review
- [ ] Check that the "Blast Ranger" name isn't taken or trademarked

## Later / stretch

_(Parking lot. Ideas, nice-to-haves, things you'd do if everything else were done.)_

- [ ] Haptics on explosions
- [ ] Firebase Analytics (D1/D7 retention) before any paid advertising
- [ ] Short-video marketing clips (ragdolls, titan belly shots, dragon gulps)
