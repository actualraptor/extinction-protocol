# 0.4 validation

- Systems suite: 130 checks, zero failures. Covers every weapon, tag-filtered upgrades, projectile modifiers, bounded procs, pickups, terrain and boss transitions.
- New fun-pass suite: 93 checks, zero failures. Includes 16 aim directions at both normal and high projectile speed against tiny targets; five-slot cap; aura exclusivity; reroll replacement/budget; 5,000 rarity rolls; compatibility; no duplicate relics; Rare pity; thermal-shock recursion limits; functional new relic bonuses.
- Native presentation suite: zero failures. Sound bank and independent music players load, loop duration uses sample count for compressed WAV, reroll replaces UI, relic spin pauses the run, rewards auto-apply once, Artifact reward is correct. Screenshots inspected at 1280x800.
- Controlled final-boss test: weak build times out at 210 seconds; five maxed/evolved weapons win in 105.3 seconds. Both pilots protected to isolate damage throughput.
- Final earned-upgrade progression with portals and expanded enemy roster: seeded five-weapon build wins at 1049.47 seconds, level 72, with evolved Winterglass/Rift Blades, rank-nine fire, rank-seven lightning and mortar. Normal upgrade offers and weighted chests; pilot invulnerable to isolate attainable progression, not dodge difficulty. See `build/progression-final-04.log`.
- Biome suite: 13 checks, zero failures. Boss drops/portal persistence, linger pressure, next-boss gating, portal transition and reset, shared caster budget, telegraph timing, brood hatchlings, charge telegraph, roster count and both Behemoth attack patterns.
- Behemoth pacing: a five-slot build based on weapons visible in the supplied 33.3-second recording defeats the revised boss in 25.93 seconds. Passives approximated; pilot protected. This is a pacing check, not an exact replay of the user's run.
- Inspected native screenshots of all nine new creatures, the top illustrated boss bar, bottom XP bar, portal and transition. Revised the monster atlas to remove visible neighbouring-sprite fragments.
- Existing saves use the unchanged progression schema; current live runs are not migrated. Older release folders remain available.
- Final native stress run: 2,200 enemies with four apex weapons, live median 22.32 ms, p95 30.65 ms, approximately 45 FPS on this RTX 5070 Ti system. Simulation-only and coroutine timing are separate measurements. Decorative impact budgets and thermal-shock cadence prevent the earlier overload.
- Standalone 0.4 executable successfully rendered its screenshot-and-exit smoke test, including music, new monster atlas, illustrated boss frame and bottom XP bar, without script errors.

Logs and screenshots are in `build/`, using names ending in `04`. Music quality remains a creative judgment; deterministic rendering and native playback were checked, not a claim of mastered commercial audio.
