# Backlog

Active, actionable work. One bullet = one chunk you could pick up and finish in a session. **Cross items off and move them to `done.md` with the date in the same turn you finish them** — the backlog must reflect current reality.

## Now

_(Mid-flight or top-priority. Usually 1–3 items.)_

- [ ] Android toolchain for stage 4: a separate session in the Moo Rush project is installing it machine-wide (Android cmdline-tools in; JDK 17 not yet as of 2026-10-07). Still needed for Blast Ranger: check it covers the Godot 4.7.2 export templates, NDK, debug keystore and editor SDK/JDK paths, then record the versions in `tech-stack.md`. Godot 4.7.2 itself is installed
- [ ] Decide what to do with the old public artifact link friends use: republish it from `prototype/`, or replace it with a hosted build (for example on `site/` or itch.io)
- [ ] Run `npm install` in `mobile/` and get the Expo app running on a device/simulator
- [ ] Add dev/prod app identities: `noamcli pack add dev-prod-variant`
- [ ] Set up the site in `site/`
- [ ] Replace the placeholder icon mark in `scripts/generate-icons.js` when the brand exists, re-run it

## Next

- [ ] Investigate ObjectDB shutdown warnings in combined headless audio stress suites; dedicated audio suite shuts down cleanly; diagnostic found only polyphonic/WAV playback resources and zero orphaned nodes. Explicit voice-stop trials worsened shutdown and were reverted.

_(Approved, ready to pick up, not started yet.)_

- [ ] Review `context/morning-page-2026-10-07.md` and authorize merging completed stage2 from `run/godot-stage-2`; main still stage1.
- [ ] Audition procedural PCM music/SFX through speakers and compare rope/hover/armor feel with Matter; automated verification is complete, perceptual parity provisional.

- [ ] Extend `check.sh` to the web prototype through `window.__dbg`; Godot registered suites, content validator and real-input bot are implemented.
- [ ] Godot port stage 3 (all 40 levels), stage 4 (Android `.apk` export)
- [ ] Godot port feel gaps (ADR 0006): debris kills enemies less often than in the prototype (level 2 flat rocket), and grenade corner bounces and spin grip differ. Re-run `godot/tests/grid.gd` against the prototype after each tuning pass
- [ ] Godot port polish: the 30-tick settle at level start is visible (input locked for 0.5 s); hide it behind a level-name banner
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
