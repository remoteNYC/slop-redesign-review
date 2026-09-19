# Clockwork Ascent

A two-level Godot 4.7 platformer set inside a clockwork tower. Run, jump, and strike downward in the first level, then chain momentum-preserving dashes through enemy relays in the second.

The original design brief and implementation plan are in [GAME_PLAN.md](GAME_PLAN.md).

## Play

Open the project in Godot 4.7 and run it, or run `godot --path .` from this directory.

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | A/D or arrow keys | Left stick or D-pad |
| Jump | Space | A / Cross |
| Downward strike | J or X, in midair | X / Square |
| Dash aim | W/A/S/D or arrow keys | Left stick or D-pad |
| Target dash | K or C, in level two | B / Circle |
| Pause | Esc | Start |
| Retry checkpoint | R | Y / Triangle |

The player has three health points. Spikes, crushers, and falls restart at the latest checkpoint. Reaching the first bell opens the Relay Shaft and unlocks the dash. Hold a direction and press dash to target the nearest visible enemy within 35 degrees of your aim. A successful hit defeats the target, preserves the player's movement, and refreshes the dash so another can follow immediately.

The title and completion screens include a level selector. Use A/D or the arrow keys to choose an unlocked level, then press Enter, Space, or gamepad A to start it. Completing level one permanently unlocks level two through the local `user://progress.cfg` save.

## Checks

Run the integration checks from this directory:

```sh
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/route.gd
godot --headless --path . --script res://tests/interactions.gd
godot --headless --path . --script res://tests/rebound.gd
godot --headless --path . --script res://tests/dash.gd
```

The optional `tests/capture.gd` script saves three screenshots to `/tmp` when run with a graphics display.
