# Extinction Protocol 0.5 validation

Validated on Windows with Godot 4.7.2, OpenGL compatibility renderer, NVIDIA RTX 5070 Ti.

## Final gameplay regression suite

347 checks passed across six suites: systems (140), fun pass (93), biome pass (14), patch 0.5 (20), unions 0.5 (75), XP 0.5 (5). No test failures or GDScript errors.

Coverage includes all 21 weapon/union combat behaviors, five-slot restrictions, compatible upgrades, all union ingredient removal and offer exclusions, Whiteout freezing and nonrecursive detonations, chest odds/luck/pity, mini-boss chest collection, six-second shrines, portal transitions, boss milestones and late-entry grace, four correctly timed base Thunderstorm strikes across three different timesteps, committed venom aim and swept collision, crowd separation, diagonal movement, frozen rooting and thawing, and XP conservation with a full 800-gem pool and gravity pickups.

## Native UI and assets

- Native presentation tests passed: save migration and backup, level choices, restart, pause, audio bank/music loops, rarity reel, fresh-key continuation, Artifact reward, rendered spell effects.
- Native union test passed: early input cannot skip the spin; held-key repeat cannot dismiss the reward; a fresh movement press creates Whiteout and frees one slot.
- Screenshots inspected for upgrade recipe wrapping, actual chest odds, union reveal and frozen/lightning effects.
- All 42 original stereo WAV assets are non-silent; maximum absolute PCM peak 0.8251, below hard clipping. Audio bank and playback checked in the engine; automated checks do not substitute for subjective listening feedback.
- Headless import and standalone Windows export succeeded. Exported executable launched in package-verification mode, rendered its scene and produced package-preview.png without banking a run or changing progression.

## Progression and performance

A full progression simulation during the pass reached victory at 1,092.30 seconds, level 85, with Whiteout and Supernova unions. This pilot was invulnerable to isolate progression and damage availability. It used the earlier per-biome boss schedule; the final milestone timing was subsequently verified in the regression suite. This is not evidence of normal-player survival or comprehensive balance calibration.

Final 2,200-creature no-weapon simulation benchmark: mean 15.39 ms, worst 43.83 ms. Native stress scene used 2,200 effectively unkillable creatures and four rank-X weapons with one legal aura: frame-plus-simulation median 31.35 ms, p95 42.42 ms. Live fixed-step sample median 36.55 ms, p95 67.91 ms, reported 26 FPS. Extreme sustained packs remain heavier than ordinary play; this is not a 60 FPS guarantee. Ordinary AI updates are staggered at 15 Hz above 1,000 creatures; player/combat run at 30 Hz and rendered creature positions interpolate. Contact searches are bounded and cached briefly, so temporary body overlap can occur while dense packs resolve.

The user-supplied 0xp.mp4 was inspected. It shows a stationary XP count while kills increase; the old 800-gem overflow rule banked fresh XP in distant existing gems. The replacement preserves fresh local drops and conserves total XP, including kills during a gravity pickup.
