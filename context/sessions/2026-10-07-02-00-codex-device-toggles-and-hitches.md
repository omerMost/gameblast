# Android settings and explosion hitches

## Changes
- Music/blood title settings now use fixed56px toggle buttons, stable labels/bounds and explicit on/off/hover styling. Native toggle state drives preferences; no moving flat-text targets.
- Clipped decals retain ArrayMesh geometry, triangulated once per ellipse/cache key instead of by each repeated colored-polygon draw (provisional ADR0011). Blood colors, platform clipping, drawing order and260-mark budget remain.
- Android prewarms existing SFX during startup instead of generating the first explosion PCM during impact handling. Physics/ammo/flight lifetimes are unchanged.
- Debug performance samples now use monotonic wall time (win slow-motion previously inflated some FPS samples), report level/state/draw CPU, and reset after long background gaps.
- Root implemented; `rocket_diagnosis` supplied read-only diagnostics. Same branch `codex/stage4-android`; main/overnight ancestry remain unmerged pending review.

## Device evidence
- Before: phone logs38.8–43.6FPS with260decals, including a zero-particle sample. No script/runtime exception.
- New build: real taps switched both settings off and on; save values matched and screenshots retained fixed layout. Original preferences restored.
- Real rocket firing on level3 completed at60FPS. Grenade/rocket sequence and subsequent play cleared levels3–4; level3 sample had101decals/46particles at60FPS, level4 after-win samples had260decals at60FPS with draw submission around3.7–5.2ms. This is not an identical before/after scene benchmark or proof across all hardware.
- Final APK installed and opened; progress preserved through level4 (unlocked5, stars0=3/1=2/2=2/3=2). Corrected wall-time logs show60FPS at idle. Phone evidence `/tmp/blast-feedback-title.png`, `/tmp/blast-feedback-toggles-off.png`, `/tmp/blast-feedback-rocket.png`, `/tmp/blast-feedback-crowded.png`, `/tmp/blast-feedback-new-device.log`.
- No permanent rocket stall reproduced. Read-only desktop scan fired on all33levels with rocket ammo and found no contact exceptions; direct shots removed by166ticks. Upward rockets can stay offscreen451ticks while blocking firing, matching the prototype. Cold boom synthesis measured10.8ms on Mac; busy initial clipping8.7ms in one scene. Precise missile-stuck report remains a follow-up; user has not answered the level/whole-game-vs-projectile clarification.

## Checks
- `./check.sh`: **15 passed,0 failed in267s**, bot40/40 original ammo in208s.
- Final targeted `./check.sh audio fx progression`:3passed,0failed in3s after wall-clock instrumentation. Tests cover stable music toggle bounds, actual native toggle transitions, mesh triangle/clipping/empty-geometry behavior, FX and picker selection.
- Export/import and incremental device install pass; final device runtime logs contain no errors. `git diff --check` passes. Known ObjectDB/audio shutdown warning remains separately tracked.
- Test migrations initially still emitted `pressed` for the old blood button, then used native toggle state; a duplicate test variable was corrected. Final suite is green. Only own failed diagnostic process tree was stopped; no unrelated sessions changed.

## Dialogue trace
User: "the music on off and blood on off is not working nicely its blinking and hard to use"; "when use the missile it gliches and stuck".

No answer yet to: whether the whole game freezes or only the missile stops, and which level. Rendering/audio changes are implemented and device-tested; broader smoothness confirmation stays in backlog.
