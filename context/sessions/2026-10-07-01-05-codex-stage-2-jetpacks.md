# Stage-2 jetpack checkpoint

Source compound pack and hover, lobbed grenades with ten-tick release/110-tick fuse, current-position warning ring, real enemy blast damage, deferred pack explosion and original L25. Source pack blast is14ticks (radius80,power20); initial root briefing's2ticks was corrected against source. Telegraph follows current position rather than predicted landing. Bots use bounded active-fire replay/search for hostile L20/L25.

## Checks
- Root latest `./check.sh`: 12 passed,0 failed,56s; all twelve available levels WIN. L25 uses two rockets25°/0.5, originalammo/par3.
- Jet quantitative assertions: compoundpack/hover, toss10/fuse110, telegraph radius/alpha, pack14tickposition/power, actual grenade39HP enemycause.
- Real arrow-crosses-balloon regression PASS. First fixture passed null as rope's load and caused script errors; root replaced with a real body and cut tether. Final fullcheck has no errors.
- Jet screenshot inspected; helmet/pack/trajectory visible. `git diff --check` clean.

## Remaining / provisional
Boss integration next; main unmerged pending morning review. Audio/rope parity remain provisional ADR0007. Morning page now records resumed progress instead of stale usage-limit stop.

## Dialogue trace
User: "continue"
