# Stage3 content complete

Continued from verified stage2 b6c62d8 in attached worktree `/Users/omer/.codex/worktrees/stage3-content/gameblast`, branch `codex/stage3-content`. All40 prototype declarations are now native level data, including26 remaining levels. Recording-builder exporter expands loops/references and preserves original numbers, geometry, metadata, ammo and par; check.sh rejects source drift. Three isolated specialists supplied early/mixed/monster real-input fixtures; root reviewed/integrated them into the unified bot. Main and stage2 run remain unchanged pending ancestry review.

Searches exposed two bugs: typed delayed arrow callback could receive a freed enemy before entering its own guard; common weak-reference scheduler skips removed targets before invocation. Active test input previously polled readiness before selecting a new weapon, causing600ticks of idle on an exhausted old weapon; selection now precedes polling. No gameplay tuning or installs. Provisional ADRs0008–0009 record source generation/lifecycle choices.

## Checks
- Root full `./check.sh`: **15 passed,0 failed,279s**. Bot clears **40/40** within original ammo with live player; includes real-input bounded alternatives where physics history changes a replay. Some levels exceed par; no added ammo or direct kills.
- Source fidelity PASS40levels; validator40levels/1143assertions. Idle300: all source enemies survive, player alive, finite transforms, bounded mobile motion and explicit source-alerted injuries. Transient missiles excluded from scenery motion.
- Selfharm:320shots,665damageevents,58deaths, all causes named. FX/archer/knight/jet/boss/world/audio suites green.
- Lifecycle proves a removed/freed drawing archer never releases its pending arrow and an exhausted weapon switches promptly. Progression verifies all40 consecutive unlocks/last-level behavior; tests disable persistence.
- L18 stored second grenade0.4 replaced0.5 after specialist search; root final targeted bot replay also PASS (fallback75°/0.8 then35°/0.6, two grenades,HP100). One mistaken check.sh level-argument invocation was canceled; correct diagnostic uses tests/run.sh bot900 -- --level=18. Full-check terminal summary above is the complete run; ignored bot log was overwritten by that canceled invocation.
- Root inspected40-level grid at1280×720 (692px card fits), Monster mash aim and fully visible300tick post-shot render. Initial screenshot waits were stopped/timed out under window occlusion; specialist isolated frame_post_draw wait and visible --always-on-top run finished cleanly in7.1s, no production issue. Evidence `/tmp/stage3-render-foreground.log` and rendered aim/blast PNGs.
- `git diff --check`, shell syntax and source check clean. Initial WeakRef inference warning fixed with explicit annotation; initial lifecycle fixture next0 reinitialized its timer, corrected to-1 to exercise the actual pending callback.

## Provisional / next
Physics-history fallback remains ADR0006. Rope/audio feel and playback-resource exit warnings remain stage2 gaps; human playtest/audio audition still pending. Source-generator and weak scheduling choices are provisional ADRs0008–0009. Stage4 Android export is next; no toolchain install or main merge is part of this turn. Branch builds on unreviewed stage2 ancestry.

## Dialogue trace
User: "Start **stage 3: port the remaining 26 levels**, with bots proving each is"
User: "continue"
