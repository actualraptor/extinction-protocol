# HUD plate and console system

Four visual families: `kael`, `voss`, `vesper`, `covenant`. Each contains six authored hero nameplates, four utility plates, and two console shells. All six heroes can use every unlocked HUD family; hero portrait/name selection is independent of the selected family.

Static lettering (hero names, AMBER, BACKPACK, RELICS, RE-ROLLS) is part of the artwork. Dynamic amounts use a shared `hud_plate.gd` component with tabular numerals, fixed normalized apertures, clipping, and bounded font reduction. Amber values are comma grouped. No plate changes size when values change.

`theme.json` documents textures, numeric/label/icon apertures, portraits, shell slicing, master rail geometry, and console layout. `hud_skin.gd` caches theme resources. `hud_layout.gd` defines left/center/right zones relative to the bottom-anchored HUD root. Only decorative connectors stretch on wider displays. XP, ability slots, and the master crest share the screen center. The right console reserves 70 logical pixels beyond the utility stack for the outer ornament; inventory sits farther inward. Runtime plate children ignore decoration input and stay clipped to their parent zone.

Backpack opens the existing detailed ledger. Relics opens its focused eight-slot view. Re-rolls displays the remaining count and explains R during upgrade selection; clicking it in combat never spends a charge. Minimap/inventory paging and existing gameplay behavior remain shared across themes.

## Art sources

Generated using the built-in image generation tool, with reference edits and transparent sprite sheets. Exact prompts/source locations: `prompts.json`, `shell-prompts.json`, `menu-prompts.json`, and `portraits-source.json`. Sheets are preserved in each family. `extract.py` isolates authored plate components; `extract_shells.py` extracts the two consoles; `extract_menus.py` extracts the seven pause/status pieces per theme. These scripts extract existing pixels and do not repaint the assets.

The pause menu uses four themed, engraved buttons: Resume, Backpack & Stats, Settings, and End Expedition. The heading is also authored per theme. Keyboard focus brightens the artwork, hover and press states retain the same input behavior, and decoration never captures clicks. The top location/clock and score plates follow the selected HUD family, independent of the hero. Location, boss countdown, clock, and comma-grouped score remain dynamic in documented per-theme apertures. The score label is baked into its panel. Top panels and pause content use uniform scaling and bounded positioning.

## Validation

Run the native fixture with `Godot --path native --script res://tests/hero_hud.gd`. It checks all 24 hero/theme pairs at 1920×1080, 2560×1440, 3440×1440, 3840×2160, 1680×1050, and 1024×768, plus existing HUD scaling, bottom attachment, inventory paging, map markers, resource fill states, theme unlock guards, and utility interactions. Numeric cases include 99,999 Amber, 9,999,999 Amber, and 99 re-rolls. Actual Godot screenshots go to `native/build/hud-concepts/`.

The pre-rework checkpoint remains at `native/build/hud-backups/2026-10-06-current-hud-ccf56a/Current-HUD-Checkpoint.zip`, with its manifest and scoped restore instructions. Gameplay saves were not included or changed by that backup.

`res://tests/hud_menus.gd` additionally verifies four pause/status themes at six resolutions, large score values, clock/countdown strings, panel/label/menu bounds, keyboard focus, Resume, Backpack, and Settings callbacks. The End Expedition callback retains its existing withdrawal behavior.
