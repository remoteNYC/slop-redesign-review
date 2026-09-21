# Clockwork Relay design

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
5. An opposing ram reverses the carriage if left dangerous. Redirecting it lets
   the carriage reach its rail stop instead; both shared-rule outcomes create a
   return.
6. The reversal deploys the exit gantry. A downward strike on the returning
   carriage inherits its motion and reaches the bell.

## Hard playability constraints

- Run, jump, dash, and rebound inputs use buffering or generous collision
  windows; successful kinetic hits cannot become delayed contact deaths.
- Spike collision begins at the visible spike line.
- The first missed dash falls into a recoverable pocket, and the first missed
  carriage catch lands on a work island.
- Death returns in 0.28 seconds. Checkpoints restore a useful, solvable machine
  state rather than a broken or already-lost timing state.
- No mandatory jump depends on a frame-perfect edge input. The complete route
  is exercised by an input-only automated playthrough.

## Scope

The target is one polished ten-to-twenty-second route, not multiple disconnected
levels. Cosmetic enemy variants, health attrition, lock-on target chains, and
single-room debug diagnostics are outside the final design because they widen
the game without deepening the kinetic rule.
