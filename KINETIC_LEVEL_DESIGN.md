# Kinetic Clockwork level design

## Structure gate

All three candidates use the same rules: a downward strike transfers the
player's horizontal speed to a ram or, less efficiently, to the carriage; rams
transfer their current speed on contact; the carriage coasts, carries the
player, and rebounds from its rail stops.

| Candidate | Control density and waiting | Recoverable states and outcomes | Mistakes, surprise, and mastery | Rectangle test |
| --- | --- | --- | --- | --- |
| **Long rail relay** — a horizontal pursuit built around one continuously moving carriage and rams approaching from both directions | High control density; little forced waiting because the player can ride, chase, redirect, or correct moving objects | High. Safe work islands, direct carriage corrections, two rail stops, and either ram can rescue bad momentum. Launch strength, collision order, and player position produce genuinely different continuations | A bad counter-impact sends the entire situation backward instead of clearing it. Skilled players can intercept early, create a later rear boost, or use a faster stop rebound | Strong: motion, spacing, and arrows communicate the whole level |
| **Rising transfer shaft** — stacked horizontal rails whose momentum choices are carried upward by the player | Medium-high control density, but medium waiting while lifts and carriages arrive at transfer floors | Medium. Falling revisits a lower tier, but crossing a tier boundary partially resets the physical problem | Good route invention, but mistakes too often feel like lost height rather than a new machine state | Good, although vertical ownership is harder to read without art |
| **Compact switching yard** — one arena where a carriage and two rams repeatedly exchange roles | Very high control density and low-to-medium waiting | Very high. It permits the most collision orders and local recoveries | Excellent emergence, but the objective becomes opaque and repeated use of one space trends toward a machine puzzle with a known answer | Excellent as a sandbox, weaker as a continuous level |

The long rail relay is the strongest structure. It combines the switching
yard's expressive collisions with a legible journey, and the consequence of
each interaction physically enters the next section.

## Final three situations

1. **Launch and catch.** The player redirects the launch ram, rebounds, and
   intercepts a carriage that is already moving. A weak launch can be repaired
   by striking the moving carriage; a strong launch creates a faster boarding
   problem.
2. **Opposing ram.** The same carriage enters a head-on encounter. The player
   can redirect the counter-ram before impact, alter it late, or allow the
   collision and recover the reversed carriage. The safe central floor lets a
   missed landing become a chase instead of a restart.
3. **Use the return.** The carriage returns left either from the far stop or
   because the displaced counter-ram comes back and hits it. The returning
   carriage is the launch point through the exit gantry. Extra momentum can
   create a faster route rather than only an overshoot penalty.

There are no walk-only corridors between these situations. The launch ram can
continue pushing the carriage into the counter encounter, and the displaced
counter-ram can cause the final return.

## System-led discovery

The first route probe deliberately allowed the counter-ram to hit the carriage
without intervention. The carriage travelled back into the original launch
ram, which struck it from the left and relaunched it. This was understandable,
repeatable, and useful, but was not part of the initial route plan.

The level was changed to support it: the launch ram's range now extends onto a
wider first recovery island. A failed counter interaction therefore changes
which earlier object is useful instead of forcing a reset. A second discovered
outcome was retained at the finish: the redirected counter-ram can rebound and
create the carriage's useful return before the carriage reaches its own stop.

## Ruthless edit check

- Removing launch and catch loses moving interception and player-to-ram setup.
- Removing the opposing ram loses head-on transfer, reversal recovery, and the
  relaunch discovery.
- Removing use the return loses deliberate over-momentum and the reinterpretation
  of leftward motion as progress.

Each section therefore contributes a different interaction. No extra section
was added only to increase timing difficulty or level length.
