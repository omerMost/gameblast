# Stage4 Android export and device feedback

## Result
- Built/pushed on `codex/stage4-android`, from stage3 ancestry. Main stays stage1 pending stage2 morning-page review.
- Existing toolchain verified: Godot4.7.2 templates, OpenJDK17.0.20.1, Android platform36/build-tools36.1.0, editor SDK/JDK paths and local debug key. No installations. Standard prebuilt APK export needs no NDK/Gradle.
- Signed ARM64 debug APK, package `com.omerevan.blastranger`,0.1.0/code1, minSDK24/targetSDK36, no permissions, test assets excluded. Landscape, immersive mode, keep-awake and existing launcher assets configured. Reproducible `scripts/export-android.sh`; output ignored at `godot/build/blast-ranger-debug.apk` (28,435,396bytes, SHA256 `ea983904589e628ff87472d9e1dc4b663567c469fdac5ab10d7b6b26748e95c4`). No key/credentials in Git.
- Installed on authorized connected model2412DPC0AG/Android16, OpenGL ES3.2/Mali-G720. Real touch drag/release played level1; save recorded3stars/unlocked2. User continued level2; later save recorded2stars/unlocked3. Updating APK preserved both records.
- User clarified missing picker pictures and brief busy-scene glitch. Added native grenade/rocket SVG pictures. Cached decal validity at first clipping, reused weapon styles, capped Android rendering60FPS with debug-only frame/effect logging. Root implemented; `android_perf_review` gave read-only hotspot review. These implementation choices are provisional (ADR0010); no physics/ammo/FX-budget changes.
- Device screenshot confirms grenade icon. Idle samples60FPS/16.7ms worst interval, with occasional startup/interruption spikes; no claim of crowded-scene performance parity. Follow-up remains in backlog. Intentional win slow-motion remains.

## Checks
- Final `./check.sh`: **15 passed,0 failed in262s**; bot40/40 with originalammo in200s. Updated FX cache geometry and progression picker-icon/switch/style regressions pass.
- Export/import, debug signing verification, APK manifest/assets inspection, `adb install -r`, launcher start, app-private save inspection and update persistence pass. KEEP_SCREEN_ON observed in device window flags. Script syntax and `git diff --check` pass.
- Device logs: no app script/runtime errors after update. `BR_PERF` now supports future crowded-scene diagnosis. `/tmp/blast-stage4-updated.png`, `/tmp/blast-stage4-updated-device.log`, `/tmp/blast-stage4-final-check.log` are local evidence.
- Initial export required ETC2/ASTC imports; configured. Initial picker icon-width assignment failed headless validation; corrected to a theme constant before installing updated build, then full suite rerun. Earlier incomplete checks were stopped only by their own PID trees. Existing audio/ObjectDB shutdown warning remains tracked, no new orphaned-node finding.

## Dialogue trace
- User: "ok continue to step 4 i have my device connected"
- User: "the game somtimes glitch when a lot is happens on the screen also the rocket and granede items pick  is not drewing over the screen"
- Clarifications: "The buttons show text but no weapon pictures"; "brief".
- A post-update confirmation question is pending; no level or perceptual confirmation received. Release identity/signing and broader device coverage remain follow-ups.
