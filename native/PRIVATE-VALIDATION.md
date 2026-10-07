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

## 0.9.1 — Commit to the Build

Verified integration runs, Daily rewards, weapon checks, save safety, native menu layouts, upgrade cards, and reward reels. Added 105 shared-buff-slot checks, 124 union/magnet checks, 33 ground-effect checks, 132 refund/progression checks, 657 scoreboard layout checks, and a native supplies reward claim. Archive UI: 280 checks at 1024x640 and 3440x1440. Union balance comparisons pass for all five tested unions.

Native screenshots inspected for scoreboard safe insets, painted scorch areas, Archive icons, and the six-section patch-notes PNG. Website responsive checks passed at 390/768/1440. Refund tests cover milestone regrant loops and preserving discovered progress. Windows exported package smoke test uses its isolated verification profile. Linux remains an exported, runtime-unverified candidate.


## 0.14.0 — A World Reborn

Release validation: 37 of 38 regression suites passed after updating stale atlas-icon, stampede-timing and ritual-duration test assumptions. The separate meteor balance probe did not meet its old five-weapon win expectation: the modest build timed out at 210 seconds and the evolved build also timed out. It is not counted as a pass. The probe now acknowledges reward screens and uses 20 Hz simulation so it can finish; no production balance was changed on this evidence. Full natural winning-run balance remains unverified.

Covered private progression on all three maps, save corruption/migration/backup protection, refunds, current dinosaur identities and art, flock movement, spawn respite, all six summons, ritual audio and ground caching, cinematic unlock/replay gating, menus, Discoveries and all eleven music decoders. GUI checks used isolated profiles. Ritual ground tests confirmed settled SubViewports stop updating, debris remains below actors, mobs cross decorations, and all six summons draw above swarms. Current 18-second ritual submission averaged 1.53–5.78 ms during measured stages on the RTX 5070 Ti; settled submission was zero. This is CPU draw submission, not a full frame-rate benchmark.

Exported Windows package: map/boss soundtrack selections, final-score clock sync, pause/resume, early victory and selector return passed; Kael gameplay and HUD smoke capture passed. Website passed 390/768/1440 responsive overflow checks, image loading, thumbnail selection, keyboard gallery navigation and Escape. Current public media uses the approved 46-second trailer and dinosaur screenshots. Public notes omit unrevealed characters and mechanics. Patch PNG visually inspected for fitting text. Linux exported successfully but cannot be runtime tested on this Windows host.
