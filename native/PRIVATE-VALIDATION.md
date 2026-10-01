# Private candidate 0.9.0 — validation and remaining release gates

Date: 2026-10-01. This is a limited private Windows test candidate, not a claim of public Early Access readiness.

## Completed

- Save safety: 35 checks (profile-safety.log). Migration preserves balances, research, unlocks, discoveries and recipes; corruption/pending-write recovery and future-schema protection tested. Real player profiles were not used.
- Complete-run integration: 214 checks (private-runs.log), all three maps in Expedition and Daily; real damage phase gates, chest fusion, XP rewards, portal charging, repeated Daily circuits and timeout.
- Daily rewards: 2,178 checks. Systems158, frontiers77, unions87, polish59, patch06 43, fast weapon/phase54. XP5, lingering8 and crit/charger7 also pass.
- Full-run soak: 991.4 simulated seconds, 45,681 kills, 1,593 peak enemies, final boss defeated in91.4 seconds. Weak stationary build loses. Uses test-only invulnerability; lifecycle/combat verification, not ordinary-player balance. The long invocation began before two stale orbital test fixtures were corrected and exited1 for those pre-soak assertions; the corrected fast suite passes54/54. The full-run assertions themselves passed. No redundant soak was run.
- UI: 1,958 actual text/button/screen-bounds checks. Ten core menu pages plus backpack/summary; HUD extreme-value checks at1024x640,1280x720,1920x1080,3440x1440 and65/100/135% scale.768 upgrade-card checks also pass. Native screenshots visually inspected.
- Daily reel: actual level/chest spin -> held result -> claim passed with isolated profile.
- Windows exported launch smoke test uses verification-profile.json in the executable folder; no real save read/write.
- Linux export succeeds; ELF64 x86-64 binary and119 literal resource paths checked for case-correctness. Linux has NOT been launched here.
- SteamPipe manifest generator tested with temporary fixture IDs: preview-only, no SetLive, only embedded executables staged, invalid-ID rejection. No Steam upload or login performed.

## Local test tools

`python native/tools/verify_private.py` runs the focused private gate with per-suite timeouts; `--suite soak` opts into the longer simulation. Native screenshots need a desktop graphics session. The environment emits a root-certificate-store warning in sandboxed headless runs; script failures are not ignored.

## Remaining before an online private Steam build

1. Create Steamworks app, App ID, depots and tester access. See steam/PRIVATE-SETUP.md.
2. Add a version-matched GodotSteam integration using that real App ID; exercise real achievements callbacks and Steam-hosted Daily score upload/download. These services are NOT implemented or advertised in this standalone build.
3. Configure/test Auto-Cloud against both OS save roots, offline conflict and roundtrip updates. Current saves are local with local backup protection.
4. Run the Linux candidate on actual Linux hardware. Validate graphics/audio, fullscreen, saves, driver compatibility and case-sensitive paths dynamically.
5. Tester acceptance: a normal non-invulnerable Expedition and a Daily session, application restart after purchases/unlocks, then update in place without progress loss. Reports/video feed the next fix pass.

Controls, store assets and broad performance optimization were explicitly deferred. No custom server is required or planned for Steam's basic achievements/Cloud/client leaderboards.
