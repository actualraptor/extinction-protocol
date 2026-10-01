# 0.8 validation

## Completed

- Polish mechanics suite: 59 checks passed.
- Multi-crit and charger suite: 7 checks passed, including 10,000 critical-tier rolls.
- Lingering and hostile-priority targeting: 8 checks passed.
- Systems regression: 158 checks passed, including bounded 2,200-enemy population.
- Progression regression: 77 checks passed; map/discovery routes: 34 checks passed; 0.6 compatibility: 43 checks passed during this pass.
- All five characters survived the deterministic 60-second opening simulation after the opening spawn adjustment.
- Native UI: 6 checks passed, including actual Archive mouse input, purchase/reload, HUD scaling and boss label separation.
- Native ultrawide: 6 checks passed at 3440x1440, including boss HP and viewport bounds.
- Timed defeat: 5 checks passed, covering timeout, cinematic, dark hold, scoreboard and cleanup.
- Reviewed rendered captures of upgrades, Archive, scoreboard, daily preview, boss/crit/mortar effects, ultrawide layouts and the meteor ending.
- Original sound files generated with bounded peaks and distinct synthesis recipes; not subjectively auditioned through the agent tools.

## Limits

Opening simulations use a simple movement bot and one deterministic seed per character; they are not a substitute for player balance feedback. No claim is made of a fully played human 15-minute run. The 2,200-enemy headless simulation averaged roughly 40 ms per step on this host; that is not a rendered frame-rate measurement. Headless runs reported the sandbox's certificate-store warning. Native visual tests completed without script or shader errors.

All native UI tests use separate fixture progress files. The release preserves the user's existing progress and prior 0.7 package.
## Standalone package

The Windows x64 executable exported successfully and launched its embedded practice encounter on the native OpenGL renderer. The package smoke test saved a rendered screenshot and exited without script/shader errors. The ZIP contains only the executable and release documentation; fixture saves, captures and development tools are excluded.
