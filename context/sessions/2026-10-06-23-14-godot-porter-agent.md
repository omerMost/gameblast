# 2026-10-06 — Godot chosen for the native app; godot-porter agent

- The user asked for an agent to convert the game to Godot for Android. That settles the open engine question, so I wrote **ADR 0002 (Godot 4 + GDScript, Android first)**. It records Capacitor, Expo, Unity and Phaser as the rejected options, and marks the `mobile/` Expo scaffold as unused.
- `.claude/agents/godot-porter.md` covers the staged port (1 core + L1–5 → 2 features → 3 all 40 levels → 4 Android `.apk`). It includes a Matter.js → Godot mapping table and unit conversion (velocity ×60, gravity ≈1000 px/s²). Levels port as data replayed by a `LevelBuilder`, and a `Debug` autoload mirrors `window.__dbg` for headless checks. The agent must not install toolchains; it stops and reports what's missing.
- Updated: the orchestrator roster and pipeline, AGENTS.md layout (`godot/` planned), STATE, tech-stack, system-design, and backlog (toolchain install + stage 1 in Now, stages 2–4 + the `mobile/` decision in Next). The engine decision moved to done.
- Environment check: **no Godot, no JDK, no Android SDK** on this Mac (Homebrew is available). The port can't be verified until these are installed.

## Later: orchestrator and sidebar sessions

- Renamed this desktop session to "Root Orchestrator". The user wants the orchestrator to create sessions that show up in the sidebar.
- Limitation: this session has no `start_session` tool, so the orchestrator can't open sidebar sessions directly. Added a "Sessions vs. subagents" section to `root-orchestrator.md`: use `start_session` when it's available, otherwise a `spawn_task` chip that opens a new session in one click, and use `send_message` to coordinate existing sessions.
- Checked the app: Claude desktop 2.19675.1 is installed and **2.26454.0 is downloaded**. ShipIt had cancelled the install because the app was still running. I set up a detached restart (quit → wait for ShipIt → reopen) so the update can install. It's unknown whether the new version gives sessions `start_session`.
- Tested background sessions: `claude --bg "<prompt>"` ran as `@root-orchestrator` and answered correctly. `claude agents --json` and `claude logs/rm <id>` work. Added the background-session workflow to the orchestrator: `claude --bg --agent <specialist>`, monitored with `claude agents --json`. These sessions don't show in the desktop sidebar.
- After updating to 2.26454.0, this session still has no `start_session`. I tried driving the Claude app with computer-use to click "+": **blocked by design**, since Claude can never be granted control of its own app. The final routes for the orchestrator are background sessions (`claude --bg`, automatic) and `spawn_task` chips (sidebar, one click).
- The user chose **chips (`spawn_task`) as the default way to create sessions**, and `root-orchestrator.md` now says so. Background `claude --bg` sessions are only for when the user asks for no-click automation.
- First chip created: "Make the Blast Ranger prototype work offline" (task_283b6f92). It vendors Matter.js and fonts into `prototype/`, verifies all 40 levels, and updates the vault.
