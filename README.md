# Clockwork Ascent

A short Godot 4.7 platformer set inside a clockwork tower. Run, jump, and strike downward in midair to rebound from enemies and gold clockwork devices. Reach the bell at the top of the stage.

The original design brief and implementation plan are in [GAME_PLAN.md](GAME_PLAN.md).

## Play

Open the project in Godot 4.7 and run it, or run `godot --path .` from this directory.

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | A/D or arrow keys | Left stick or D-pad |
| Jump | Space | A / Cross |
| Downward strike | J or X, in midair | X / Square |
| Pause | Esc | Start |
| Retry checkpoint | R | Y / Triangle |

The player has three health points. Spikes, crushers, and falls restart at the latest checkpoint. The first stage uses only the starting abilities; later levels can add ability pickups.

## Checks

Run the integration checks from this directory:

```sh
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/route.gd
godot --headless --path . --script res://tests/interactions.gd
```

The optional `tests/capture.gd` script saves three screenshots to `/tmp` when run with a graphics display.
