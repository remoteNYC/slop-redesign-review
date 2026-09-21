# Clockwork Relay audit and final route

## Audit

The previous repository contained two disconnected designs: a two-level
platformer whose second level was a prescribed lock-on target chain, and a
gray-box rail prototype with a stronger systemic premise but hidden velocity
numbers, long reset state, and an exit that did not actually require the
advertised return. A later relay build made the far shutter the only way to
deploy the exit, even though its notes promised that a carriage reversal by the
opposing ram or rail stop would work. The current route makes the reversal
itself the rule and removes that extra shutter.

The redesign classified the major work as follows:

| Decision | Systems |
| --- | --- |
| Keep | responsive acceleration, coyote time, jump buffering, fixed rebound, quick retry, clockwork presentation, persistent ram/carriage impacts |
| Keep but simplify | kinetic transfer bands, camera, recovery islands, checkpoint state |
| Redesign | lock-on dash into a free directional kinetic dash; debug rail into one continuous learning arc; return into a mechanically required exit deployment; carriage clash into a catchable vault |
| Reuse selectively | the old aimed-dash target cue as free-dash feedback; Wind Effigy's optional upper route as a carriage-rebound flank above the opposing ram |
| Remove | health attrition, cosmetic enemy variants, relay target chains, isolated crushers, level select, numeric diagnostics, far shutter |

The target dash was removed because it reduced play to target 1 → target 2 →
target 3. The free dash now composes with ordinary movement, rams, the carriage,
landing, and rebound refreshes.

## Shared rules

- A ram telegraphs and commits to a direction at the start of windup, then
  keeps its charge momentum. The player can bait the charge.
- A downward strike gives a fixed vertical rebound and transfers the player's
  horizontal motion.
- A directional dash transfers stronger motion. A confirmed clash separates
  the player safely.
- Rams open kinetic receivers and collide with the carriage instead of being
  consumed.
- The carriage carries the player, accepts weaker direct corrections, rebounds
  at rail stops, and contributes its motion to a player's rebound. A dash into
  it sends the player up and along its motion for a deliberate catch.
- Returning an advanced carriage deploys the exit. The opposing ram, far rail
  stop, or a strong player correction can create that return.
- The carriage rebound can reach an optional one-way upper deck. Crossing above
  the opposing ram and dropping behind it lets the player bait its charge and
  dash it back into the carriage; the lower landing gives room to recover.

## Successful player sequence

The full route check uses only player inputs and completes this sequence:

1. Run to the gold pad, jump, strike down, and use the fixed rebound to clear the
   first ledge.
2. Run-jump and dash across the upper gap. A miss falls beside a second pad and
   can be recovered.
3. Drop toward the first ram and dash into it from the left. The ram opens the
   shutter, continues into the carriage, and rebounds back as a readable second
   danger.
4. Catch the carriage. After a missed catch or death, the checkpoint restores a
   stationary carriage on the work island; a grounded dash relaunches it and
   vaults the player toward a catch. Moving strikes offer smaller corrections.
5. Ride toward the opposing ram. Leaving the ram dangerous makes it reverse the
   carriage quickly. Redirecting it lets the far stop create the same useful
   return. Its committed windup also lets the player bait the charge timing.
6. When the gantry unfolds, jump from the left-moving carriage, strike it, and
   let the inherited leftward motion carry the rebound into the bell.

The input-only route now completes through a missed catch, checkpoint recovery,
and a ram-caused return. Its automated completion proves physical feasibility,
not the first-player learning time or fun. The intended first-play sequence is
roughly three to five minutes of observation and retries; that needs a human
playtest.

## Failure information

- Missing the upper gap reveals the recovery pad rather than causing death.
- Letting the first ram return after opening the shutter can kill the player,
  but the opened-shutter checkpoint makes the cause immediately replayable.
- Missing the carriage lands on a work island whenever the player still has a
  recoverable trajectory.
- The opposing ram's red windup locks to a direction, so crossing behind it
  produces a predictable miss instead of a last-frame turn.
- The free dash shows a short directional guide and marks a kinetic target only
  when it lies in the dash's immediate unobstructed path; it never steers the dash.
- The folded gantry visibly deploys at reversal, linking the changed carriage
  state to the new route.
- Spike collision matches the drawn tips; there is no invisible lethal margin.
