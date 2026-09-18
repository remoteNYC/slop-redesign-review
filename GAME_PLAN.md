# Clockwork Tower vertical slice

## Summary

Build a short, playable 2D Godot stage that combines precise platforming with enemies designed around movement. The player can **run, jump, and perform an airborne downward attack**. A successful hit damages an enemy or activates a marked clockwork device and rebounds the player upward. Dashes, wall abilities, and ability pickups belong to later levels.

## Implementation

- Create responsive, momentum based movement with variable jump height, jump buffering, and a brief coyote time. Keep attack timing and rebound height consistent enough for deliberate platforming.
- Build a connected tower stage that teaches the rebound on safe devices, then combines it with three distinct enemy behaviors: a ground patrol, a hovering drone, and a telegraphed charging sentry.
- Add spikes, timed crushers, and moving platforms. Arrange challenges so each obstacle tests a different use of running, jumping, or rebounding.
- Use stylized pixel art with clear attack targets and hazard tells, plus basic animation, effects, and sound cues. Add three player health points, nearby checkpoints, quick respawns, and a clear stage finish.
- Keep movement abilities and enemy interactions modular so later levels can introduce ability pickups without rewriting the player controller.

## Interfaces and verification

- Add keyboard and gamepad actions for movement, jump, attack, pause, and restart. The attack works only in the air and strikes downward.
- Verify that enemy and device hits rebound the player, ordinary contact causes damage, lethal hazards restart at the latest checkpoint, and the full stage can be completed with the starting abilities.
- Run the project with Godot 4.7 and play through the stage to tune timing, readability, and checkpoint spacing.

## Assumptions

The first release targets desktop play. It should be challenging but forgiving, with fast recovery after failure. The stage contains no ability pickup; its design leaves room for them in later levels.
