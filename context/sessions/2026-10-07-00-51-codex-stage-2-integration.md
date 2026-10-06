# Codex stage-2 integration checkpoint

Integrated isolated specialists' archers, world mechanics and audio into the existing overnight branch. Added prototype-indexed levels 19 and 21–24, sparse progression, a real-input replay bot, new-class import refresh and general engine-error rejection. Root reviewed the merged code, updated all architecture/vault records, and wrote provisional ADR 0007 for distance constraints and sparse content.

## Checks
- `./check.sh`: **10 passed, 0 failed in 38s** (smoke, validate, shooters, selfharm, death, FX, bot, world mechanics, audio, archer).
- Bot: all 10 available levels WIN within original ammo; L3 and L19 in two shots, L21/L22 one shot, L23/L24 two shots. No direct kills or added ammo.
- Selfharm: 80 test shots, 100 damage events, 10 deaths; all causes present; no unexplained fall/crush damage. World suite: 18 assertions. Audio suite covers 25 PCM effects, score/envelopes/toggles and real game signals.
- Rendered/inspected L22 raft/balloons/ropes and L2 aiming/blast; screenshot audio driver Dummy. `git diff --check` and shell syntax check clean.

## Findings and fixes
- An unconditional zero well-acceleration velocity assignment interfered with buffered impulses; now only nonzero acceleration writes velocity.
- Blood toggle moved into an audio/blood row; FX test now finds the actual button recursively.
- Degenerate clipping polygons caused engine triangulation errors; drawing skips them and caches immutable decal shapes.
- Bots must preserve shot cadence: L1–5 wait for scenery, hostile levels fire as soon as projectiles clear. L3 rocket power0.6 replaces fragile0.5; bounded search discovers alternatives when chaos changes a replay. Headless bots skip repeated canvas redraws; screenshot scenes opt in.
- Earlier exploratory checks were stopped or failed on incomplete integration; final full check above passed. Several combined features share one integration checkpoint to retain a bootable tree; grouping is provisional.

## Provisional / remaining
Distance-solver feel and pad corners need future Matter comparison (ADR 0007). Audio uses mono22.05kHz PCM/frame scheduling/approximate filters and discrete echo; not speaker-auditioned. Some stress suites still print ObjectDB shutdown warnings despite mixer teardown; diagnostic follow-up underway. Knights, jetpacks, titan and dragon remain.

## Dialogue trace
User: "go over this project seesions you are under the claude root arc you are codex ai and i want you to continue the work of the session overnight run"
