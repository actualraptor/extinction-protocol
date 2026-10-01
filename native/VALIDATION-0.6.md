# 0.6 release validation

Validated on 2026-09-30 with Godot 4.7.2, Windows x64 and an RTX 5070 Ti using OpenGL compatibility rendering.

## Automated checks

- 400 headless checks: systems 145, fun pass 93, biome pass 14, patch 0.5 20, unions 75, XP 5, patch 0.6 43, controlled union comparisons 5.
- 11 native presentation checks: map, discovery persistence, ledger, union discovery, optional replacement, refinement reel and HUD layout. Screenshots inspected.
- 9 existing native presentation checks, including save/recovery, restart, pause and chest interaction.
- Tests used isolated save fixtures. Personal run reports are excluded from the release package.

## Balance and progression

Controlled 20-second effective damage comparisons against one large target: fire/mortar 31,733 to Supernova 35,486; lightning/frost 19,450 to Whiteout 20,962; revolver/shotgun 18,590 to Last Word 22,315; club/spear 13,408 to Earthshaker 17,413; orbital/aegis 1,784 to Bastion 4,633. These fixtures verify no catastrophic merge regression, not universal superiority in every encounter.

An invulnerable progression pilot won at 18:20, level 87. The final meteor arrived at 15:00 and required about 200 seconds, within its 210-second deadline. This verifies attainable progression and damage; it does not measure human dodging difficulty. A separate prepared strong build won its final encounter in 169.9 seconds; the weak fixture failed.

## Performance and limitations

The 2,200-enemy stress fixture with four maximum weapons measured about 32 FPS: median frame plus simulation 28.878 ms, p95 36.635 ms; live fixed-step median 31.849 ms, p95 44.368 ms. This is an extreme load and is not a 60 FPS guarantee. Real player balance and performance on lower-end hardware still need further playtesting.

The standalone embedded executable was launched on the native GPU in its no-reward package verification mode. Assets, sound resources and gameplay scene loaded successfully. The prior 0.5 release and pre-change source backup remain available.
