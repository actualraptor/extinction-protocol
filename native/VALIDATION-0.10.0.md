# Hollow Harvest local release candidate

Windows export and startup verified. Linux export produced; Linux runtime compatibility remains unverified.

Checks completed:

- Six boss sequences: 58 checks, zero failures. Tests cover repeated windup/action/recovery cycles, locked aim, destructible summon cancellation, exposure, bounded summons, immovable bosses, rewards/portals and unchanged meteor attacks.
- Build control, speech event triggers, theme defaults and migration: 17 checks, zero failures.
- Kael voice channel: 161 checks, zero failures; includes priority, variant selection, cooldowns, low-health hysteresis and cleanup.
- Daily seeded rewards: 2178 checks, zero failures.
- Complete-run integration: 214 checks, zero failures.
- Weapon unions and XP magnets: 124 checks, zero failures.
- Profile safety: 35 checks, zero failures.
- Menu and HUD layouts: 2138 checks, zero failures, including 1024×640, 1280×720 and 3440×1440.
- Every upgrade card and its controls: 996 checks, zero failures. Restored tags and Banish initially exceeded card height; spacing was corrected and all cards retested in the real renderer.
- Summary bounds: 657 checks, zero failures.
- Stage objects: 29 checks; progression: 34 checks; terrain: 15 checks; seasonal menu: 11 checks. All pass.
- Scorched-ground lifetime and damage checks pass.
- Painted seasonal atlas/accessory/music checks pass.

Rendered and inspected seasonal survivors, all six boss windups, compact and ultrawide upgrade cards, settings and the haunted main menu. Screenshots are local build artifacts, excluded from release exports.

These are deterministic and simulated integration checks, plus rendered UI inspection. A human 15-minute playthrough and Linux playtest are still recommended before public promotion. Godot reports existing exit-time ObjectDB cleanup warnings; there were no gameplay script errors in the passing suites.

Progression references: [Vampire Survivors achievements](https://vampire-survivors.fandom.com/wiki/Achievements), [Vampire Survivors Banish](https://vampire-survivors.fandom.com/wiki/Banish), and [Megabonk quests](https://megabonk.wiki/wiki/Quests). The update uses discovery goals, weapon-use milestones and limited build control; it does not import their content.
