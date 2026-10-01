# Release 0.3 asset provenance

Both atlases were generated with the built-in image generation tool on 2026-09-30, inspected, copied into this project, and integrated using their original alpha channels. No assets from Vampire Survivors or Megabonk were used. The existing painted project atlases remain in use; see `PROVENANCE.md` for those assets.

## pickups.png

Nine cells: frozen hourglass, gravity orb, healing heart, volcanic nuke, frenzy talisman, protective prism, XP crystal, closed relic chest, open relic chest. Used in the world, upgrade cards and chest reveal animation. Original generation: `exec-ad87b29e-9016-4adc-b8a5-af5d5fd60ff9.png`.

Prompt:

> Create a production 2D game asset atlas, square image, exactly 3 columns by 3 rows of equal square cells, nine isolated painted fantasy roguelite collectible icons. Genuinely transparent background, no text, no frames, no grid lines. Each centered in its own cell with generous 18% transparent margin. Dramatic polished hand-painted dark prehistoric fantasy style, high contrast rich jewel colors, clear silhouettes at 48px, soft luminous rim. Row 1 left to right: crystalline blue frozen hourglass with icy wisps (time freeze); emerald-black gravity orb with swirling green motes (magnet); red glass heart potion with bone stopper (healing). Row 2: orange miniature exploding volcanic sun (nuke); crimson electrified claw talisman (frenzy); golden iridescent protective shield prism (invulnerability). Row 3: purple radiant multifaceted knowledge crystal (XP surge); ancient bone-and-bronze treasure coffer closed with violet light in cracks; same coffer opened with bright gold-purple relic light erupting. Exactly 9 distinct icons, no overlapping cells. Game identity Extinction Protocol, human gunslingers and prehistoric magic, premium illustrative assets.

## terrain-features.png

Six cells: mossy boulders, ruined wall, basalt/ice pillars, mud, lava, ground foliage. The first five are used for actual blocking/slowing/damaging terrain. The sixth is reserved art, not a collision tile. Original generation: `exec-1c08ac9c-d615-40b0-93b8-4612e9ad0e16.png`.

Prompt:

> Production painted 2D top-down game terrain atlas, 3 columns x 2 rows of equal square cells on true transparent background, no labels borders or text. Six isolated environmental assets with generous margin, centered and no overlap between cells. Premium hand-painted dark prehistoric fantasy with clear shapes, subtle warm highlights and detailed stone foliage, viewed steeply from above for a top down action game. Top row: dense cluster of mossy grey rounded boulders whose base fills a square 64px collision tile; dense upright ruined stone wall fragment with vine roots filling same square footprint; dense cluster of angular icy blue black basalt pillars filling same square footprint. Bottom row: irregular flat patch of dark muddy brown earth and water with feathered organic edge; flat circular orange lava pool with black crust perimeter and blazing visible center; dark flattened grass ground patch dotted with ferns, no tall objects. Each cell entirely separate on transparent alpha, no shared shadow/background, high quality illustrative style. Terrain must be very readable as obstacles and ground surfaces in Extinction Protocol.

## Sound and rendering

New freeze, magnet, frenzy and nuke sounds are original synthesized waveforms in `scripts/sound.gd`; no third-party audio samples. Shader and gameplay code are project source. The swarm renderer uses Godot's documented [MultiMesh API](https://docs.godotengine.org/en/4.7/classes/class_multimesh.html).
