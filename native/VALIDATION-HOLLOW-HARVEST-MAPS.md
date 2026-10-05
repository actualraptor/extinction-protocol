# Hollow Harvest map and progression validation

Validated locally on 2026-10-05 with Godot 4.7.2 headless. No release uploaded.

## Player changes

- All authored maps are 20% smaller along both axes. Authored reward and landmark routes are 25% shorter; region radii shrink 15% to preserve broad combat spaces.
- First supplies are within 5,000 units of spawn. At least one first-biome unlock lies within 8,000 units on every map.
- Each map adds a Cursed Reliquary with eight guardians and an Ancient Forge with five. Approaching starts one bounded pack; defeating it permits collection. Reliquaries use the normal chest flow. Forges improve the strongest unfinished weapon by one rank, capped at ten; a complete arsenal receives 40 amber instead.
- Ancestor's Wrath damage can unlock Ironbriar (60,000), Graveshot damage can unlock Lost Ballistics (100,000), and Stormbinder damage can unlock Riftcraft (180,000). Existing kill milestones and found signals still work; previously owned content remains owned.
- Campaign tracking exposes up to three map-relevant goals, supports one saved tracked goal, and excludes completed unlocks.
- First discoveries add a capped recovery reward of 12% maximum health, up to 18 health, alongside the existing 20 amber.

## Checks

- `tests/continuous_terrain.gd`: all 15 checks passed; authored routes remain walkable and all objective spacing validates.
- `tests/stage_objects.gd`: 29 checks, zero failures; guarded rewards, bounded packs, forge cap, amber fallback and existing collection behavior.
- `tests/harvest_progression.gd`: 34 checks, zero failures; old campaign migration, alternate unlocks, idempotent rewards, goal tracking, smaller bounds and capped discovery healing.

## Integration contract

Call `Campaign.record_build(profile,sim.report())` once at expedition end, before evaluating and saving final unlocks. Do not call it repeatedly during a run. Daily does not add permanent progression.

Campaign's optional `weapon_damage` and `survivor_runs` dictionaries hold numeric values. Profile validation should reject malformed values while preserving these dictionaries on updates.

Enemies marked `encounter_guard` must be exempt from ordinary distance-based despawning. Otherwise leaving and returning could count despawned guards as defeated. Discovery touch handling calls `Discoveries.field_reward` once for a newly found signal.

The encounter art currently uses the existing cache artwork. World/map presentation should label active guardians and identify the Ancient Forge before activation; the mechanics deliberately avoid spending amber automatically.
