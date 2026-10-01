# Progress safety for private testing

The profile remains `user://progress.json` (Godot's Extinction Protocol user-data directory). Windows normally resolves this to `%APPDATA%/Godot/app_userdata/Extinction Protocol/progress.json`. Linux normally uses `$XDG_DATA_HOME/godot/app_userdata/Extinction Protocol/` or `~/.local/share/godot/app_userdata/Extinction Protocol/`.

## Format and compatibility

- Current schema: version 2. Version 1 profiles migrate in memory without resetting amber, research, records, discoveries, recipes or campaign totals.
- Legacy returning players retain the original equipment entitlement migration.
- Unknown fields, research IDs and unlock IDs remain present, allowing later additions without stripping data.
- Invalid nested shapes are rejected before gameplay consumes them. Missing legacy fields receive defaults; an incomplete version 2 document is rejected.
- A profile from a future schema disables saving in this build. Do not downgrade by replacing its version number.

## Recovery and transaction behavior

Load preference is a valid canonical `progress.json`, then a complete pending `progress.tmp`, then `progress.backup.json`. A newer-schema source stops fallback so an old build cannot roll progression back. An unreadable primary falls back to safety copies. If all existing sources are invalid, saving is disabled and the main menu reports that the files are protected.

Every save writes and flushes a pending file, reopens it for validation, copies a valid previous primary into `progress.backup.json`, then renames the pending file over the primary. Failed commits leave a recovery source available. A recovered pending transaction is backed up before that temporary path is reused. A damaged primary is retained as `progress.json.damaged-<timestamp>` before replacement. Damaged files never overwrite the last valid backup.

This protects against process interruption and common partial/truncated files. It is not a guarantee against storage hardware failure or every filesystem/power-loss failure. Keep external backups for valuable test profiles.

## Steam Cloud planning

Configure only canonical `progress.json` for Cloud synchronization. Leave pending, backup, damaged files and run reports local. Steam Cloud configuration requires the game's actual Steamworks app and should map Windows and Linux user-data locations to the same cloud identity. Never package tester profiles. Steam's conflict prompt remains important for simultaneous/offline sessions; this module does not merge divergent balances or purchases across devices.

## Verification

`native/tests/profile_safety.gd` creates unique fixture directories under `native/build/`. It does not touch the real user profile. The suite covers migration, unknown field preservation, unlocks/recipes, repeat recovery, missing and truncated primaries, interrupted transactions, malformed nested fields, future schema refusal, and application-level persistence blocking/round trips.

Latest run: **35 checks, 0 failures** (`native/build/profile-safety.log`).
