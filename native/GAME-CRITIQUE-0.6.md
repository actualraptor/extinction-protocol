# Independent gameplay critique — baseline 0.5

Read-only review of the two attached concept documents, screenshots, run telemetry, and simulation/rendering code. Both concept files have identical SHA-256 hashes. Both reports describe the same 961.9-second, 51,008-kill victory; they must not be treated as independent playtests. Video playback was not reviewed by this critic.

## Highest priority: restore consequences without destroying the power fantasy

The early game already threatens this player: their health reached 11 at 177.63 seconds. The later game loses that pressure. They stood at the same recorded coordinate for roughly 24 seconds around 14:14–14:38 at full health while killing approximately 90 enemies per second. Raising all enemy health or damage would punish the successful early balance and inflate runtime.

Blood Chalice currently heals 4 every 30 kills with no time limit (`expedition.gd`, `kill`; `relic_system.gd`, blood mods). At 90 kills/second that is 12 health/second, before 1.75 regeneration/second. The final boss's first major strike dealt 66 damage at 918 seconds; health returned to full by 926. Two later 78-damage strikes were survivable too. Its 61.87-second defeat is not inherently too short; the problem is that mistakes are erased. Add a healing time budget, e.g. 4 health at most once per 2 seconds, and make the description explicit. Preserve kill-driven healing identity and early usefulness.

Outside-arena damage is `hurt(20*dt+8)` and then reduced by flat armor and invulnerability. At 30 Hz and high armor it becomes the minimum 4 damage per accepted hit, less than late sustain. It should be a deliberately timed boundary penalty with a clear warning, not a per-frame quantity passed through a contact-hit model. Do not make it an invisible unavoidable execution.

## Chest flood is a concrete reward-source bug

Apex Invasion requests 58 spawns/second for 32 seconds, with a 4.5% elite chance. Every elite drops a guaranteed chest. Before population limits this creates approximately 84 chests from one event, plus scheduled elites. Chest drops need source classification: scheduled hunt mini-bosses retain guaranteed rewards, event elites do not. A bounded event reward budget and a ground-chest cap prevent cascades without making early mini-bosses disappointing.

At eight relics, `open_choices(true)` changes its local `relic` flag to false. The same chest then becomes a three-card level-up, which explains both inconsistent presentation and missing chest percentages. Preserve chest context separately from reward type. Resolve one random eligible upgrade for a full satchel and show it on the reel. Show real upgrade-pool odds or explicitly state guaranteed transformation; never show relic rarity percentages for a different reward table.

The winning build filled all eight relic slots by 232.7 seconds. Its final relic set contains no legendary or artifact. A full satchel then cannot pursue later exciting tiers. Consider replacement choice on a genuinely higher-tier drop, or a clearly presented refinement system. Avoid silently deleting an existing relic or auto-replacing a build-critical rare. Luck upgrades after saturation must retain an actual benefit rather than becoming dead picks.

## Put a ceiling on overlapping multipliers, not on fun

Weapon rank growth already reaches 3.7× at rank ten. Evolution adds 1.85×, then `combat_engine.gd` doubles power again at rank ten. That is 13.69× base before damage passives, spell amplification, mage affinity, crits, count, area, and cooldown. The final-rank jump creates an abrupt cliff. Reduce that last generic multiplier and move reward into clear archetype behavior. Expose count, active-instance, duration and repeat-hit budgets in one stat contract, then enforce them in each executor.

Thunderstorm can have many long-lived overlapping fields: duration augments add seconds, evolution doubles strike frequency, and multiple zones repeatedly render three lightning bolts. Its gameplay and rendering budgets should be separate. Keep the powerful field mechanic while capping visible redundant bolts and same-target pulse frequency. Enemy count alone is a poor visual-quality throttle: a strong build clears the screen and still creates enormous spell overdraw.

Report damage shares were approximately Fire 39%, Whiteout 27%, Thunderstorm 19%; these are lifetime totals, not controlled DPS comparisons, because acquisition times differ. The new inspector should show recent effective DPS, total damage, and acquisition/active time, not present lifetime totals as a fair ranking. Count actual health removed, already supported, and preserve attribution after a union consumes its parents.

## Threat must always be readable above player spectacle

Reserve the strongest bright outlines and clear silhouettes for the player, hostile projectiles, boss windups, and safe gaps. Player spell interiors should dim near the player and during boss warnings; textured edges and short impact peaks can remain spectacular. Reduce redundant long-lived effects before shrinking all magic. Keep boss geometry visible above spell particles. A screenshot at maximum build must show the player, boss/anchors, and escape lane without hiding all weapons.

The HUD screenshot shows long weapon and relic strings wrapping into the XP bar. This is a fixed-layout ownership problem: five compact weapon slots should own their space; detailed stats and relic names belong in the inspector. Distinct icons must also distinguish base, evolved, and union states. Whiteout should visibly combine ice and lightning, with its parents named during the union reveal. Replace generic APEX labels with the actual name and rank/evolved state.

## Progression needs an adventure loop, not taxes

Use a small default mage kit, discoverable map landmarks, and affordable amber unlocks that introduce new behavior. Preserve already-owned content when migrating old saves. A fog-of-war map, edge arrows and landmark discoveries should agree on coordinates and discovery state. Locking a weapon must also remove incompatible passives and impossible evolution offers from early choice pools. Discoveries should persist immediately and be visible in the menu even if the expedition ends in death.

Do not implement every suggested archetype in one change. Establish truthful shared stats, terrain rules, finite spawn waves and a few behaviorally distinct unlocks; that provides a safe foundation for additional content. Bosses should test movement/build decisions with readable patterns, not only larger health pools. Early fun and satisfying mass kills are worth retaining.

## Acceptance evidence for the next pass

- A scheduled early mini-boss always drops its chest; the entire Apex event has a bounded chest budget.
- Full satchel chests still use the reel with truthful odds/context; none unexpectedly open three cards.
- A high-kill build cannot instantly heal a major boss mistake; an actively dodging strong build can still win.
- A maximum build screenshot leaves boss windups and the player readable; bottom HUD never overlaps XP at 1280×800 and 1920×1080.
- Fresh and migrated saves both retain valid unlock paths, with no lost permanent purchases.
- Recent DPS measures active effective damage and remains correct across unions and pauses.

## Follow-up source review of the in-progress 0.6 pass

The new source addresses the largest baseline failures: Blood Chalice now has a two-second recovery budget, event-elite chests have a 35-second gate and probability, the boundary uses deliberate timed damage, chest context survives a full satchel, and exploration discoveries are saved immediately. The compact HUD and ledger remove the original long-text collision. No obvious dead end was found in the starting mage's available weapon pool.

Actionable remaining issues found during this review:

1. **Automatic relic replacement can damage a build.** `open_choices` chooses the lowest rarity equipped relic and `choose` removes it without an alternative. Higher rarity does not guarantee better compatibility: a rare Glass relic imposes incoming damage and may replace an essential sustain or cooldown relic. The reveal calls it “A STRONGER RELIC”, which is not always true. Give a deliberate keep/salvage option or postpone replacement until a safe interaction exists. This does not require another confirmation popup; the landed reel can show the two actions.
2. **Refinement odds caption misdescribes the roll.** It says “LOWER-TIER DUPLICATES”, but `Relics.roll` explicitly excludes all already-owned relics. These are lower/equal-tier unowned rewards converted to refinements. Name that condition accurately. The displayed tier probabilities otherwise correspond to the sampled tier distribution, including content locks and pity.
3. **Consumed weapons' average DPS decays forever.** `CombatLedger.average` divides by current time since first cast, even after a union permanently removes the weapon. Its label is literal, but this makes historical comparisons misleading. Record retirement time for consumed weapons or label them as run-average history separately; recent DPS naturally returns zero and is fine.
4. **Old-content migration is narrow.** Existing recorded heroes remain available, and research/amber are retained, but previously usable optional weapons all become newly locked. This is a deliberate progression reset for content access, not preservation of every previously available build. Either explicitly document that distinction or grandfather returning profiles' content packs. Do not claim every prior unlock is retained if this behavior remains.

These are source-review findings, not claims of live playtesting. A comparison of maximum builds before and after the power reduction still needs runtime validation; changing many multipliers while reducing healing can swing difficulty sharply even though each individual change is reasonable.

## Final review update

All four findings from the previous follow-up are resolved in the reviewed source: replacement is optional on the landed reel (E equips; movement/Space preserves the current relic and salvages), the odds caption describes non-replacement finds, consumed weapons have retirement timestamps, and returning profiles with completed runs retain existing content access. Source also contains six timed wave events, bounded staggered projectiles, and cover-aware targeting. The parent developer reports passing native UI and controlled five-union damage comparisons; those results were not independently rerun by this critic.

Two material new-weapon issues remain in the inspected source:

- **Dead Pierce upgrades:** Prism Skipper and Sun Chaser carry PROJECTILE and qualify for Through and Through, but their executors force pierce to 1 and 8 respectively (with Sun Chaser resetting to 8 on return). A build containing only either weapon can spend ranks on no effect. Honor the stat where appropriate or exclude incompatible archetypes from the upgrade filter.
- **Sun Chaser return behavior:** its evolution promises a stronger second pass but currently only clears hit history/resets pierce when returning, without applying a return damage bonus. Homing also runs after return-to-owner steering, allowing a purchased tracking upgrade to pull a returning crescent back toward enemies. Apply the promised one-time return bonus and prioritize owner steering during the return leg.

No other new release-blocking logic defect was identified in this limited final source review. This is not a claim that the whole game is defect-free or that one controlled DPS comparison establishes encounter balance.

## Release resolution
Both final new-weapon findings are resolved: Prism's ricochet archetype excludes incompatible Pierce offers, Sun Chaser honors Pierce on both legs, its evolution applies the promised one-time 1.25 return damage multiplier, and return-to-owner steering takes priority over Homing. The 43-check patch suite covers these interactions and passes.

