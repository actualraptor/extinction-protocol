# 0.8.2 — Fate decides

## Daily survival randomizer

- Removed preset five-weapon builds, fixed relic sequences and special level rewards.
- Daily uses the normal level-up generator, then randomly selects one of its available choices.
- Chests use the ordinary rarity, evolution, union, refinement and replacement systems. Daily automatically resolves choices; a replacement offer randomly equips or salvages.
- New weapons, passives, augments and relics enter through the normal eligible reward pools. No separate daily content list is maintained.
- A shared UTC date seed selects the survivor and map. Start with that survivor's normal weapon. All content is available; permanent research is disabled.
- Reward RNG is separate from combat RNG. Legal choices still depend on your current build and which rewards you collect.
- Meteor victory opens another circuit instead of ending the daily run. The next map is drawn from the map catalog in rotation.
- Each completed circuit doubles new enemy/boss HP and adds 50% incoming non-piercing damage. Boss scheduling restarts at five-minute intervals after entering each biome.
- Survive until death; the meteor's timer can still end a failed encounter.
- Added a local daily leaderboard ranked by survival time, then kills, then score. Also records bosses defeated and circuit reached.
- Results save with their UTC date and ruleset. The board shows today's top ten attempts; up to 200 attempts are retained. This is not an online leaderboard.

## HUD

- Rebuilt the timer panel's internal layout: timer, biome and countdown stay inside the illustrated inset.
- Added a matching stone/brass frame around the blue XP bar and a central gold-text level plaque.
- Added a framed arsenal tray and styled amber/backpack readout.
- Daily readout says FATE DECIDES rather than advertising unused rerolls.
- Weapon tray, XP bar and backpack panel have separate reserved space.

## Validation

- 1,458 daily checks passed across twelve seeds: normal-pool parity, deterministic rewards, inventory limits, varied builds, endless portal transition and unchanged normal expedition victory.
- 73 native HUD/save checks passed across 1024x640, 1280x800, 1920x1080 and 3440x1440 at 65%, 100% and 135% HUD sizes.
- 59 existing polish regression checks passed.
- Captures inspected for timer insets, XP/arsenal presentation, daily menu and leaderboard. Local fixture saves used for UI checks.
- Balance is not exhaustively human-playtested; bad and powerful random builds are intentional.
