# 0.13.0 — Current playtest

The new HUD is a first iteration and will have layout, scaling and visual issues. See [release notes](RELEASE-0.13.0.md).

# Extinction Protocol — native Windows edition

A playable Godot 4.7.2 migration of Extinction Bloom, rebuilt around human survivors. Release 0.8 adds armor-scaling thorns, hero level traits, multi-crits, expanded permanent research, automatic daily builds, destructibles, stronger post-boss pressure and an animated extinction defeat. See RELEASE-0.8.md. The old browser game remains in the parent folder.

## Play

Extract the Windows ZIP and double-click **Extinction Protocol.exe**. No browser, npm, engine installation, account, or connection is needed. Windows x64, OpenGL 3.3 or better.

- WASD or arrows: move; attacks aim and fire automatically.
- 1/2/3 or mouse: choose an upgrade. R rerolls (three charges, boss kills restore one). Relic reels wait for a fresh movement, Space or Enter press.
- Tab (or M): live transparent map overlay. B: backpack, stats and damage. Escape: pause. F11: fullscreen.
- Hover equipment icons for names and descriptions. Settings includes a HUD size slider. Health is below your character.
- On a full-satchel relic replacement reveal: E equips the new relic; movement/Space/Enter keeps the current one and salvages the find. Other reels keep the normal fresh-key claim.
- **Meteor trial** starts the final encounter with a prepared evolved build. Practice does not award currency or records.

## What's playable

- Mara Voss, a gunslinger; Kael, a Neanderthal hunter; Vesper, an elemental mage; Iona, a polar hunter; Orin, an arcane astronomer.
- Twenty-three base weapons/spells with ten ranks and chest evolutions, plus six two-weapon unions that free a slot.
- Ten global passives, seventeen tag-compatible augment tracks and twenty-six relics. Carry five weapons/spells and eight relics; further caches offer refinements or optional replacement relics.
- Discovery sites and cumulative kill/boss milestones unlock maps, equipment and survivors. Fresh profiles begin with the mage; returning players retain their original catalog. New Prism Skipper and Sun Chaser discoveries are available to both.
- Three biome depths linked by walk-in boss portals, eighteen enemy species, mutations, elites, two gate bosses, and the Extinction Engine.
- Approximately five minutes per biome before its boss, with extra time for boss fights and optional post-boss looting. Death/restart, victory, pause/settings, native saves, permanent research, local records, and a seeded daily challenge.
- Original generated character, terrain and prop assets, animated fire/ice/lightning impact sheets, textured spell projectiles, runic level-up/evolution bursts, GPU particles, glowing blade trails, illustrated chests/shrines/anchors, camera shake, screen shaders, synthesized effects and adaptive procedural music.
- Exported native executable with assets embedded. No JavaScript or web view inside the game.

## New in 0.6.2

Ultrawide gameplay fills the screen. Weapons sit bottom-left; buffs and upgrades sit top-right. B opens a single-screen Attack / Defense / Utility backpack. Tab uses an unframed transparent terrain overlay. See RELEASE-0.6.2.md.

## New in 0.6.1

See RELEASE-0.6.1.md for the compact HUD, discovery guidance fixes, live overlay map and character health bar.

## New in 0.6

See [release notes](RELEASE-0.6.md) for exploration, discoveries, map/DPS controls, the new weapons, safer loot choices, union corrections, music and balance changes.

## New in 0.5

See [release notes](RELEASE-0.5.md) for all recipes, chest odds, luck, Thunderstorm, enemy collision and freeze changes.

## New in 0.4

See [release notes](RELEASE-0.4.md) for the backpack, rerolls, collision fix, thermal shock, rarity tiers, original music and weapon audio.

## New in 0.3.1

- Fixed upside-down ordinary enemies in the GPU swarm renderer.
- Jewel-blue, twenty-segment XP bar with a brass frame, XP counts and gain glow.
- Painted four-frame walk cycles for all three survivors, with front, back and mirrored side views. Movement distance controls cadence; idle retains facing and pause freezes the pose.
- Removed text labels from mud and lava. Their painted terrain communicates their identity.

## New in 0.3

- Projectile speed/piercing/homing/ricochets, melee reach/echo strikes, chain forks/rechains, aura pulses, lingering bombardments, barrier recharge and time-control duration follow tags. Incompatible options are excluded.
- Rank 5/7/9 milestones expand attack behavior. In 0.6 rank 10 adds a 20% mastery bonus instead of doubling power. Evolution becomes available at rank 8 plus the linked passive at rank II.
- Relic triggers include fifth-attack volleys, third-attack full-circle melee, frozen shatters, spreading fire, growing auras, critical-kill cooldown refunds, low-health haste, movement momentum and boss growth. Trigger cooldowns and bounded proc queues prevent runaway recursion.
- Seven rare collectibles: time freeze, global magnet, healing, nuke, frenzy, immunity and doubled XP. Timed buffs are visible on the HUD. Bosses resist freeze and nukes.
- Painted rock/ruin/basalt ridges block movement, mud slows and lava damages. Open roads and clearings remain connected. Flyers bypass terrain; ground enemies share a flow field. Boss arenas clear nearby obstacles.
- Warnings precede events at 2:30, 7:00 and 12:00. The 7-minute horde emphasizes weak enemies and XP rather than inflated health. Population is bounded at 2,200 during that event.
- Animated chest anticipation, illustrated relic reveals, automatic reward collection, tag-labelled animated upgrade cards and distinct pickup sounds. In 0.5, landed rewards wait for a fresh key press.
- Regular enemies use one GPU MultiMesh batch. Expensive decorative status effects, damage numbers, projectiles, XP entities and proc queues are bounded. Combat uses a fixed 30 Hz simulation with independently rendered effects and a smoothed camera.

## The extinction fight

The Basalt Behemoth at ten minutes now breaks its carapace at half health. Its temporary molten armor protects the transition while it telegraphs crossing attack lanes.

The meteor has 6,000,000 core health and three orbital anchors. While anchors survive it takes 12% damage. Breaking all three opens the core for 12 seconds. It reforms at 67% and 34% health; excessive burst damage cannot skip these gates. Unfinished windows regenerate the anchors. Blood Chalice's healing has a two-second trigger cooldown; outside-arena damage bypasses flat armor.

Coronal flares leave dodge lanes, bombardments mark their impact zones, and concentric shockwaves fire in staggered pulses. Phase two and three overlap additional hazards. Remaining outside the 720-unit arena is dangerous. The meteor enrages at 150 seconds and finishes extinction at 210 seconds.

This is intentionally an extreme build check. Balance is an initial tested baseline, not a claim that all builds or skill levels have been calibrated. The controlled balance test gives both pilots invulnerability to isolate damage throughput: the mediocre build times out; the fully evolved build wins. Actual play must also survive the attacks.

## Saves and reports

Godot stores progress in `%APPDATA%/Godot/app_userdata/Extinction Protocol/`. Completed runs write JSON into `reports/`; the summary can open this folder. Progress uses a temporary file plus a previous-save backup. Version-one saves gain discoveries, unlocks and recipe records without resetting currency or research. Existing banked runs grant legacy equipment access. Browser progression is not imported because the characters and balance have changed. Supplied personal run reports and recordings are not included in the distributable.

## Develop

Open `project.godot` in Godot **4.7.2** and press F6/F5. The downloaded portable editor is in the workspace's `tools/godot/` directory. No external code dependencies.

- `scripts/combat_rules.gd`: tags, compatibility filters, ten-rank stats and augment definitions.
- `scripts/combat_engine.gd`, `chain_system.gd`: reusable delivery behaviors, delayed repeats, zones and bounded chains.
- `scripts/relic_system.gd`: declarative relic modifiers, cast rules and kill hooks.
- `scripts/terrain_map.gd`, `horde_director.gd`, `world_pickups.gd`: terrain/navigation, timed density events and collectible effects.
- `scripts/swarm_renderer.gd`: GPU-batched ordinary enemies.
- `scripts/catalog.gd`: character, weapon, relic, biome, and research definitions.
- `scripts/expedition.gd`: deterministic fixed-step simulation, spatial hash, bounded swarms, upgrades, boss state machine, telemetry.
- `scripts/world.gd`: camera-relative 2D rendering, sprite atlas, GPU particles and bounded transient effects.
- `scripts/spell_fx.gd`: textured weapon trails and crossfaded impact animation sheets.
- `scripts/readability.gd`: danger markers, survivor silhouette and priority numbers above the spell layers.
- `scripts/main.gd`: native menus, input, HUD, progression, settings, and reports.
- `scripts/discoveries.gd`, `expedition_map.gd`, `navigation.gd`: unlock catalog, exploration map, optional waypoints and edge guidance.
- `scripts/combat_ledger.gd`: bounded effective-damage telemetry and retired-weapon history.
- `scripts/atlas_icons.gd`, `hostile_fx.gd`: distinct item illustrations and priority textured attack warnings.
- `scripts/sound.gd`: sound synthesis, voice pool, and adaptive music.
- `shaders/atmosphere.gdshader`: screen atmosphere, damage vignette, and level-up flash.
- `shaders/spell_glow.gdshader`: additive luminosity and atlas edge masking for spell art.
- `tests/run.gd`: simulation and accelerated full-expedition integration checks.
- `tests/boss_balance.gd`: mediocre versus fully evolved build test.

From the repository root in PowerShell:

```powershell
& tools/godot/Godot_v4.7.2-stable_win64_console.exe --path native --editor
& tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path native --script res://tests/run.gd
& tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path native --script res://tests/boss_balance.gd
& tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path native --export-release "Windows Desktop"
```

The supplied export preset points at portable templates in the workspace. On another machine, install matching Godot export templates and clear the custom-template paths in Export settings.

## Production work still ahead

The characters currently use illustrated sprite poses with procedural movement, not complete hand-authored walk/attack animation sets. Audio is synthesized, not a studio sound library. Distinct terrain sets, authored animation, deeper item interactions, more environmental objectives, accessibility options and extensive human balance testing are the next production passes. Online leaderboards, controller support, recording, and browser-save migration are not included in this native release.

See `BALANCE-REVIEW.md` for the original run diagnosis and `assets/PROVENANCE.md` for asset prompts and provenance. Godot's license is included with the Windows package.


## Validation

See `VALIDATION-0.3.md` for measured stress results and test limitations. `tests/systems.gd` exercises new mechanics, `tests/presentation.gd` checks native UI/save/restart behavior and captures screenshots using an isolated test save, and `tests/progression.gd` builds from ordinary level-up offers. The damage-throughput pilots are invulnerable by design; their wins do not prove that dodging the boss is easy.
