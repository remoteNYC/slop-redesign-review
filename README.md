# Clockwork Ascent: Kinetic Prototype

The project currently launches a continuous Godot 4.7 gray-box level for
*Kinetic Clockwork*. Run, jump, and downward-strike a charging ram to transfer
your horizontal momentum into it. The same heavy rail carriage carries that
changing momentum through three connected situations: catch it after launch,
deal with a second ram approaching from the opposite direction, and turn its
leftward return into the jump to the exit gantry.

The original two-level *Clockwork Ascent* build remains intact in
`scenes/game.tscn`; this prototype is isolated in
`scenes/kinetic_prototype.tscn` so the mechanic can be evaluated before either
full level is redesigned.

The original design brief and implementation plan are in [GAME_PLAN.md](GAME_PLAN.md).
Past and upcoming game changes are recorded in [CHANGELOG.md](CHANGELOG.md).

## Play

Open the project in Godot 4.7 and run it, or run `godot --path .` from this directory.

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | A/D or arrow keys | Left stick or D-pad |
| Jump | Space | A / Cross |
| Downward strike | J or X, in midair | X / Square |
| Reset experiment | R | Y / Triangle |

The strike uses the player's current horizontal speed. A near-vertical strike
damps a ram, a fast strike in its direction accelerates it, and an
opposite-direction strike can slow or reverse it. The carriage coasts with
deterministic friction, rebounds from its rail stops, carries the player, and
accepts weaker direct strike corrections. Safe work islands make imperfect
momentum recoverable; spikes and ram contact reset the relay quickly.

The on-screen velocity readout and arrows are temporary playtest diagnostics.
The candidate comparison, section audit, and system-led discovery are recorded
in [KINETIC_LEVEL_DESIGN.md](KINETIC_LEVEL_DESIGN.md).

## Checks

Run the integration checks from this directory:

```sh
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/route.gd
godot --headless --path . --script res://tests/interactions.gd
godot --headless --path . --script res://tests/rebound.gd
godot --headless --path . --script res://tests/dash.gd
godot --headless --path . --script res://tests/kinetic.gd
godot --headless --path . --script res://tests/kinetic_route.gd
```

The optional capture scripts save screenshots to `/tmp` when run with a
graphics display.
