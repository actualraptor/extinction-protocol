# Fortune and Fang — implementation validation

Source-tree validation on Windows, Godot 4.7.2, 2026-10-05. Public releases, website and binary assets were not published or replaced. Existing unrelated uncommitted work was preserved. Exports were built only after the user's subsequent request for a zipped release; see packaging follow-up below. No Steam integration test or real-time full-length manual run was performed.

## Passing targeted suites

| Suite | Checks |
|---|---:|
| tiered_relics_011 | 940 |
| fortune_runs_011 | 3,412 |
| fortune_visual_011 | 27 |
| fortune_lifecycle_011 | 6 |
| daily_082 | 2,178 |
| private_runs | 214 |
| unions_magnet_private | 124 |
| buff_slots_091 | 105 |
| profile_safety | 35 |
| private_ui | 2,129 |
| clean_icon_assets | 917 |
| systems | 159 |
| harvest_bosses | 58 |
| harvest_build | 17 |
| harvest_progression | 34 |
| stage_atlas | 42 |
| stage_objects | 29 |
| continuous_terrain | 15 |
| map_navigation_compact | 69 |
| map_travel_audit | 53 |
| fun_pass | 94 |
| summary_fit | 657 |
| **Total** | **11,314** |

Logs and screenshots are under `build/011-*`, `build/fortune-*` and the map/asset probes. Fixtures use separate `res://build/` profiles; the player's save is not a test fixture. Preserve these ignored files separately if sharing evidence with another machine.

## What was verified

- Every relic identity resolves all six tier effects and descriptions. Common Lens + Artifact Lens increase an actual 100-XP pickup to 135. Repeat acquisitions invalidate warm stat caches, preserve unique slots and remove correctly. Full inventories stack existing relics to ten; exhausted builds receive amber once. Refinement payloads report actual remaining rank gain for weapons, passives and augments.
- Two independent 30,000-roll samples match the displayed tier probabilities within one percentage point per tier, at zero and .5 Luck. Baseline sample: 12,064 / 8,910 / 5,378 / 2,733 / 822 / 93. Luck .5 sample: 7,026 / 7,843 / 7,037 / 5,249 / 2,470 / 375. Protection state tested separately; these samples intentionally reset protection to measure raw weights.
- Five seeded Daily reward sequences agree despite different combat RNG use. Normal level-up choices, Daily automatic rewards, chest payloads and single-award acknowledgement remain valid.
- XP/proc-heavy late builds perform real automatic attacks and gain XP in all three maps and both modes, then pass bosses through actual damage phase gates and portals. Boss finishing damage is deliberately forced to isolate lifecycle correctness; this is not a boss balance or perfect-build difficulty measurement. Queues remain bounded, relic stacks persist across transitions and Daily continues into another circuit.
- All 41 authored objective routes measured using fresh Kael terrain movement. First supply: 18.3–19.9 seconds. Farthest reward: 60.8–71.0 seconds. See `VALIDATION-MAP-0.11.0.md` for every route, seed and movement method. Combat travel times remain a playtest topic.
- Rendered screenshots inspected at 1280×720, 1920×1080 and 3440×1440: local/overview map, landed Crown reel, three upgrade cards, seasonal character cards. Original portraits, locked cards, main menu and patch history inspected at 720p. Map projection tests cover pan, zoom, recenter and resizing. The map suppresses the run HUD/banner so its dedicated footer cannot overlap XP. First-frame drawing and thin-screen region clipping were corrected after graphical testing caught them.
- Individual item/weapon/upgrade assets reviewed on dark, light and checker backgrounds at 40 and 160 pixels; Crown and Lens rechecked in the reward UI. Boss IDs resolve actual normal/seasonal boss art, including historical patch entries. The patch PNG was rendered, fit-asserted and visually reviewed; body font weight was increased after review for readability.
- Existing profile migration tests retain unknown fields, unlocks, archive purchases and records; event defaults on while explicit opt-out survives migration. No reset or destructive profile migration was introduced.
- Six start/map/menu cycles settled at 125 nodes and 2,142 objects after first-use warming (2,137 on the first cycle), with no continued growth. Explicit audio shutdown and a short drain before exit produced no ObjectDB leak warnings in this lifecycle and graphical fixture.

## Remaining diagnostic limits

Two legacy 0.7 frontier suites retain stale expectations: `frontier_routes_07` reports 14/22 failures and `frontiers_07` 8/70. Their discovery BFS covers only ±30 cells and they assert superseded shared boss hazard counts. Current authored route and distinct-boss tests pass; this report does not claim every historical test passes.

The old `summary_fit` and, intermittently, `private_ui` fixtures still emit immediate-exit audio/resource leak warnings although their assertions pass. The final `private_ui` run reported 42 ObjectDB instances and one resource on exit. The repeated live lifecycle test and drained graphical shutdown do not reproduce continued growth. Treat this as fixture/shutdown timing evidence, not proof that all runtime ownership concerns are solved.

Windows certificate-store access and graphical shader-cache creation report sandbox/runtime errors. No gameplay script error remains in the final graphical log. Reproduce those environment diagnostics outside this sandbox before classifying them as game defects. Enjoyable late-run balance, accessibility/legibility on physical displays, Linux compatibility and exported-package behavior still require tester feedback.

## Reproduction

Packaging follow-up (2026-10-05): exported Windows x86-64 and Linux x86-64 with embedded game resources. The Windows release executable ran its graphical `--verify-package` Safari smoke sequence, saved a reviewed screenshot and exited successfully, using a separate verification profile. No missing-resource, script or parse errors were found. An initial headless invocation was stopped because the capture awaits a rendered frame; that invocation is not counted as a successful smoke test. Linux was exported but not executed and is explicitly named UNVERIFIED. ZIP CRC/allowlisted contents and tar executable permissions were checked by `tools/package_private.py`; SHA-256 sidecars were produced. Archives exclude verification profiles, logs and screenshots. This follow-up does not establish full-run packaged balance or Linux support.

```powershell
& './tools/godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path native --log-file 'D:/Utveckling CODEX/Dummy test/native/build/011-repeat.log' --script tests/tiered_relics_011.gd
```

Change the script name for other suites. `fortune_visual_011.gd` requires graphical mode: omit `--headless`. New player-facing notes are in `RELEASE-0.11.0.md`, in-game history and `../dist/Extinction-Protocol-0.11.0-Patch-Notes.png`. Balance formulas and tables are in `BALANCE-0.11.0.md`.
