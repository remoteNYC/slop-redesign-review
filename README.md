# Wind Effigy — Thread Playground

A fresh Godot 4.7 side-view prototype for one question: does swinging from village structures make players want another attempt? This is the required 30–60 second greybox gate. Full level production, elastic bamboo, resonance systems, and the final art pass wait for human playtest feedback.

## Run

Open `project.godot` in Godot 4.7.2 and press **Run Project**, or run `godot --path .` from this directory. The game starts in feel variant **B**.

| Input | Action |
| --- | --- |
| A / D | Run and influence airborne movement |
| Space | Jump; buffered input and coyote time are included |
| Aim at a ring, hold left mouse | Attach Wind Thread to that anchor |
| Release left mouse | Keep the velocity you created and fly |
| 1 / 2 / 3 | Switch between the same mechanic's A / B / C tuning profiles |
| R | Retry from the last roof checkpoint |
| Shift + R | Restart the playground and its timer |

Run and jump toward the first beam, attach, then release while rising toward the next roof. The lower ledges provide recovery; the upper line is a shortcut. The puppet has no preset launch impulse on release.

## Current gate

The playground includes a safe first interaction, release timing, an airborne two-anchor chain, lower recovery floors, and a higher optional route. The HUD shows speed, thread tension, attempts, and elapsed time. Three numeric tuning variants live in `scripts/wind_puppet.gd`. `tests/playground_probe.gd` checks constraint stability, timing effects, three landing windows, and a two-anchor chain; it does **not** measure enjoyment.

Use [the playtest sheet](docs/playtest.md) to evaluate the mechanic with a human player. [The design foundation](docs/design_foundation.md) records the reference analysis, palette, and research decisions. Original generated art studies are in [assets/staging](assets/staging/README.md); only the puppet sprite is in the playable greybox.

The pre-reset Git history is independently recoverable from `recovery/pre_reset_6a228f7.bundle`. The previous implementation remains in that bundle and is not used by this game.
