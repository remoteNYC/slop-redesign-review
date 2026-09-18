# Momentum Lab — greybox

A Godot 4.7 test space for one rule: momentum can be redirected by a rigid anchor, stored and returned by elastic bamboo, and transferred into a resonant bell. The arena has multiple possible chains and a low recovery floor. It uses primitive geometry and placeholder sounds.

## Run

Open `project.godot` with Godot 4.7.2 and press Run Project, or run:

```sh
/Users/yangruimeng/Downloads/Godot.app/Contents/MacOS/Godot --path .
```

The project-local Codex Godot MCP setting points at the same local binary. Update `.codex/config.toml` if Godot is moved.

## Controls

| Control | Action |
| --- | --- |
| WASD | Camera-relative movement |
| Mouse | Orbit camera |
| Space | Jump; includes coyote time and jump buffering |
| Shift | Dash in the move direction, or camera forward when idle |
| Hold right mouse | Attach to an anchor in view and within range |
| Release right mouse | Let go with swing velocity preserved |
| R | Respawn at the start |
| Escape | Release the mouse; click to capture it again |

The tether keeps its initial length; it does not pull the player to the anchor. Build speed before attaching and release when its tangent points toward the next landing. Start with the beam across the first gap, then try either the side anchor or bamboo, and reach the bell by chaining through the upper anchors. Experiment with bamboo-to-rigid as well as rigid-to-bamboo approaches.

Movement and feedback values are exported on `Player` and `FollowCamera`. Anchor mass, spring stiffness, release energy transfer, damping, and resonance thresholds are exported on their scene roots. The arena is authored in `scenes/main.tscn`. The `references/` directory holds visual references and is excluded from Godot import.
