# Steam private-launch setup (not activated)

No Steamworks app exists yet. This build has no Steam SDK dependency, no online leaderboard, no Steam achievements and no active Cloud synchronization. No custom server is used or planned.

## Private install/update delivery

Create the real app in Steamworks, then create Windows and Linux depots and a password-protected testing branch. Configure platform-specific launch executables (`Extinction Protocol.exe` and `Extinction Protocol.x86_64`). Steam handles installation and updates; no custom installer is needed. Do not mark Linux supported until the actual Linux build is tested.

Run `native/tools/prepare_steam.py --help` for manifest generation. It requires real App and depot IDs, points to separately staged platform releases, and includes only the executable with its embedded resources. It cannot upload or publish anything. Generated AppBuild uses Preview=1; after review, use SteamCMD locally with your Steamworks credentials. Never commit credentials. Testers need authorized access or keys for the app; a beta password alone does not grant ownership.

## Steam Auto-Cloud

Use a single canonical save identity across Windows/Linux. Set the Windows root to WinAppDataRoaming, subdirectory `Godot/app_userdata/Extinction Protocol`, exact file `progress.json`. Configure the corresponding Linux root override to its Godot user-data directory (default `$XDG_DATA_HOME/godot/app_userdata/Extinction Protocol`, usually `~/.local/share/godot/app_userdata/Extinction Protocol`). Verify the resolved root on the Linux tester's machine, including custom XDG_DATA_HOME setups.

Sync only progress.json. Exclude progress.tmp, progress.backup.json, damaged-original archives, logs, reports and verification profiles. Enable developer-only Cloud testing first. Test Windows -> Linux -> Windows, offline play and the Steam conflict prompt before enabling tester Cloud. Do not silently merge currency from divergent saves. Local backup recovery remains independent of Steam.

## Achievements (next integration step)

Use a GodotSteam build/extension matching the installed Godot version and an explicit real App ID. Standalone launches must still work when Steam is absent. Do not ship the Spacewar test ID. Define achievement IDs in Steamworks first; initialize Steam before syncing, handle callbacks and retry failed stores. Derive existing earned milestones from the saved campaign to grant returning players their achievements.

Suggested first set: FIRST_BOSS (campaign bosses>=1), FIRST_EXTINCTION (wins>=1), HUNTER_10000 (campaign kills>=10000), FIRST_UNION (a recipe discovered). These are proposed IDs, not active achievements.

## Daily leaderboard (Steam-hosted)

Use Steam UserStats leaderboards, separated by UTC date and gameplay ruleset. Rank by survival time; upload kills, score, bosses and circuit as score details. Use KeepBest, not ForceUpdate; don't overwrite a better attempt. Steam's single score sort does not implement our local board's entire tiebreak ordering. Keep local results available offline and label online/offline status honestly.

Client-submitted boards are appropriate for this private test, but are not cheat-proof. Steam Trusted writes require a secure backend; we will not claim that protection or embed a publisher Web API key in the client. No custom server is needed for ordinary client leaderboards.

## Sources

- https://partner.steamgames.com/doc/sdk/uploading
- https://partner.steamgames.com/doc/features/cloud
- https://partner.steamgames.com/doc/features/leaderboards
- https://codeberg.org/godotsteam/godotsteam-docs/src/branch/master/docs/tutorials/initializing.md

Actual Steam login, callback, Cloud and cross-device tests remain blocked on Steamworks setup and test hardware. The local game is intentionally independent of that setup.
