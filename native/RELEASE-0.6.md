# Extinction Protocol 0.6 — Beyond the Rift

## Explore, discover, return stronger

**M** opens the paused expedition map. Walking reveals fog, terrain, nearby caches and shrines. Unknown signals hint at discoveries; click the map to set a waypoint. A screen-edge arrow points to that waypoint or the current cache, shrine or exit.

Twelve discovery sites span the three biomes. Find a site, then purchase its survivor/equipment package with amber in **Discoveries / survivors & equipment**. Discovery is saved immediately; purchases happen between runs. Fresh profiles start with Vesper and a compact selection of guns, melee and elemental spells. Optional equipment, augment groups and relics expand through the archive.

**Returning 0.5 players keep their original catalog, survivors, currency, research and records.** An existing profile with at least one banked run receives legacy unlocks during migration. No progression is reset. Two new weapon discoveries remain available to everyone:

- **Prism Skipper**, found in biome two: crystals ricochet between distinct targets, losing 15% damage per bounce. Rank VIII + Deadeye II + a chest evolves it into **Prism Cascade**, adding ricochets and stronger volleys.
- **Sun Chaser**, found in biome three: crescents fly outward and return toward the moving survivor, hitting again on their return. Rank VIII + movement-speed passive II + a chest evolves it into **Second Dawn**.

The arsenal now has eighteen base weapons and five original unions. Five backpack slots and one offensive aura remain the limits. Daily and Meteor trial use the complete catalog without permanent research bonuses.

## Chests worth stopping for

Every chest uses one RNG reel in every biome, including with eight relics bound. Eligible transformations still take priority and are clearly labelled guaranteed.

- Full satchels: lower-tier finds become a compatible rank upgrade or supplies. Higher-tier relics, and equal-tier Epic-or-better finds, offer an optional replacement.
- On a replacement reveal, **E equips the new relic**. **Space, Enter or movement keeps the current relic and salvages the find for 25 amber and 15 healing**. The current relic's effect is shown for comparison. There is no second popup.
- The reel displays the actual rarity distribution after luck, available compatible relics and bad-luck protection. Locked relics are excluded. An Artifact cannot appear before it is unlocked.
- A union displays both ingredient icons, a merging presentation, and a first-discovery announcement. Discovered recipes are saved in the archive. Consuming two weapons frees exactly one slot.
- Whiteout retains Winterglass's single-target role through three seeking ice lances alongside its freezing arcs. Supernova uses a separate bounded boss hit interval so the union no longer loses most of its ingredients' damage. Controlled large-target checks cover all five unions against their ingredient pairs.
- Scheduled mini-bosses still drop chests while fewer than four boxes are waiting. Invasion mutations instead have a 12% chance, sharing a 35-second cooldown. This removes the late-game chest forest.

## Read the fight

- Original icon atlases distinguish every weapon, passive, augment and relic. Stormbinder, Thunderstorm and Whiteout have separate artwork.
- Backpack cards show the weapon/evolution name, actual rank, and evolved/union state. The bottom HUD fits above the blue XP bar without long relic lists overlapping it.
- **Tab** opens a paused damage/loadout ledger: total effective damage, five-second DPS, average DPS over the weapon's active lifetime, relic effects and acquired upgrades. Overkill is excluded; historical averages stop when ingredients are consumed.
- Boss lanes, craters and shockwaves use painted lava/ember textures with exact footprint outlines. Venom globules and charge wakes use dedicated textures. Hostile effects and the meteor silhouette render above friendly magic.
- Friendly effects have lower additive intensity, smaller impact sizes, a clear area around the player, and bounded visual budgets. Multi-shot volleys stagger their projectiles instead of producing an instant opaque fan.
- Three original 32-bar combat cues, at **140 / 152 / 164 BPM**, give each biome its own melodic hook, harmony and rhythm. The previous calmer score plays in menus. Combat tracks crossfade on biome changes. Weapon effects are 4 dB quieter; warnings and reward sounds retain their level.

## Strong builds, meaningful consequences

- Rank X's hidden extra doubling becomes a 20% mastery bonus. Existing rank scaling, milestone behaviors, solo evolutions and unions remain.
- Shared caps bound count, radius, chain reach, duration, cooldown and active projectiles. Endless combinations no longer multiply without practical limits.
- Blood Chalice heals at most once every two seconds. A mass kill cannot instantly erase repeated boss mistakes.
- The meteor's arena collapse ticks once per second for 18% maximum health + 10, bypassing flat armor. Its 6,000,000 health, anchor windows and phase gates are unchanged.
- Skybreaker Flight, Ironback Procession and Rift Hunt add timed species-specific formations between the large existing swarms. There are lanes and flanks as well as encirclements.
- Armor primarily resists physical attacks. Mossjaw is vulnerable to fire; Cinder Colossus resists fire and is vulnerable to ice. Bosses retain selective crowd-control resistance.
- Utility drops use weighted tables: healing and magnets are more common than nukes, with extra weighting for low health and a crowded XP field.
- Physical gun rounds and Prism Skipper respect rock cover and prefer visible targets. Magical frost/fire retain terrain penetration. Generic weapon data now includes targeting, shot interval, terrain behavior and projectile caps.

## Preservation and design references

The previous 0.5 executable and ZIP are retained. A source backup was made before this pass. Version-one saves retain their format and add discoveries, purchases and recorded recipes; atomic writes retain a previous-save backup. Tests use separate fixture saves.

The user's [weapon reference](https://vampire-survivors.fandom.com/wiki/Weapons), [weapon statistics](https://vampire-survivors.fandom.com/wiki/Weapons/Overview_Stats), [map discovery](https://vampire-survivors.fandom.com/wiki/Milky_Way_Map) and [relic progression](https://vampire-survivors.fandom.com/wiki/Relics) informed the reusable systems. The names, art, music, combinations and implementation are original. The long concept's examples are supported as a design direction, not copied one-for-one into the roster.
