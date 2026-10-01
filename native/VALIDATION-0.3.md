# Extinction Protocol 0.3 — validation

Tested on 2026-09-30 with Godot 4.7.2, Windows x64, GL Compatibility, NVIDIA RTX 5070 Ti. The exported executable was also launched independently of the editor with all assets embedded.

## Automated results

| Suite | Result |
|---|---|
| `tests/systems.gd` | 124 checks, zero failures |
| `tests/run.gd` | 43 regression/integration checks, zero failures |
| `tests/presentation.gd` | Nine native UI/save/restart assertions, zero failures; screenshots inspected |
| `tests/opening.gd` | All three survivors complete 60 seconds without invulnerability |
| `tests/progression.gd` | Starts from level one, selects ordinary generated offers, reaches level 79 and wins at 15:47.9 |
| `tests/boss_balance.gd` | Weak build loses at 210 seconds; prepared evolved build wins in 68.8 seconds |
| Exported Windows build | Launches, loads embedded assets, renders the meteor encounter, captures a frame, exits cleanly; no script errors or leaked-object warnings |

The 43-check full expedition simulates 941.8 seconds, records 42,541 kills and a peak of 1,970 enemies, reaches every biome, and wins the final encounter in 41.8 seconds. Its pilot starts with a prepared maximum-rank build and also collects upgrades during the run.

The progression pilot starts with normal equipment and no permanent research. Its final build has five evolved weapons, eight relics and earned tag augments. Its boss fight times were 7.5, 4.7 and 47.8 seconds. The second boss's carapace gate prevents skipping its molten second phase even with extreme burst damage.

**Balance-test limitation:** the full-expedition, progression and isolated boss pilots use invulnerability to measure attainable progression and damage throughput. They do not establish human dodge difficulty or a guaranteed win rate. The opening-minute test does not use invulnerability: Mara finishes with 54 HP/80 kills, Kael with 130 HP/120 kills, and Vesper with 69 HP/84 kills. Its pilot collects XP, avoids nearby enemies and steers around obstacles.

## Performance

- Simulation-only stress: 2,200 ordinary enemies, navigation, spatial grid and event updates; approximately **8.4 ms mean / 18.1 ms worst** over 120 ticks in the final systems test. No weapons in this isolated benchmark.
- Extreme rendered stress: 2,200 artificially durable creatures with four maximum-rank weapons, sustained status effects and no mass deaths. In live fixed-step gameplay, **22.0 ms median / 31.9 ms p95**, with the engine reporting approximately **44 FPS**. Window: 1280×800; logical viewport: 1440×900. This is deliberately harsher than the weak-enemy event and is not a claim of locked 60 FPS.
- Batching reduced the earlier rendered stress median from 58 ms to roughly 21 ms in the coroutine-driven comparison. Live gameplay is reported separately above.
- Actual event enemies are much weaker and die in large groups. Population caps, merged XP, pooled audio/GPU particles, shared navigation, a GPU swarm batch, bounded projectile/effect counts and bounded proc queues keep growth controlled.

## Coverage

All content is tagged. Tests cover incompatible upgrade exclusion; all fifteen attack/support behaviors; rank/evolution offers; projectile modifiers; chains and their work limits; aura damage, stacking poison and non-refreshing DOT; barriers; utility effects; relic synergies and trigger cooldowns; the eight-relic limit; all seven pickups; global magnet attraction; boss freeze/nuke resistance; terrain blocking, anti-tunnelling, connected walkable space and shared routing; flyer exceptions; 2:30/7:00/12:00 events; 5/10/15-minute bosses; phase gates; level-up/chest confirmation; save compatibility; save backup; pause and restart.

Native presentation tests use `build/test-progress.json`, not the player's real save. Existing version-one amber, research and records remain compatible. Daily seeds and new records carry the 0.3 ruleset; older records retain their version label.

## Run the checks

Use the included project with the portable Godot executable in `../tools/godot/`, or another Godot 4.7.2 installation:

```text
godot --headless --path native --script res://tests/systems.gd
godot --headless --path native --script res://tests/run.gd
godot --headless --path native --script res://tests/opening.gd
godot --headless --path native --script res://tests/progression.gd
godot --headless --path native --script res://tests/boss_balance.gd
godot --path native --script res://tests/presentation.gd
```

Some sandboxed headless invocations report host certificate/log-directory access restrictions. The native presentation and exported-build runs have normal access and clean logs. No external network service is needed to play.
