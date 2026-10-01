# 0.6.1 — Field visibility

- Tab opens a transparent map overlay while movement and combat continue. Tab or Escape closes it. M remains an alias. B opens the paused backpack and damage ledger.
- Off-screen guidance prioritizes a placed waypoint, biome exit, then nearest undiscovered unlock. No arrows to routine chests or shrines, no arrow when the target is on-screen.
- Completed discoveries no longer show misleading unknown signals. Unfound locations use larger illustrated camp markers; arriving records the discovery and explains the Archive purchase.
- Equipment uses compact hoverable icons: weapons, relics and passives. Backpack includes survivor crit chance, armor, speed, health, regeneration and upgrade ranks, plus calculated weapon power/cooldown/count/radius and measured damage.
- Smaller ornate boss frame, compact footer and automatic relative HUD reduction at larger window sizes. Settings adds a saved HUD-size preference.
- Health is a small bar below the survivor; hover for current/max HP. Low health turns red and an active shield adds a blue strip. Removed the upper-left health panel.
- Survivor artwork is about 21% smaller. Combat collision and movement are unchanged.
- Removed both untextured circles around spit windups/projectiles. Painted venom remains visible above friendly spells.

## Validation

Ten focused native UI checks passed, with isolated test progression. Verified live map timing, key toggles, completed/new discovery guidance, discovery arrival, backpack pause, equipment tooltip and large-window scaling. Inspected native captures at 960×600 and 1920×1080, including the under-character health bar and revised footer. These are UI validation checks, not a new full-run balance benchmark. The 0.6 balance and gameplay rules remain in place.

Extract the Windows ZIP, then run Extinction Protocol.exe. The previous release remains available; your existing progression is retained.
