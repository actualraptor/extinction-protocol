# Measured compact stage travel

Fresh Kael (no research, no items), seeded terrain 81927, using actual terrain movement/collision at 30Hz and map speed modifiers; includes mud slowing if encountered. Movement-only isolated route measurement; combat and detours add time. Arena and attack ranges unchanged.

| Map | Objective | Terrain route time |
|---|---|---|
| cradle | speed | 18.3 s |
| cradle | regen | 32.0 s |
| cradle | armor | 49.3 s |
| cradle | crit | 60.4 s |
| cradle | vesper | 44.9 s |
| cradle | mara | 54.0 s |
| cradle | ironbriar | 33.3 s |
| cradle | ballistics | 26.7 s |
| cradle | tracking | 46.9 s |
| cradle | ancients | 52.4 s |
| cradle | alchemy | 58.0 s |
| cradle | myths | 60.8 s |
| cradle | heartwood_cache | 42.8 s |
| cradle | caldera_cache | 56.2 s |
| cradle | cursed_reliquary | 26.2 s |
| cradle | ancient_forge | 44.5 s |
| frostbreak | pickup | 19.4 s |
| frostbreak | haste | 28.9 s |
| frostbreak | area | 48.0 s |
| frostbreak | regen | 59.0 s |
| frostbreak | iona | 34.9 s |
| frostbreak | glacier | 42.9 s |
| frostbreak | fracture | 47.1 s |
| frostbreak | sundial | 66.5 s |
| frostbreak | blue_cache | 39.9 s |
| frostbreak | aurora_cache | 60.0 s |
| frostbreak | cursed_reliquary | 33.8 s |
| frostbreak | ancient_forge | 46.7 s |
| observatory | luck | 19.9 s |
| observatory | damage | 32.0 s |
| observatory | count | 50.9 s |
| observatory | armor | 62.6 s |
| observatory | orin | 71.0 s |
| observatory | riftcraft | 34.9 s |
| observatory | sunbow | 56.0 s |
| observatory | prismwork | 53.8 s |
| observatory | chronicle | 68.2 s |
| observatory | meridian_cache | 39.8 s |
| observatory | star_cache | 60.6 s |
| observatory | cursed_reliquary | 29.2 s |
| observatory | ancient_forge | 46.7 s |

Navigation changes: local player-centered view on opening; O/full-overview and F/recenter controls; middle-drag pan; cursor-anchored zoom; sampled obstacle/mud/lava context and authored route lines; collision-suppressed objective labels; independently reserved footer; fonts and icons scale with screen height. Map distance convention is explicit: 1 m = 10 world units. Whole-stage dimensions now 44,000 x 38,000 units; authored objectives use 46% source coordinates; arenas, weapon reach and boss mechanics retain their dimensions.

Headless checks: continuous_terrain 15; stage_objects 29; stage_atlas 42; harvest_progression 34; map_navigation_compact 69; map_travel_audit 53. All pass. Legacy atlas assertions explicitly request overview rather than relying on its old default. The travel probe includes all authored rewards at all biome depths; it does not simulate combat detours. Integrated rendered screenshots are reviewed separately by the root task.

Legacy frontier suites were also run: frontier_routes_07 reports 14/22 failures; frontiers_07 reports 8/70 failures. These are stale assertions: discovery BFS is limited to +/-30 cells (1,920 world units), while authored discoveries have deliberately been farther away since 0.9.2; frontier_routes also requires the removed shared boss pattern to create exactly two or three hazards. Those assertions were not silently weakened. Current continuous authored route and actual terrain movement probes cover every map's current objective geometry; unique boss tests belong to the boss suite.
