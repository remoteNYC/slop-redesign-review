# Clockwork Relay audit and final route

## Audit

The previous repository contained two disconnected designs: a two-level
platformer whose second level was a prescribed lock-on target chain, and a
gray-box rail prototype with a stronger systemic premise but hidden velocity
numbers, long reset state, and an exit that did not actually require the
advertised return.

The redesign classified the major work as follows:

| Decision | Systems |
| --- | --- |
| Keep | responsive acceleration, coyote time, jump buffering, fixed rebound, quick retry, clockwork presentation, persistent ram/carriage impacts |
| Keep but simplify | kinetic transfer bands, camera, recovery islands, checkpoint state |
| Redesign | lock-on dash into a free directional kinetic dash; debug rail into one continuous learning arc; return into a mechanically required exit deployment |
| Remove | health attrition, cosmetic enemy variants, relay target chains, isolated crushers, level select, numeric diagnostics |

The target dash was removed because it reduced play to target 1 → target 2 →
target 3. The free dash now composes with ordinary movement, rams, the carriage,
landing, and rebound refreshes.

## Shared rules

- A ram telegraphs, faces the player during windup, then keeps its charge
  momentum.
- A downward strike gives a fixed vertical rebound and transfers the player's
  horizontal motion.
- A directional dash transfers stronger motion. A confirmed clash separates
  the player safely.
- Rams open kinetic receivers and collide with the carriage instead of being
  consumed.
- The carriage carries the player, accepts weaker direct corrections, rebounds
  at rail stops, and contributes its motion to a player's rebound.
- Reversing an advanced carriage deploys the exit. Either the opposing ram or
  the far rail stop can create that reversal.

## Successful player sequence

The full route check uses only player inputs and completes this sequence:

1. Run to the gold pad, jump, strike down, and use the fixed rebound to clear the
   first ledge.
2. Run-jump and dash across the upper gap. A miss falls beside a second pad and
   can be recovered.
3. Drop toward the first ram and dash through it to the right. The ram opens the
   shutter, continues into the carriage, and rebounds back as a readable second
   danger.
4. Catch the carriage. After a missed catch or death, the checkpoint restores a
   stationary carriage on the work island; one or two moving downward strikes
   relaunch it.
5. Ride toward the opposing ram. Leaving the ram dangerous makes it reverse the
   carriage quickly. Redirecting it instead lets the far stop create the same
   useful return.
6. When the gantry unfolds, jump from the left-moving carriage, strike it, and
   let the inherited leftward motion carry the rebound into the bell.

The input-only route completes in roughly ten seconds of active play and
includes enough margin for a short jump hold, non-perfect dash timing, one
missed catch, and checkpoint recovery.

## Failure information

- Missing the upper gap reveals the recovery pad rather than causing death.
- Letting the first ram return after opening the shutter can kill the player,
  but the opened-shutter checkpoint makes the cause immediately replayable.
- Missing the carriage lands on a work island whenever the player still has a
  recoverable trajectory.
- The opposing ram's red windup and motion arrow show why the carriage reversed.
- The folded gantry visibly deploys at reversal, linking the changed carriage
  state to the new route.
- Spike collision matches the drawn tips; there is no invisible lethal margin.
