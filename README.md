# Clockwork Relay

A short Godot 4.7 precision-platforming game about turning hazards into tools.
Run, jump, dash, and strike downward through one continuous clockwork route.
The same charging ram that kills on contact can be redirected into a shutter,
the shutter releases a rail carriage, and a later opposing ram can reverse that
carriage into the route to the exit. Redirecting the second ram lets the
carriage reach the far rail stop for a different, equally useful return.
Rebounding from the carriage also reaches an optional upper path: cross above
the opposing ram, drop behind it, and redirect its charge into the carriage.

The game uses a small permanent move set. Downward strikes rebound at a fixed
height and transfer horizontal momentum into rams and the carriage. The free
directional dash also transfers momentum on contact and refreshes after a
successful kinetic clash, a rebound, or landing. Dashing into the carriage
vaults the player toward it, and moving carriage rebounds carry their
horizontal motion into the player's next rebound.
The short dash guide marks a nearby kinetic target when the current aim can hit
it; the dash still travels exactly in the chosen direction.

Failures restart in about a quarter-second. Checkpoints preserve understood
machine state: after opening the shutter, retry begins beside a recoverable
carriage; after reversing the carriage, retry begins on the final moving
encounter.

## Play

Open the project in Godot 4.7 and run it, or run Godot with --path . from this
directory.

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move / horizontal aim | A/D or arrows | Left stick or D-pad |
| Vertical dash aim | W/S or arrows | Left stick or D-pad |
| Jump | Space | A / Cross |
| Directional dash | K or C | B / Circle |
| Downward strike | J or X, in midair | X / Square |
| Pause | Esc | Start |
| Retry checkpoint | R | Y / Triangle |

## Checks

Run the gameplay checks from the repository root:

~~~sh
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/rebound.gd
godot --headless --path . --script res://tests/dash.gd
godot --headless --path . --script res://tests/kinetic.gd
godot --headless --path . --script res://tests/interactions.gd
godot --headless --path . --script res://tests/alternate.gd
godot --headless --path . --script res://tests/high_route.gd
godot --headless --path . --script res://tests/route.gd
~~~

The route check completes the game using player inputs only; it does not
teleport the player or set puzzle state. The capture check saves visual
checkpoints to /tmp when run with a graphics display.

The design audit and successful input sequence are recorded in
[KINETIC_LEVEL_DESIGN.md](KINETIC_LEVEL_DESIGN.md). Past and current changes are
recorded in [CHANGELOG.md](CHANGELOG.md).
