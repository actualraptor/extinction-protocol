# Extinction Protocol 0.5 — Storms & Unions

## Faster rewards, clearer choices

- Rift shrines charge in six seconds, down from twelve. Portal entry also takes half the previous time.
- Relic reels keep the landed reward visible until a fresh WASD, arrow, Space or Enter press. Holding movement cannot accidentally skip the result. There is no second popup.
- Mini-bosses drop a physical relic chest. Walk over it to collect; it remains until you leave the biome.
- Chest rarity odds appear below the reel. Base weights: Common 40%, Uncommon 30%, Rare 18%, Epic 9%, Legendary 2.7%, Artifact 0.3%.
- Fortune's Favor is a new run passive. Permanent Scavenger's Luck research improves rarity odds as well as amber income. Higher tiers receive progressively stronger weighting; the displayed odds include luck, available unowned compatible relics and the existing fifth-dry-chest Rare guarantee.
- A ready evolution or union takes priority over a relic roll, even with eight relics equipped. The reveal clearly identifies a guaranteed transformation rather than displaying random relic odds.

## Weapons and evolutions

Vesper starts with Stormbinder. Sixteen base weapons/spells plus five original unions are available. Carry five weapons at once, with at most one offensive aura.

Both union ingredients must reach **rank X**. Their individual evolved forms also qualify. Collecting the next chest replaces both with their union, freeing one slot. Ingredients consumed by a union cannot be reacquired during that run. When multiple recipes are ready, the chest selects one eligible union.

| Ingredients | Union | Behavior |
|---|---|---|
| Stormbinder + Winterglass | WHITEOUT | Frost lightning arcs through enemies, freezes them, and detonates already-frozen prey. Detonations have a shared cooldown and cannot recursively detonate. |
| Cinder Gospel + Extinction Mortar | SUPERNOVA | Solar bombardments leave burning fields with a final eruption. |
| Graveshot + Bone Rattler | THE LAST WORD | Rapid, long-range fans of piercing execution rounds. |
| Ancestor's Wrath + Epoch Lance | EARTHSHAKER | Wide full-circle cleaves, echoes and piercing shockwaves. |
| Rift Blades + Prism Aegis | RIFT BASTION | Heavy orbiting blades with a periodically recharging barrier. |

Solo evolutions require **rank VIII + their linked passive at rank II + a chest**. Upgrade cards show the recipe. Each keeps its role: seeking/faster-freezing Winterglass, branching Stormbinder, burning mortar craters, larger fire explosions, wider auras, stronger barriers and longer time stops. Unions are optional and do not require choosing a solo evolution first.

**Thunderstorm** creates a targeted two-second field with four lightning strikes. It benefits from damage, area, cooldown, field count and duration upgrades. It is not an aura. Its evolution, HEAVEN'S END, lasts three seconds and strikes twice as often. Field/visual caps and per-boss hit intervals prevent overlapping fields from producing uncontrolled damage.

## Movement, combat and presentation

- Fixed XP appearing to stop dropping during large hordes. At the 800-gem cap, two old distant gems now combine and a fresh gem appears at the new kill. Total XP is preserved; a gravity pickup still collects all banked XP.
- Bosses use run-time milestones at 5:00, 10:00 and 15:00, rather than resetting a five-minute clock after each portal. Late entry grants 45 seconds of preparation. You must enter the next biome through its portal. The HUD now shows the next boss countdown.

- Enemy bodies collide and separate using a bounded spatial contact solver. Dense packs spread and compress around obstacles instead of sharing one point. Contact searches are staggered; minor temporary overlap remains possible in large packs.
- Eight-direction navigation and direct pursuit across open ground replace four-direction stair-stepping. Flyers still cross terrain but collide with other creatures.
- Venom spitters wind up and fire bright, straight-moving projectiles. Sidestep them or use rock cover. They no longer place green damage circles under the player.
- Frozen creatures receive a faceted blue ice coating and frost crystals. They stop walking, stop bobbing, and resist displacement until thawing. Bosses retain their freeze resistance.
- Winterglass has shimmering trails, glassy attack cracks and brittle impacts. Lightning chains reveal successive jagged arcs with electrical crackles. Thunderstorm adds descending bolts, a rotating field and thunder impacts.
- Weapon transients were tightened, short reflections replaced long rapid-fire echoes, and strong casts briefly lower music slightly to preserve attack clarity.

Design reference: the user's [Vampire Survivors weapon wiki](https://vampire-survivors.fandom.com/wiki/Weapons), [evolution/union rules](https://vampire-survivors.fandom.com/wiki/Evolution) and [Santa Water](https://vampire-survivors.fandom.com/wiki/Santa_Water). Names, combinations, gameplay implementation, artwork and synthesized audio in this game are original.

Existing permanent progression loads unchanged. Start a new run in the new executable for this ruleset. Local daily records are tagged 0.5.
