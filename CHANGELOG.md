# Game changelog

This file records the history of the game, including discarded prototypes. It is
ordered newest first within each date. Commit links use abbreviated local Git
revisions because the repository may be moved or forked.

## Unreleased

- Restored a short directional dash guide and kinetic target cue from the old
  aimed-dash experiment, adapted to the free dash without homing or target order.
- Added an optional upper approach above the opposing ram, reached by rebounding
  from the carriage, with a safe drop behind it and room to redirect its charge
  back into the carriage.
- Prevented a carriage returning offscreen from awarding a later checkpoint to
  a player who stayed behind, and rejected stale bell-contact signals after a
  retry so they cannot complete a run from outside the goal.
- Made an advanced carriage's return deploy the exit whether it is reversed by
  the opposing ram, the far rail stop, or a deliberate player correction; the
  separate far shutter is no longer a required trigger.
- Fixed horizontal ground dashes ending on floor contact, made carriage dashes
  vault the player toward a catch, and preserved earned airborne momentum long
  enough to use it.
- Reduced carriage drag so its return can actually reach the final rebound,
  and made charging rams commit to the direction shown by their windup.
- Rebuilt the game as one continuous Clockwork Relay route focused on a shared
  momentum rule, with a safe rebound opening, kinetic shutter, persistent rail
  carriage, opposing ram, return gantry, and bell exit.
- Replaced the level-two lock-on target chain with a permanent free directional
  dash that transfers motion into rams and the carriage and refreshes on
  landing, rebound, or a successful kinetic clash.
- Added fast state-aware checkpoints, recovery pads and work islands, exact
  visible spike hitboxes, a more generous strike connection, and brief contact
  grace so successful strikes and dashes cannot become delayed collision deaths.
- Removed the disconnected Foundry and Relay Shaft level flow, health attrition,
  cosmetic enemy variants, crushers, level selection, and prototype velocity
  diagnostics from the playable game.
- Made the opposing ram or far rail stop reverse the same carriage, visibly
  deploy the exit, and let the returning carriage contribute horizontal motion
  to the final rebound.
- Cleaned up active procedural sound playback when leaving the game scene so
  retries, automated runs, and scene shutdown do not retain stale audio objects.
- Expanded the Kinetic Clockwork experiment from one room into a continuous
  three-part rail relay built around the same persistent carriage.
- Added an opposing ram, a scrolling camera, recovery islands, and an exit
  gantry reached by using the carriage's leftward return.
- Extended the launch ram's range so a carriage reversed by the opposing ram
  can return to it and be relaunched instead of forcing a restart.
- Reduced carriage friction for the long rail, keeping objects in motion while
  preserving direct strike corrections and rail-stop rebounds.
- Added a one-room Kinetic Clockwork gray-box prototype as the project's launch
  scene while preserving the original two-level game scene.
- Made downward strikes transfer the player's horizontal momentum into the
  prototype ram and heavy rail carriage. The persistent ram can then transfer
  its current momentum into the carriage on contact.
- Added deterministic carriage friction, damped rail-stop rebounds, direct
  strike corrections, quick room resets, and temporary velocity diagnostics.
- Built a compact test room with a safe starting ledge, spike rail, movable
  carriage, charging ram, and upper-right exit to test undershoot, controlled
  pushes, overshoot, and recovery from imperfect inputs.

## 2026-09-18

### Directional dash targeting (`60af703`)

- Changed the level-two dash from automatic nearest-target selection to
  directional aiming with the keyboard, D-pad, or analog stick.
- Limited valid dash targets to visible enemies within 175 pixels and a
  35-degree cone around the player's aim.
- Added an aim-cone guide and target highlight, and revised the HUD and in-level
  instructions to teach the new controls.

### Relay Shaft and level selection (`23dc870`)

- Expanded *Clockwork Ascent* from one level to two with the Relay Shaft, a
  longer stage built around chains of relay enemies, spike gaps, crushers, and
  three checkpoints.
- Added the target dash. It homes toward a visible relay enemy, defeats it on
  contact, carries some entry momentum through the hit, and refreshes after a
  successful connection so dashes can be chained.
- Added dash-ready HUD feedback, dash effects and sounds, and relay-enemy visual
  states.
- Added a level selector to the title and completion screens. Finishing level
  one unlocks level two and saves that unlock in `user://progress.cfg`.
- Made checkpoints, goals, camera limits, respawning, and completion flow work
  independently for either level.

### Rebound and crusher corrections (`47efc06`)

- Made crushers solid moving bodies with separate lethal spike hitboxes, so
  their movement and contacts are handled by physics instead of an approximate
  distance check.
- Stopped jump-button release from shortening a rebound, downward strike, damage
  knockback, death, or respawn motion by tracking whether a normal jump is still
  eligible for a variable-height cut.
- Added focused integration coverage for rebound height and the corrected
  crusher behavior.

### Clockwork Ascent vertical slice (`9809cea`, integrated by `d6b581b`)

- Replaced the thread-swinging prototype with *Clockwork Ascent*, a side-view
  pixel-art platformer rendered at a 384 x 216 internal resolution.
- Added momentum-based running, variable jump height, coyote time, jump
  buffering, an airborne downward strike, and upward rebounds from enemies and
  gold clockwork devices.
- Built the Clockwork Tower stage with platforms, spikes, moving platforms,
  timed crushers, rebound devices, checkpoints, and a bell goal.
- Added three enemy types: patrolling walkers, hovering drones, and charging
  sentries with a telegraphed windup.
- Added three-point health, damage knockback and invulnerability, fall and hazard
  deaths, checkpoint respawns, pause/retry flow, a timer and HUD, title and win
  overlays, particles, and generated sound effects.
- Added keyboard and gamepad controls plus smoke, route, interaction, and
  screenshot checks.
- Added the game's design and implementation brief in `GAME_PLAN.md`.

### Prototype reset and branch transition (`abc3a7a`, `d6b581b`)

- Removed the Wind Effigy implementation, its generated art and audio, design
  notes, playtest materials, and recovery bundle from the main branch.
- Merged the Clockwork Ascent branch, making that vertical slice the active game.

### Wind Effigy thread playground (`30e8be7`)

- Reworked the earlier 3D experiment into *Wind Effigy*, a 30–60 second
  side-view swinging playground intended to test whether the core interaction
  was enjoyable.
- Added running, buffered/coyote-time jumping, mouse-aimed Wind Thread
  attachment, momentum-preserving release, roof checkpoints, recovery ledges,
  an optional high route, and an airborne two-anchor chain.
- Added three switchable feel profiles, retry and full-restart controls, and a
  HUD showing speed, thread tension, attempts, and elapsed time.
- Added a puppet sprite, generated audio, art studies, a design foundation,
  human playtest instructions, and automated probes for constraint stability,
  landing windows, timing, and anchor chaining.
- Preserved the preceding Momentum Lab prototype in a Git recovery bundle before
  replacing it.

## 2026-09-17 to 2026-09-19

### Momentum Lab greybox (`6a228f7`)

- Created a third-person momentum playground for redirecting speed around rigid
  tether anchors, storing and returning energy with elastic bamboo, and
  transferring motion into a resonant bell.
- Added camera-relative movement, orbit camera controls, jumping with coyote time
  and input buffering, directional dash, hold-to-attach tethering, preserved
  swing velocity on release, and respawning.
- Built multiple anchor chains, alternate routes, a low recovery floor, a goal
  bell, debug feedback, placeholder sound effects, and reference art.
- Added automated probes for the first swing, bamboo behavior, and momentum
  transfer.

> The commit's authored date is 2026-09-19 in UTC+08, which corresponds to
> 2026-09-18 in this repository's later UTC-04 working timezone.

### Project foundation (`ce11fd8`, `7456c70`, `d695b22`)

- Created the repository and an initially empty Godot 4.7 project named *Slop*.
- Added the project icon, editor and Git settings, and local Codex/Godot tooling
  configuration. The follow-up commit corrected that tooling configuration; it
  did not change gameplay.

## Maintenance rule

Every future change that affects gameplay, levels, controls, balance, content,
presentation, audio, player-visible behavior, or game-facing bug fixes must add
an entry under **Unreleased** in the same change. Replace “No game changes yet”
when adding the first entry. Keep entries factual and player-focused, and never
delete historical entries when a feature is removed; record the removal as a new
change instead. Documentation-only, test-only, and internal refactors need an
entry only when they alter or clarify player-visible behavior.
