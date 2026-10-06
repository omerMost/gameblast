# Stage-2 knights checkpoint

Ported original L20 and knight compound shield, frontal blast protection, run/jump/climb, delayed sword damage and physical weapon drops. Root reviewed code and rendered the real grenade blast. Strengthened level validator (opcodes/arity, finite positive geometry, material and named-body references). Corrected enemy missile/balloon collision filters to executable prototype source.

## Checks
- Stable latest `./check.sh`: 11 passed, 0 failed, 48s. Bot clears all eleven available levels within original ammo; L20 two grenades, 5°/0.9 then 25°/0.7.
- Knight suite covers compound inertia, frontal/rear/overhead blasts, real drops, running/jumping/climbing, sword20HP/delay9/cooldown55 and real-input clearance.
- Visual L20 blast inspected; shield/sword physical drops visible. `git diff --check` clean.
- Earlier full check failed only an audio cleanup trial already reverted; final check above uses stable code. Audio diagnostic found playback/WAV resources only and zero orphaned Nodes. Explicit stop trials worsened warnings; no trial retained.

## Remaining / provisional
Jetpack, titan and dragon integration remain. Rope/audio feel remains provisional under ADR0007; no speaker audition. Main stays unchanged until morning review.

## Dialogue trace
User: "continue"
