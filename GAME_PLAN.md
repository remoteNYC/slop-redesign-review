# Clockwork Relay design

## Design reconstruction

The earliest Clockwork Tower brief favored a connected movement stage, rebound
combat, and varied hazards. Its later target-dash chains added skillful aiming
but made enemies disposable steps in a prescribed sequence. The gray-box
kinetic experiment found a stronger relationship: a threatening ram can launch,
reverse, or rescue the same carriage. Wind Effigy's earlier notes also argued
for momentum that remains legible after a player releases control, and for a
human playtest before claiming that a reachable route is fun. This design keeps
those principles without restoring the tether, health attrition, crushers, or
extra levels.

## Core verbs and rules

Run, jump, aim a free dash, and strike downward. Four main mechanics compose:
fixed rebound, kinetic ram, rail carriage, and a shutter that only a moving ram
can open. The player learns the rebound safely, uses a dash across a recoverable
gap, redirects a ram through the shutter, catches the carriage, then decides
whether to redirect an opposing ram or let it reverse the carriage. A rail-stop
return is a second valid outcome. Reversing the advanced carriage deploys the
exit. The same carriage becomes the final rebound tool.

The target is a focused first-play sequence of roughly three to five minutes
including observation and retries. A practiced route should be much faster;
do not lengthen it with empty travel or new standalone hazards. This timing is
a design target pending human playtesting, not an automated result.

## Promise

Build a short precision-platforming route in which one understandable kinetic
rule repeatedly changes meaning:

> A downward strike or directional dash transfers horizontal motion. Rams and
> the carriage keep that motion until friction, another impact, or a rail stop
> changes it.

Contact with a ram is lethal unless the player is actively striking or dashing
it. A confirmed interaction always separates the player safely and refreshes
the dash. The result should progress from threat, to understood rule, to
deliberate tool.

## Continuous learning arc

1. A safe clock pad and an unreachable ledge establish the fixed rebound.
2. A recoverable gap demonstrates the free directional dash without killing a
   player who misses it.
3. A charging ram initially threatens the player. Redirecting or vaulting it
   sends the same ram through a kinetic shutter and into a carriage.
4. The carriage can be caught, ridden, dashed, or struck. A work island keeps a
   missed catch playable.
5. An opposing ram reverses the carriage if left dangerous. Its windup commits
   to a visible direction, so the player can bait its timing or redirect it
   away from the carriage. Redirecting it lets the carriage reach its rail stop
   instead; both shared-rule outcomes create a return.
6. The reversal deploys the exit gantry. A downward strike on the returning
   carriage inherits its motion and reaches the bell.

## Hard playability constraints

- Run, jump, dash, and rebound inputs use generous collision windows; successful
  kinetic hits cannot become delayed contact deaths. A ground dash must travel
  across a floor instead of stopping on floor contact.
- Spike collision begins at the visible spike line.
- The first missed dash falls into a recoverable pocket, and the first missed
  carriage catch lands on a work island.
- Death returns in 0.28 seconds. Checkpoints restore a useful, solvable machine
  state rather than a broken or already-lost timing state.
- No mandatory jump depends on a frame-perfect edge input. The complete route
  is exercised by an input-only automated playthrough.

## Scope

The target is one polished continuous route, not multiple disconnected levels.
Cosmetic enemy variants, health attrition, lock-on target chains, a second
shutter, and single-room debug diagnostics are outside the playable design
because they widen the game without deepening the kinetic rule.
