# Original art studies

These images were generated with the built-in `image_gen` tool from written visual rules derived from the reference analysis. None of the reference PNGs was copied, cropped, filtered, or supplied as an edit target. Only `../sprites/wind_puppet.png` is used in the playable greybox. The generated full-resolution puppet source is `../source/wind_puppet_generated.png`; the gameplay cutout was cropped and scaled from that new image.

| File | Status |
| --- | --- |
| `mountain_distant.png` | Candidate low-contrast far background; requires parallax composition check after the gameplay gate |
| `plaster_roof_module.png` | Candidate architecture; needs modular splitting and collision pivots |
| `bronze_bell.png` | Candidate prop; resonance behavior is not yet implemented |
| `bamboo_candidate.png` | **Rejected for game use:** green halo remains in transparent areas; regenerate a clean cutout after the gate |

## Final saved prompts

**Puppet source (`../source/wind_puppet_generated.png`):**

> Use case: stylized-concept. Asset type: original side-view gameplay character sprite for a Godot 2.5D traversal prototype. Create ONE original small ritual Wind Puppet, a constructed village artifact that borrows momentum from architecture. Full-body right-facing side profile in a neutral ready-to-move pose. A compact carved dark-timber body, small off-white weathered plaster-like ritual mask with two simple dark eye marks, short folded faded-indigo cloth around shoulders and hips, a single muted cinnabar thread spool mounted at its back and a short loose red cord tail. Jointed wooden limbs suitable for running and swinging. The silhouette must be readable at 64–96 pixels tall against both light plaster and dark timber. Refined painterly pixel-art game sprite with deliberate clusters and clean outer silhouette; original design. One isolated character, centered, ample transparent padding, no ground shadow. Palette: near-black brown #292b28, aged ivory #e5dfca, faded indigo #596e78, muted cinnabar #a4513f, small brass #9e865d. Truly transparent alpha background, no scenery, no text, no sprite-sheet grid, no extra poses, no copied reference image, no human adult proportions, no cape, no photorealism, no watermark.

**Distant mountain (`mountain_distant.png`):**

> Use case: stylized-concept. Asset type: ORIGINAL distant mountain background layer for a side-view 2.5D game. A quiet restrained far-background panorama: only two broad staggered blue-gray mountain silhouettes with thin low fog and a very pale warm gray sky. A few tiny softened roof silhouettes near the bottom. Designed to sit behind highly readable playable village roofs, with no dramatic focal point. Painterly pixel-art game layer with broad simple clusters and low detail density, no photograph/filter treatment. Horizontal 16:9 panorama, consistent side-view horizon, clear negative space in middle third. Low-contrast dusty cyan, pale gray-blue, faint gray-green, warm off-white mist. No high saturation. No waterfall, no lake, no cliff foreground, no prominent temple, no large trees, no people, no text, no copied reference composition.

**Building module (`plaster_roof_module.png`):**

> Use case: stylized-concept. Asset type: original modular architecture sprite for a side-view 2.5D game, staged for later art pass. ONE isolated village building module: a weathered off-white plaster wall with dark exposed timber grid, topped by a gray-green tiled roof with deep dark overhang. Damp moss along stone base, very restrained aged red mark near one doorway. Designed as a readable gameplay roof and wall, with a clearly continuous walkable top silhouette and one hanging structural beam under the eave. Refined painterly pixel-art sprite, deliberate broad forms and limited texture clusters, original design. Strict side-on orthographic elevation, one complete module, centered with transparent padding, no landscape or ground shadow. Palette: aged ivory #c9c6b1, near-black timber #2d3634, roof #536c69, moss #65745b, tiny aged red #9d5141. True transparent alpha background, no other buildings, no character, no text, no copy of reference images, no isometric perspective.

**Bell (`bronze_bell.png`):**

> Use case: stylized-concept. Asset type: original interactive bell prop sprite for a side-view Godot game, staged for later art pass. One small weathered bronze village temple bell suspended from a simple dark timber bracket by a visible short cord, designed as a tetherable resonant structure. The bell lip and attachment eye must have clear silhouettes. Old metal with muted green patina and a tiny faded red cord knot. Refined painterly pixel-art gameplay sprite with purposeful broad shapes and readable highlights; original design. Strict side-on view, isolated complete prop, centered with generous transparent padding, no floor shadow. Palette: near-black timber, aged bronze, green patina, tiny aged red. True transparent alpha background, no text, no scenery, no person, no copied reference imagery, no black rectangle background.

**Rejected bamboo candidate (`bamboo_candidate.png`):**

> Use case: stylized-concept. Asset type: original isolated bamboo gameplay sprite. ONE slender bamboo stem with two short side branches and a small leaf cluster, rooted in a tiny mossy stone base. It must be a simple clean cutout suitable for a bendable elastic tether point in a side-view game. Restrained painterly pixel art with few broad color clusters and clear silhouette; no lighting effects. Strict side-on orthographic, full plant from tip to base, centered on transparent canvas with padding. Palette: muted gray-green #647765 and dark teal green #405b57, moss #68735a. Truly transparent alpha everywhere outside stalk/leaves/stone. No color glow, no green aura, no colored backdrop, no gradient, no ground shadow, no extra scenery, no text, no copied reference image.
