# Run 2026-10-07 — Godot stage 2 (all enemies and features)

**Branch:** `run/godot-stage-2` (from main f1cf7f5). **Not merged** until the user reviews `context/morning-page-2026-10-07.md` (ADR 0005).

## North star (user: "start the overnight run for stage 2")
By morning, every stage-2 enemy and feature from the web prototype (`prototype/index.html`, the spec) works in `godot/`. Each is proven by a committed headless test, and the prototype levels that introduce each feature are ported and cleared by the sweep bot.

## Checklist (one verified commit each; `./check.sh` green after every step)
0. Run file (this), then `check.sh` at the repo root (runs `godot/tests/suites.txt`; fails on exit≠0, script error, TIMEOUT, or no `RESULT: PASS`).
1. Player damage and death causes, and the death screen with cause + tip.
2. **Done:** FX and the blood toggle, including ragdoll bleeding, ground-clipped decals and low-HP fill.
3. **Done:** Archers (arcing arrows that stick). Level 19 "Archers".
4. **Done:** Knights (run, jump, climb, frontal shield blocks blasts, drop real weapons). Level 20 "Knights".
5. Jetpack troopers (thrown grenades with a landing telegraph, the pack explodes). Level 25 "Jetpacks".
6. **Done:** Ropes, balloons, bouncy pads. Levels 21 "Hanging stone", 22 "Sky raft", 23 "Bounce house".
7. **Done:** Black holes (bend shots, the preview curves). Level 24 "Black hole".
8. Titans (belly-only weak spot, ARMOR / CORE HIT!, stomp shake, ledge jumps, fist smash). Level 31 "Titan".
9. Dragons (fly, roar, mouth glow, real fire, grenade-in-mouth only, SCALES / GULP). Level 33 "Dragon".
10. **Done:** Music with ducking on explosions, plus the music toggle.
11. Morning page, STATE, backlog/done, architecture, session note, push.

## Night rules
- No merge into main. No installs (the Android toolchain belongs to the Moo Rush session). Nothing outward-facing except pushing this branch.
- Don't touch `prototype/`, `.claude/agents/`, or other sessions' work.
- Feel, difficulty, or behaviour not in the prototype → **provisional**, listed on the morning page.
- A step that can't go green in reasonable time gets reverted and recorded, and the run moves on.
- Stop early and leave the morning page rather than hitting the usage limit.

## Provisional calls made at kick-off
- **P1 Level numbering:** `Levels.LEVELS` stays indexed by prototype number. Levels that aren't ported yet are `null` placeholders (stage 3 fills them in), and the level select and the sweep skip them. That way level 19 is still "Archers".

## Codex continuation
Resumed the existing worktree/branch after reviewing its usage-limit session and morning page. Added a build guide and level-data validation; independent world/audio work uses isolated worktrees. No merge authorization is inferred from resuming.

Integration checkpoint groups independently ported steps 3, 6, 7 and 10 in one bootable verified tree because they share Game/View/lifecycle hooks; later enemy steps retain separate checkpoints. This grouping is provisional for morning review.
