# 0.6.2 — Ultrawide and HUD layout

- Expanded viewport fills ultrawide displays without pillarboxing. Terrain, swarms, effects, navigation and player health now follow the expanded drawing area. Menus remain centered and their backdrop covers the screen.
- Timer/biome at upper-left, boss name and phase at top-center with a separate health-frame region, score at upper-right. Compact layouts move the buff grid beneath the boss frame's vertical extent.
- Weapons only at bottom-left. Temporary buffs (with countdowns), relics, passives and augments occupy a right-aligned top-right grid with hover descriptions.
- B opens a complete single-screen backpack: Attack, Defense and Utility stat tables; five weapon rows; eight relic slots; passive/augment icons. No scroll container. Detailed weapon damage and equipment descriptions remain available on hover.
- Tab map has no rectangular background or explored-cell fill. It shows translucent terrain boundaries and small objective markers while gameplay continues.
- Existing character size, under-character health, progression and combat rules are retained.

Validation: 19 native UI checks passed across 960x600, 1920x1080 and actual 3440x1440 captures, with all five weapons, eight relics, every upgrade and four timed buffs. Checked full backpack population, no scroll container, separate weapon/buff groups, top-right anchoring, boss text above its health trough and expanded ultrawide viewport. Inspected gameplay, map and backpack screenshots. No script errors in the final validation log. This is UI verification, not a new performance or full-run balance benchmark.
