# Extinction Protocol 0.4 — build a legend

## Play and build

Five weapon slots, visible in the bottom-left backpack. Weapon upgrades and evolutions retain their slot. Once full, level-ups offer existing weapons, applicable augments and passives. Only one offensive aura can enter a build; orbiting blades, barriers and time magic remain distinct options.

Start each run with three rerolls. Press R or click Reroll on the level-up screen. A reroll excludes the displayed offers when at least three alternatives exist, costs one charge, and does not advance gameplay. Boss kills restore one charge, up to five. Meteor trial also uses five weapons.

## Combat

Winterglass and all other projectiles now use a shared ground-space aim origin and swept segment collision. Fast projectiles cannot skip small targets between ticks. Volleys always include a centre shot; ricochets start a fresh path next tick instead of hitting along their previous trajectory.

Fire hitting a frozen enemy causes thermal shock: it consumes the freeze and schedules one area explosion. Per-enemy cooldowns, a damage cap and the existing bounded proc queue prevent recursive explosions. Ice remains useful alongside fire, instead of merely duplicating damage. Gun impacts, crystalline frost trails/shards, fire cores and directed spear thrusts have distinct effects.

## Relic caches

Caches roll one compatible, unowned relic and automatically award it after a slowing reel and rarity reveal. No selection followed by another confirmation. Eight relics remain the satchel limit; additional caches provide the existing bonus upgrade and amber reward.

Rarity tiers: Common (white), Uncommon (green), Rare (blue), Epic (purple), Legendary (orange), Artifact (gold). Initial tier weights are 40 / 30 / 18 / 9 / 2.7 / 0.3, normalized over available tiers. After four consecutive Common/Uncommon rewards, the next eligible roll is Rare or better. The actual reward is selected by the seeded simulation before animation; decorative reel movement does not alter it.

26 relics, including six additions: Hunter's Flint, Mammoth Wrap, Quickening Coil, Amber Lens, Prism of Plenty and the ultra-rare Unwritten Era. New bonuses affect real damage, health, recharge, XP or projectile/chain/blade/bombardment counts.

## Audio

Original 116 BPM D-minor chiptune/adventure score, “Against the Falling Sky”: 32 bars, melodic variations, triangle bass, pulse lead, bell arpeggios, pads and percussion. A synchronized additional rhythm layer rises with danger. Music has independent players so weapon spam cannot steal its voices. The loop is 66.21 seconds.

36 stereo sound cues include weapon-specific casts, separate frost/fire/metal impacts, thermal shock, reel ticks and six rarity stings. Frost uses inharmonic ice/glass tones and fracture noise; firearms use sharp report/body layers; fire and mortar use low roar/impact layers; lightning uses gated crackle; arcane abilities use resonant tones. Repeated impacts and aura casts are rate-limited for mix clarity.

Generated deterministically by `tools/compose_audio.py`, with no borrowed recordings or melodies. Music and sound toggles retain saved preferences.

## Biomes, enemies and boss pacing

The first two bosses leave a visible animated rift instead of immediately changing biomes. Collect remaining drops, then walk into the rift for 0.65 seconds to leave. Staying behind increases spawn pressure up to fivefold, enemy health up to fourfold and newly spawned enemy movement speed up to 75%. The HUD displays linger time and spawn pressure. Entering clears remaining old-world drops and starts the next biome's five-minute boss interval, with a brief protected visual transition. Runs can exceed fifteen minutes when you linger or take longer to defeat bosses.

Fourteen enemy species now include Venomcrest spitters, armored Ironbacks and Mossjaws, telegraphing Tuskbreaker mammoths, Brood Widows that release three hatchlings, flying Amberwings, Cinder Colossi, terrain-phasing Rift Stalkers and Embersails. New painted silhouettes are GPU-batched. Heavy species enter after the opening section; later biomes change the mix.

Ordinary ground attackers share a global cooldown: four seconds in biome two, three elsewhere. Warnings last 1.65 seconds and impacts just 0.3 seconds, with fixed positions. Ordinary casters stop casting during boss fights. Killing elites no longer creates a damaging ground burst.

Basalt Behemoth health is 90,000 (previously 360,000). It now uses obsidian-colossus art, alternates four crossing lanes with two brief impacts, and pauses 4.7–5.5 seconds between patterns. Half-health armor transition remains. The final Extinction Engine retains its extreme six-million-health build check.

XP is now at the bottom. Boss name, phase, health and final-boss mechanics are at the top in an original illustrated fossil/obsidian frame with a delayed damage trail.

## Inspiration

Reviewed indexed excerpts from the user-supplied Vampire Survivors wiki: [Weapons](https://vampire-survivors.fandom.com/wiki/Weapons), [Level up](https://vampire-survivors.fandom.com/wiki/Level_up), [PowerUps](https://vampire-survivors.fandom.com/wiki/PowerUps), [Treasure Chest](https://vampire-survivors.fandom.com/wiki/Treasure_Chest) and [Evolution](https://vampire-survivors.fandom.com/wiki/Evolution). Direct Fandom fetches returned 402, so research used indexed excerpts. Limited loadouts, rerolls, weighted rewards and upgrade/evolution roles informed this pass; game content, audiovisual assets and tuning are original.

Enemy roles and biome encounters also take inspiration from the user-linked [Enemies reference](https://vampire-survivors.fandom.com/wiki/Enemies). See assets/PROVENANCE-0.4.md for original artwork and audio details.
