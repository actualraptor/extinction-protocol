# EXTINCTION PROTOCOL — 0.8: IRON & THUNDER

## GENERAL

- Weapon capacity remains **5 slots**.
- Added **Ironbriar**, bringing the arsenal to **23 base weapons and 6 unions**.
- Added destructible bone urns, fossil crates and egg nests throughout the maps.
- Starting spawn rate reduced by **35%**, gradually returning to normal over the first **120 seconds**.
- Added rotated, mirrored and alternate district layouts, broken formations and additional map decoration.

## HEROES

Bonuses below are gained through character levels. Damage/speed traits begin after level 1; existing starting bonuses remain.

**MARA VOSS**
- Gains **+1 projectile every 10 levels**, up to **+3**.
- Applies to projectile weapons, not chains or ground strikes.

**KAEL**
- Gains **+1% physical damage per level**, up to **+50%**.

**VESPER**
- Gains **+1% spell damage per level**, up to **+40%**.
- Retains his existing spell specialization.

**IONA**
- Gains **+0.5% movement speed per level**, up to **+15%**.

**ORIN**
- Gains **+0.5% arcane attack speed per level**, up to **+20%**.

## WEAPONS

**STORMBINDER**
- Gains an additional natural chain target at weapon ranks **5 and 10**.
- Base target count progresses **3 → 4 → 5**, before build bonuses.

**EXTINCTION MORTAR**
- Shells now launch from the survivor and follow a visible upward arc.
- Explosions occur on landing, not during flight.
- The same trajectory treatment applies to its bombardment union.

**IRONBRIAR — NEW WEAPON**
- Releases automatic thorn bursts and retaliates when struck.
- Base damage: **25**. Base cooldown: **2.4s**. Base radius: **115**.
- Gains **+4 base damage per armor**, up to **25 armor**, before ordinary weapon scaling.
- Retaliation deals **80%** of current burst damage.
- Retaliation cooldown: **40% of attack cooldown**, minimum **0.65s**.
- Tags: **Physical, Area, Defensive, Retaliation, Knockback, Critical**.
- Does not consume the offensive aura allowance.
- Unlock: **800 lifetime expedition kills**, or discover its signal in the Lost Cradle.
- Added to Kael's available kit once unlocked.

**HARDENED SPINES — NEW AUGMENT**
- **+25% thorn damage and +15% thorn radius per rank**. Maximum **3 ranks**.

**QUICK RETORT — NEW AUGMENT**
- **+15% thorn attack speed per rank**. Maximum **3 ranks**.

**IRONBRIAR BUILD**
- Kael / Ironbriar / armor / Hardened Spines / Quick Retort.
- Add Ancestor's Wrath for the union. Health and regeneration support close-range play; crit and area improve the bursts.
- Armor conversion and retaliation frequency are bounded. Taking damage is a bonus trigger, not a requirement to attack.

## EVOLUTIONS

- Solo evolution: **rank-10 weapon + relic chest**. Removed passive-rank requirements.
- Union: **one rank-10 weapon + its compatible partner at any rank + relic chest**.
- Unions consume both ingredients and free **1 weapon slot**.
- Eligible unions take priority over solo evolutions.

| Ingredients | Union |
|---|---|
| Stormbinder + Winterglass | WHITEOUT |
| Cinder Gospel + Extinction Mortar | SUPERNOVA |
| Graveshot + Bone Rattler | THE LAST WORD |
| Ancestor's Wrath + Epoch Lance | EARTHSHAKER |
| Rift Blades + Prism Aegis | RIFT BASTION |
| Ironbriar + Ancestor's Wrath | IRONBRIAR KING |

**IRONBRIAR KING**
- Base damage **48**, cooldown **1.8s**, radius **155** before rank/build scaling.
- Retaliation deals **115%** of current burst damage.
- Retains armor scaling and adds stronger radial coverage.

## CRITICAL STRIKES

- Critical chance can now exceed **100%**.
- Each full 100% guarantees one critical tier; the remainder rolls for one additional tier.
- **250% effective crit = guaranteed double crit + 50% chance of triple crit**.
- Damage multiplier: **1 + 0.9 × critical tier**. Single/double/triple crits deal **1.9× / 2.8× / 3.7×** damage.
- Raw crit gains have diminishing returns: first 100 points at **100% efficiency**, next 100 at **65%**, next 200 at **40%**, further gains at **25%**.
- Backpack displays effective chance. Upgrade cards show the actual gain.
- Critical passive maximum increased **5 → 60 ranks** for extreme builds.
- Added small gold sparks and marked damage numbers. Visual tier markers cap at three; actual damage does not.

## ENEMIES & BOSSES

- Charging enemy population limited to **5 / 6 / 7** by biome depth.
- Added a shared charge windup interval of **1.15 / 1.00 / 0.85 seconds** by depth.
- Excess charger spawns become other local species, including scheduled hordes.
- Small enemies are displaced outside boss bodies.
- Bosses render above ordinary swarms and friendly effects.
- Boss bars now display **current HP / maximum HP**.

**POST-BOSS PRESSURE**
- Added **20 seconds** of post-boss looting grace.
- After grace, newly spawned enemy health **doubles every 25 seconds**.
- Incoming non-piercing damage gains **+100% every 25 seconds** after grace, including attacks from enemies already present.
- Spawn pressure increases up to **6×**; new enemy movement increases up to **2×**. Population safety limits remain.
- Elite intervals shrink toward **8 seconds**.
- At **2 minutes** after the boss: new enemies have **16× HP** and incoming damage is **5×**.
- Pressure continues rising beyond the old plateau. The portal stays open and crossing it clears lingering pressure.
- Added a warning when grace ends and live HP/damage multipliers in the rift HUD.

**EXTINCTION ENGINE — TIMED DEFEAT**
- Reaching its existing **210-second** limit now triggers a **5.2-second ending sequence**.
- Meteor expansion, fiery screen-wide shockwave, bass impact, music ducking, darkness, then the scoreboard.
- Screen shake follows the player's setting. Ordinary deaths still show results immediately.

## BREAKABLES

| Drop | Chance |
|---|---:|
| Amber cache (+8 amber) | 70% |
| Health pickup | 20% |
| XP magnet | 5% |
| Freeze / frenzy / surge / nuke | 1.25% each |

- Breakables do not award kills or XP.
- Automatic targeting prioritizes hostile enemies; props become targets when no hostile is available.
- Area attacks and projectile collisions can still destroy props during combat.
- Local prop and pickup limits protect performance. Amber is banked directly if the pickup pool is full.

## THE ARCHIVE

Expanded permanent research from **3 → 14 tracks**. Costs below are first-rank prices; subsequent prices scale by **1.65×** per rank.

| Research | Bonus per rank | Max ranks | Starting amber |
|---|---|---:|---:|
| Hunter's Eye | +2 raw crit points | 10 | 200 |
| Survivor's Blood | +10 health | 5 | 70 |
| Forbidden Knowledge | +3% damage | 5 | 100 |
| Scavenger's Legacy | +5% amber and luck | 5 | 80 |
| Second Thoughts | +1 starting reroll | 5 | 180 |
| Lucky Fossil | +1% luck | 10 | 120 |
| Full Magazine | +1 projectile | 2 | 1,800 |
| Storm Memory | +1 chain target | 2 | 2,000 |
| Refuse Extinction | One revival at 50% HP, 3s immunity | 1 | 3,000 |
| Amber Prospector | +5% amber | 8 | 100 |
| Ancient Insight | +3% XP | 8 | 120 |
| Gathering Instinct | +12 pickup radius | 8 | 90 |
| Fossil Plating | +1 armor | 3 | 220 |
| Living History | +0.15 HP/s regeneration | 4 | 240 |

- Existing purchases and progression are preserved.
- Rebuilt Archive layout as a compact grid with a fixed footer.
- Fixed the Main menu button accepting mouse input.

## DAILY EXPEDITION

- Date now determines the survivor, map and five-weapon build.
- Levels **2–5** automatically grant the remaining weapons.
- Later levels improve the lowest-rank owned weapon; from level **15**, grant up to **2 ranks**.
- Every third level grants a scheduled passive upgrade.
- Chests follow a fixed relic order or award an eligible evolution.
- No gear-choice pauses, rerolls or permanent research bonuses.
- Records remain local to this computer; there is no online leaderboard.

## UI & AUDIO

- Simplified upgrade wording and added icons for currently owned weapons affected by each upgrade.
- Armor upgrades explicitly identify Ironbriar as an affected weapon.
- Added painted fossil-and-metal HUD plates, upgrade frames and a skull-framed scoreboard.
- Scoreboard includes run metrics and a weapon damage/share table.
- Fixed the HUD size preference; verified small and large settings and ultrawide layout.
- Repositioned boss headings to avoid score/HUD overlap.
- Added **29 original weapon/impact/breakable sounds** with distinct gun, frost, lightning, fire, melee and arcane treatments.
- Glacier Wheel now uses icy transient layers instead of the old alarm-like tone.
- Dense combat attenuates overlapping sounds to preserve definition.
- Existing nine map/biome music arrangements remain in this release.

## FIXES

- Breakables respect the total enemy budget.
- Corrected prop variation selection so urns, crates and nests can all appear.
- Amber drops now use amber artwork instead of chest artwork.
- Daily results return to today's fixed build rather than unrestricted survivor selection.
- Save purchases, evolution slot rules, boss visibility, mortar landing damage and multi-crit probability covered by regression checks.

## DESIGN REFERENCES

Progression and evolution readability informed by [Vampire Survivors weapons](https://vampire-survivors.fandom.com/wiki/Weapons), [passive items](https://vampire-survivors.fandom.com/wiki/Passive_items), and [Reroll](https://vampire-survivors.fandom.com/wiki/Reroll), with build variety inspiration from [Megabonk](https://store.steampowered.com/app/3405340/Megabonk/). Assets and audio were authored for this game; no reference-game sound recordings were imported.
