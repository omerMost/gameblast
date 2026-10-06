# ADR 0002 — Godot 4 for the native app (Android first)

**Status:** Accepted
**Date:** 2026-10-06
**Supersedes:** _(none)_. This settles the open "engine decision" backlog item, and it means the noamcli Expo scaffold in `mobile/` won't be used for the game.

## Context

The game exists as a single-file HTML5 + Matter.js prototype (`prototype/index.html`, 40 levels). We need a native Android app (iOS later). The options were discussed in the pre-repo chat (`sessions/2026-10-04-14-35-shipping-research.md`). noamcli scaffolded an Expo app, but nothing has been built on it.

## Decision

Port the game to **Godot 4 with GDScript** in `godot/`, and export to Android. The prototype stays as the gameplay **spec** until the port reaches parity. The port is done in stages by the `godot-porter` agent.

## Alternatives considered

- **Keep the HTML game + Capacitor.** Fastest to ship and no rewrite, but Matter.js has performance and tunneling limits, there's no visual level editor, and it ships as a web view inside an app. This was the chat's "ship fast" option, and the user chose to go native instead.
- **Expo / React Native (the `mobile/` scaffold).** There's no good 2D rigid-body physics and rendering setup for a game like this. It would mean a rewrite with worse tools than a game engine.
- **Unity (C#).** Strong for monetized mobile games, and the user knows C#. But it's heavier, has licensing risk, and is overkill for a 2D physics game. Godot is free and open, its 2D is excellent, and it can still use C# later if needed.
- **Phaser + Capacitor.** A cleaner web structure, but it still ships as a web view.

## Consequences

- Gets easier: performance, CCD for fast rockets, a visual level editor, shaders and particles, native offline builds, and plugins for ads, purchases and achievements (AdMob for Godot).
- Gets harder: the game logic has to be rewritten (~2k lines), the physics needs retuning to match the prototype's feel, and toolchain setup is needed (Godot 4, export templates, JDK 17, Android SDK). iOS will need Xcode.
- `mobile/` (Expo) is no longer the app. Removing it or reusing it is a separate follow-up.
- A new ADR would be needed to switch engines again (for example, to Unity for monetization).
