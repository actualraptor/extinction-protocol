# Extinction Protocol 0.9.2 — The World Opens Up

## Stages

- Added three authored expedition stages: Lost Cradle, Frostbreak Expanse and the Sunken Observatory.
- Each stage now uses a large bounded continuous terrain field with seeded obstacle islands, broad travel routes and stage-specific modifiers.
- Added map-specific landmarks, discovery signals, caches and build passives placed across the world.
- Added the Expedition Atlas overview: major objectives stay visible, far signals are marked as unknown until found, and clicking pins a route.
- Ordinary enemies recycle safely outside the active view while bosses and discoveries remain persistent and readable.

## Survivors

- Kael is now the guaranteed starting survivor.
- Vesper now uses a new directional female mage walk cycle in-game.
- Existing unlocks are preserved by the profile migration; paid survivors remain unlockable through discoveries and milestones.

## Fixes

- Fixed map overlay clipping on compact windows by clamping inset rectangles before drawing.
- Added authored landmark art for camps, skeleton sites, giant trees, observatories, vaults and craters.
- Preserved all existing weapon unions, daily rewards, archive respecs and progression safety rules.

## Validation

- Starter migration: 16 checks, 0 failures.
- Stage objects: 24 checks, 0 failures.
- Stage atlas: 42 checks passed.
- Continuous terrain: route, bounds, spacing and obstacle checks passed.
- Visual captures generated for all three stage atlases, routes and Vesper directional portraits.
