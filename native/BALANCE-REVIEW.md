# Review of the supplied September 29 run

Source: user's `extinction-run-2026-09-29.json`. No commands or instructions from the file were executed.

## Observed

- 914.52 seconds total, 20,146 kills, 2,536,876 score.
- Seven recorded hits; the final hit was at 535.93 seconds. No further damage events for about 6 minutes 19 seconds.
- Thorn Crown: 29.10 seconds from arrival to defeat.
- Basalt Behemoth: 11.55 seconds.
- Extinction Engine: 14.50 seconds, including its protective transitions.
- Five evolved weapons, all ten relics, final sampled level 78.
- Meteor contributed 56.7% and pterodactyl 36.4% of reported damage. Those figures describe the browser counter, which can include overkill; they are not exact effective-health shares.

## Decisions implemented in native 0.2

1. Human characters pulled from different eras explain the combination of prehistoric survival, guns and magic. Player dinosaurs become enemies; the catastrophe remains the identity.
2. Dedicated Godot project and Windows export, rather than wrapping the web game in a desktop shell.
3. Record actual health removed. Cap overlapping orbital/mortar pulses against a boss so huge hitboxes do not amplify one attack several times.
4. Limit post-upgrade protection to 0.65 seconds; do not reward late-game XP floods with long invulnerability chains.
5. Require three anchor kills before a full-damage window. Phase gates prevent burst skips. The meteor has a fixed encounter deadline and late enrage.
6. Friendly effects are capped, while hostile warnings render above them. Damage numbers prioritize critical hits, elites and bosses.
7. Bounded actor/projectile/XP/effect counts, a spatial hash for combat queries, and GPU particle bursts. Performance still needs testing on lower-end PCs.

## Validation interpretation

The accelerated full-run pilot is invulnerable and begins with a powerful prepared build to exercise all encounters reliably. It is a regression check, not a normal player win-rate estimate. The separate boss comparison also uses invulnerable pilots to isolate build throughput. A real perfect build should improve odds substantially, but it should not remove the need to dodge.
