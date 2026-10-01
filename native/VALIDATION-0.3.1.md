# Visual patch validation — 0.3.1

- Godot 4.7.2 imported and exported the project successfully.
- `tests/visual_patch.gd`: 47 checks, zero failures. Covers directional selection, idle facing, paused phase, 36 nonempty frames, and XP ratio/level rollover.
- Native GPU screenshots inspected: all five ordinary species upright, blue segmented XP bar readable at 1280x800, no mud/lava labels. Four directional views and all walk frames inspected for each survivor. Alpha-based atlas rectangles fixed observed frame clipping and neighboring-frame fragments.
- Standalone Windows executable ran `--verify-package`, rendered the new assets and exited without script errors. Test saves are isolated; user's progression was not modified.
- Combat and balance are unchanged from 0.3. The full expedition balance suite was not rerun for this visual patch.

Evidence: `build/visual-patch-031.log`, `build/upright-mobs-blue-xp-031.png`, `build/directional-walks-031.png`, `build/package-031.log`, `build/release-0.3.1/package-preview.png`.
