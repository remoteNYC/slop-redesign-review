# Design foundation — Wind Effigy

## Intended player experience

The player borrows force from the village. A fixed thread changes the direction of existing motion; it does not pull the puppet to a target or assign a launch vector. Entry speed, anchor position, gravity, limited steering, and release time are the shared rules. The immediate test is whether a player can describe a failed trajectory and wants to adjust it on the next try.

The current authored playground is a gate, not a miniature final game. A first beam spans a gap, two beams allow a chain, lower roofs catch mistakes, and a higher route rewards control. The final 4–7 minute village and elastic/resonant materials remain contingent on human feedback.

## Reference reading

The six village files are the world art bible. They are scene and material references, never textures or final backgrounds.

| Reference | Observed design information | Gameplay translation |
| --- | --- | --- |
| `village_02` | Tight street, heavy roof overhangs, irregular white plaster, dark suspended forms | An early protected lane and a beam that clearly belongs to an overhang |
| `village_03` | Canal negative space, layered walkways, a distant pagoda, mist that separates depth | Readable gap, underside anchor, distant destination landmark |
| `village_04` | High retaining wall, stacked pale buildings, bare tree and sparse aged red | Tall wall route, branch anchor, red reserved for interaction cues |
| `village_05` | Deep timber eaves and narrowed street framing a brighter distant opening | Short tunnel followed by a visible movement choice |
| `village_06` | Long stepped roof silhouettes and repeated balconies against cool distance | Roof-to-roof rhythm with safe landings under the faster line |
| `village_07` | Close roof and balcony overlap, irregular gaps, small bridge and arch | Two heights of traversal and structural beams beneath a bridge |

`character_01` suggests layered cloth around a narrow center and small warm accents. `character_02` gives a strong dark vertical mass and red cloth movement. `character_03` contributes faded blue cloth and a lighter face-to-body contrast. The original Wind Puppet uses **artifact proportions**, a timber body, an off-white mask, indigo cloth, and a small cinnabar thread spool; it is not a reduced human character. Its 78-pixel gameplay sprite is readable on both plaster and timber.

`pixel_style_01` informs only the side-view composition: a small protagonist against large structures, strong playable silhouettes, separated depth planes, and empty space around traversable gaps. Its warm colors and industrial architecture are not part of the game's palette or setting.

## Working visual system

| Layer | Colors | Rule |
| --- | --- | --- |
| Far sky and mountains | warm mist `#e2e0d4`, cool pale blue-gray `#b9c9c8`, `#9cafad` | Low contrast, low detail |
| Distant village | `#748f90`, `#7c9290` | Soft simple roof masses |
| Playable plaster and stone | aged ivory `#c7c5b2`, cool gray-green `#748780` | Clear top edges and landing surfaces |
| Timber and roof | `#273332`, `#3b4743`, `#536c69` | Strong collision silhouette |
| Interaction and puppet | thread `#ad4e3d`, bronze `#a38b67`, mask `#d4cfbb` | Saturation concentrated at the verb and character |

The current geometry is code-drawn placeholder architecture. A later kit should use separate wall, roof, balcony, bridge, stone, branch, and bamboo modules. Each module needs a consistent side-view scale, an explicit collision top or attachment pivot, and a far/near contrast variant. For the planned 1280×720 viewport, roof modules should span roughly 160–320 game pixels; anchors need a visible ring of at least 16 pixels; the puppet should remain about 60–80 pixels high. Art cannot obscure the rope, landing edge, or intended trajectory.

The staged generated art samples provide a starting material study. They are not texture-filtered reference images. The bamboo study is rejected for current use because a green halo contaminates its transparency. Future bamboo art must have clean alpha, a separate deformable stalk layer, a base pivot, and leaves that can trail the bend.

## AI-and-Games research used

I reviewed the [official book site](https://gameaibook.org/), [table of contents](https://gameaibook.org/toc/), [exercises](https://gameaibook.org/exercises/), and [book PDF](https://gameaibook.org/wp-content/uploads/2024/08/book2.pdf), especially behavior authoring (3.1), PCG (7), levels/visuals/rules/evaluation (9.1, 9.2, 9.5, 9.7), and player modeling/experience (10 and 12.3). I also reviewed the authors' [Experience-Driven PCG paper](https://yannakakis.net/wp-content/uploads/2015/11/PID3821875.pdf).

The EDPCG framework links content representation, generation, content quality, and a player experience model. That suggests a useful hierarchy here: authored candidate route geometry, automated reachability/stability probes, then observed human experience. A technically reachable roof can still create a poor rhythm or confusing failure. The official material distinguishes functional checks from subjective aesthetics/experience, so automated probes are never treated as proof of fun.

Behavior authoring methods such as finite state machines and behavior trees are useful when NPC behavior becomes necessary. This playground has no NPCs or combat, so adding an AI behavior stack now would not serve the target experience. Rule and mechanic generation is relevant as a design lens: one tether rule plus future rigid/elastic/resonant properties can create variations without adding unrelated buttons. Any later candidate layout generator would need human curation and evaluation for downtime, route choice, recovery, and mastery, as well as solvability.
