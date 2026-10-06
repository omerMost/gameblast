# ADR0010 — Android debug export from prebuilt templates

**Status:** Provisional (AI implementation within the user's authorized stage4).
**Date:** 2026-10-07

## Decision
Use Godot4.7.2's standard prebuilt APK templates with ARM64 and package `com.omerevan.blastranger`, version0.1.0/code1. Export a signed debug APK into ignored `godot/build/`, reusing local editor SDK/JDK/debug-key settings. Sensor-landscape, immersive mode, keep-awake and existing launcher artwork are configured. No Internet permission or test resources. Cap Android rendering at60FPS to match physics and avoid redundant canvas drawing on high-refresh phones. Debug-only frame/effect logging supports device diagnosis.

## Alternatives
Gradle/custom Android builds are reasonable for later ad/native plugins, but add dependencies without helping the current offline game. Both ARMv7 and ARM64 would cover more devices; ARM64 keeps the debug artifact small and matches the connected device. Rendering at the display refresh rate produces more canvas work than physics updates on120Hz phones.

## Consequences
Stage4 needs no SDK/JDK/template installation and no NDK. The package/version are provisional development identity, not a store release decision. Release signing and broader device coverage remain follow-ups. Rendering limits do not alter physics ticks, weapon behavior or particle counts.
