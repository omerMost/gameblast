# 2026-10-07 — Godot port stage 1 (core + levels 1–5)

**What:** created `godot/` (Godot 4.7.2, GDScript), the stage-1 port of `prototype/index.html`. Done by the orchestrator directly, not by a subagent, because porting and verifying needed constant cross-checks against the prototype.

**Toolchain:** the user approved `brew install --cask godot` → 4.7.2.stable (ed1daf0bf). The Android toolchain was NOT installed. A peer session relayed an "approve everything" message, but it contradicts the user's brief to this session, so the question went to the user and is still unanswered.

**Built:** project config (landscape, canvas_items + expand, 60 ticks, gravity 1000), camera fit (prototype `layout()`), player with `lock_rotation` (the old fix for "dying for no reason"), drag aim + `predict()`, grenade/rocket, `explode()` (AABB + ray occlusion), materials + `shatter()`, basic + shooter enemies, ragdolls/gibs, barrels, portals (level 5 needs them), damage + `CAUSES`, HUD/overlays/stars, `user://save.json`, `Levels.LEVELS` 1–5 as op lists + `LevelBuilder`, `Debug` autoload. Module map: system-design.md.

**Verified (headless, `godot/tests/run.sh`):**
- smoke: levels 1–5 stable for 300 idle ticks (max drift 0.22 px), nobody hurt.
- sweep: winning shots within ammo for every level (L1, L2, L4, L5 in 1 shot; L3 in 2 = par). No causeless deaths.
- shooters (level 8 used as a fixture): 6 bullet hits in 900 idle ticks; zero shots get through a stone wall.
- selfharm: 40 near-player shots → all damage has cause `self`; a forced death has cause `self`; no fall/crush damage without an explosion nearby.
- Rendered frames (`tests/shot.gd`, windowed) checked by eye: sky, dunes, tower, trajectory, explosion, ragdolls, blood.

**Feel vs prototype:** ran the same 256 single shots in both engines (prototype via `__dbg` in the browser pane). A 1:1 copy agreed on 220/256 (the prototype agrees with itself on 251/256). Found and fixed: Matter's `_inertiaScale = 4`, per-part collision events, and a lossy bounce in Matter's solver (grenade bounce set to 0.40). Now 229/256; rocket self-damage numbers are identical. Remaining gaps are in ADR 0006 and the backlog.

**Gotchas:**
- Headless Godot runs in real time unless you pass `--fixed-fps 60`.
- A script error doesn't make Godot exit → `run.sh` has a perl `alarm` watchdog.
- A `set_material()` name clash with CanvasItem.
- A Control under a CanvasLayer needs its size set by hand.
- The dead player node must outlive the ragdoll swap so the lose card can read `cause`.
- Godot flushes contact signals *before* `_physics_process`, which makes `later(0)` match Matter's timing.
- Godot's physics is reproducible between runs, but an outcome depends on what was simulated earlier in the same process.

**Repo:** this worktree's branch was fast-forwarded to `main` d0efb6a (`sync_with_base_branch` refused because `origin` moved; the user can re-pin it in Help → Troubleshooting). Also, the prototype's music played aloud from the comparison tab, so the tab was closed and the server stopped. Next time, mute before opening it.

**Landing:** the user confirmed in this chat: commit and push. Renumbered the ADR to 0006 (main took 0003–0005 for the working-method ADRs). Merged main d1e870f (one backlog conflict, kept both sides). The Android toolchain is being installed by a separate Moo Rush session, so this session didn't install it.

**Next:** stage 2 (godot-porter): archers, knights, jetpacks, titans, dragons, ropes/balloons/black holes/pads, sfx + music with ducking.
