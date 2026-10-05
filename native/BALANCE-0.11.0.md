# Fortune and Fang — reward balance

## Inventory and compatibility

Five weapons; eight distinct passive/augment types combined; eight distinct relic types. Each relic type accepts ten copies, even when all unique slots are occupied. Relics do not occupy passive slots. A chest first checks eligible rank-10 evolutions/unions (both union ingredients still require rank 10), then compatible, unlocked relic copies, then owned rank refinements; exhausted builds receive supplies. Tier is independent of identity. No ninth distinct relic is silently awarded. Additive percentages use fractions internally: two +10% XP copies mean +20%, not ×1.1×1.1.

Tier stacks are run state, not a new mid-run save feature. Legacy ID-only inventories are interpreted as one original-strength copy; old records retain their relic ID arrays. New reports additionally contain `relic_stacks` and `reward_schema: 2`. Profile format, unlocks, purchases, records and Halloween preference remain compatible. Fixture tests do not edit the player's real profile.

## Tier tables

| Per copy / chest | Common | Uncommon | Rare | Epic | Legendary | Artifact |
|---|---:|---:|---:|---:|---:|---:|
| Base tier chance | 40% | 30% | 18% | 9% | 2.7% | 0.3% |
| Amber Lens XP | 5% | 7.5% | 10% | 15% | 20% | 30% |
| King of Nothing score, XP, future horde HP | 5% | 7.5% | 10% | 15% | 20% | 30% |
| Mammoth Wrap HP + heal | 10 | 15 | 20 | 30 | 40 | 60 |
| Shell HP + heal | 15 | 20 | 30 | 40 | 55 | 75 |
| Shell armor | 1 | 1 | 2 | 2 | 3 | 4 |
| Prism extra projectile/chain/strike | 1 | 1 | 1 | 2 | 2 | 3 |
| Guard interval (seconds) | 40 | 35 | 30 | 25 | 20 | 15 |
| XP vacuum interval (seconds) | 30 | 26 | 22 | 18 | 15 | 12 |
| Moving wake interval (seconds) | 6 | 5.5 | 5 | 4 | 3.5 | 3 |
| Heal per 30 kills | 2 | 3 | 4 | 6 | 8 | 12 |
| Critical arc damage fraction | 15% | 20% | 25% | 35% | 45% | 60% |
| Fire burst damage per 18 kills | 25 | 35 | 45 | 60 | 80 | 120 |
| Chest refinement ranks (remaining ranks limit) | 1 | 1 | 2 | 2 | 3 | 4 |
| Exhausted chest amber | 25 | 35 | 50 | 75 | 100 | 150 |
| Exhausted chest healing | 15 | 20 | 25 | 35 | 45 | 60 |
| General power factor | .35 | .50 | .75 | 1.00 | 1.35 | 2.00 |

General factor multiplies the following per-copy bases; acquire HP is rounded to whole points. Other percentages remain precise, with the UI rounding to one decimal place.

| Relic ID | Base at factor 1 |
|---|---|
| flint | +10% all damage |
| coil | +12% attack speed |
| glass | +30% damage, +20% damage taken |
| frost | +25% damage against chilled/frozen enemies |
| branch | +30% fork chance |
| laststand | +50% attack speed below 35% HP |
| momentum | +5% damage per second moving, up to eight seconds |
| apex | +15% damage and +20 maximum HP per boss killed |
| chronicle | +45% damage, +20% attack speed, +40 maximum HP/healing |
| volley | +5 shots on every fifth projectile cast, rounded to whole shots |
| cyclone | Full-circle melee every round(3 / power) casts, minimum two |
| shatter, wildfire | Status-kill explosion: 65% of prey's maximum HP × power |
| reaper | Critical kill reduces active cooldowns by .15 seconds × power |
| garden | Aura-kill growth: .2% per kill × power, cap +65% × power |

King's HP cost affects future ordinary, elite and summoned enemies through their shared spawn path. It never retroactively heals existing enemies and never scales boss HP. Lens and King each cap at +300% XP from ten Artifact copies; owning both yields +600% additive XP. Combat still pays finite XP, and rewards require successive level thresholds.

## Proc and timer limits

Repeated copies feed one trigger per identity. Proc power sums factors but caps at 3. Status burst damage caps at 100% prey HP and 350 damage; queue caps at 32; proc kills cannot create new status bursts. Critical cooldown reduction caps at .3 seconds with a .3-second trigger cooldown. Healing has a two-second cooldown and caps at 30 per proc; fire bursts cap at 350 damage. Bonus volleys and weapon count obey the existing twelve-projectile ceiling.

Relic totals cap extra count at +4, fork chance at 85%, critical arc at 150%, low-HP haste at 150%, damage per boss at 45%, and health per boss at 60. Garden remains capped at +65% radius. Best timer tier is divided by `1 + .12 × additional copies`, with floors of 10 seconds for guard, 6 for XP vacuum and 1.5 for moving wake. No stack multiplies the number of event callbacks.

## Odds and randomness

Weight for tier index 0–5 is `base_weight × (1 + luck)^tier`, normalized to 100%. Luck equals passive Luck rank × .1 plus permanent and stage Luck. At .5 Luck, chances become 23.28 / 26.19 / 23.57 / 17.68 / 7.96 / 1.33%. After four Common/Uncommon rolls, the next rarity roll excludes those two tiers and normalizes Rare through Artifact; rolling Rare or better resets this protection. Thus baseline weights are not the long-run distribution with protection enabled.

All eligible identities support every tier. Inventory composition affects the identity pool, not tier availability. Exhausted chests use the same tier roll for their rank/amber reward. Evolutions are guaranteed eligible transformations, not a fake random rarity roll. The reward payload carries identity, rarity, quantity, source and effects; refinements record actual remaining rank gain. Daily uses its dedicated reward RNG; reel decoration uses a separate visual RNG.

These are original tuning choices. The official [Megabonk description](https://store.steampowered.com/app/3405340/Megabonk/) documents randomized upgrade rarity and build synergies, which informed the principle. It does not publish these odds or stacking tables; no claim of identical balance is made.

## Travel targets

Actual starter Kael terrain movement at 30 Hz reaches first supplies in 18.3 / 19.4 / 19.9 seconds and farthest authored rewards in 60.8 / 66.5 / 71.0 seconds (Cradle / Frostbreak / Observatory). Combat detours add time. Every authored reward route was measured; detailed results are in `VALIDATION-MAP-0.11.0.md`. Dimensions are 44,000 × 38,000 world units, with authored points at 46% of source coordinates. Arena and attack dimensions stay intact. Display distance: 1 metre = 10 world units.
