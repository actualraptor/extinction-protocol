# Working on Extinction Protocol

## Open the game

1. Clone this repository after accepting your GitHub collaborator invitation.
2. Install the standard Godot **4.7.2** editor from its official distribution.
3. Import `native/project.godot`, allow the initial asset import, then press F6/F5 as appropriate (F5 runs the main scene).

The source and game assets are included. No npm installation is required for the native game. The repository intentionally excludes prebuilt engine binaries, generated imports, test saves and build outputs.

## Run focused checks

Use your local Python and Godot installation:

```sh
python native/tools/verify_private.py --engine /path/to/Godot --suite saves --suite runs --suite daily --suite weapons
```

UI checks require a working desktop graphics session:

```sh
python native/tools/verify_private.py --engine /path/to/Godot --suite ui --suite cards --suite reels
```

Test fixtures and logs go under `native/build`. The longer optional complete-run simulation is `--suite soak`.

## Export

Install matching Godot export templates. The checked-in presets refer to the original workspace's custom template paths; in Godot's Export dialog, clear Custom Template paths to use your installed standard templates, or provide local paths. Windows and Linux exports embed game resources in the executable. Do not include tester saves in packages.

## Project map

- `native/scripts/expedition.gd`: run simulation, rewards, encounters.
- `native/scripts/main.gd`: menus and application lifecycle.
- `native/scripts/profile_store.gd`: save validation, migration and safety copies.
- `native/scripts/catalog.gd`: survivor and equipment data.
- `native/assets`: original game art/audio plus bundled licensed fonts.
- `native/tests`: simulation, progression and UI checks.
- `docs`: offline store-presentation preview. Open `docs/index.html` in a browser.
- `native/steam/PRIVATE-SETUP.md`: future Steam integration plan; no live Steam service is connected.

## Feedback

Use the repository's Issues tab. Include version, character, mode, map, time into the run and reproduction steps. Add screenshots or a run report when useful. Don't include account credentials or unrelated personal files. Saves and reports are local; the game does not automatically upload them.

## Development status

Before starting or resuming a feature, update its card in `docs/roadmap.json`. Use `in-progress` for active work, `improve` for unfinished work requiring review or polish, `planned` for queued/paused work, and `done` only after developer acceptance. Add a dated devlog entry for meaningful changes. Keep `ROADMAP.md` consistent and publish the board with the work. Do not expose undiscovered content in public descriptions. A preview or passing technical check is not developer acceptance.

Devblog entries in `docs/roadmap.json` should cover what changed, actual testing, what was learned and the next step. Add entries for meaningful milestones or changes of direction, not every command or routine check. Keep dates factual and distinguish prototype, review and released work. Mirror entries in `DEVBLOG.md`.
