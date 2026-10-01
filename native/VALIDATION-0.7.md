# Validation — 0.7 Frontiers

- Frontiers progression/content: 76 checks passed (starter kits, map gates, milestone idempotence, save serialization, new weapon damage and chest evolutions).
- New-map routes: 34 checks passed (both gate bosses, bounded attack patterns, retained map/layout through portals, reachable deeper discoveries).
- Existing systems regression: 155 checks passed. The 2,200-enemy simulation averaged 30.05 ms per step, worst 67.07 ms, with concurrent tests running. This is simulation-only, not a rendered FPS claim.
- Existing 0.6 regression: 43 checks passed.
- Native UI integration: 13 checks passed, including disk persistence, no duplicated kill counts, free camp recruitment, music routing, and reload. Fixtures use native/build, not the player's save.
- Deterministic 60-second opening smoke runs: all five survived on their introductory maps (original trio in Cradle, Iona in Frostbreak, Orin in Observatory), with 80–180 kills. An additional Vesper/Observatory bot run died at 38 seconds; the simple navigation bot is not a comprehensive difficulty benchmark. All character/map combinations have not been exhaustively balanced.
- Inspected native captures of character selection, map selection, Archive, frost terrain, observatory terrain, and the exported final encounter.
- Nine distinct PCM music files, 64.7–80 seconds each; composition manifest records peak 0.86. Playback routing was tested, but perceptual listening is not automated validation.
- Windows release export succeeded. Exported executable launched and rendered its practice encounter without script errors. Prior release and user progression were preserved.

The older long full-expedition soak was stopped before completion; no full-run pass is claimed for 0.7. Shorter progression, combat, portal, boss-pattern, and package checks above completed. Sandbox-only certificate/log-directory warnings appeared in headless tool runs, not script failures.
