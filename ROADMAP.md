# Development roadmap

Updated 17 October 2026 · Early Access playtest 0.15.0

Done means accepted by the developer. A private preview is not a shipped feature. No release dates are promised.

## In progress

### Torr Stormbuk — ongoing Early Access refinement

Torr is included in 0.15.0 with divine equipment, permanent hammer orbit and
ricochets, independently painted movement/action poses, recorded voice lines,
an optional world encounter and a replayable illustrated lesson with a useful
reward. Existing saves are retained.

Human full-run difficulty, foot planting/action transitions and dense-crowd
performance still need refinement. The broader enemy/minion animation roster
remains a separate task. Shipping this EA update does not mark that task done.

### Companion engagement prototype

The private exported playtest includes the heavy-ally ground slam and textured traveling rupture. Locked aim, terrain blocking, individual damage credit and runtime captures pass.

Closer attack-spacing trials remain rejected. Eighteen seeded mixed-army encounters now track complete slam-and-wave coverage across three maps; lower-rank attacks connected reliably. All complete misses in that sample followed target death during wind-up; committed aim remains unchanged. A generated-terrain review now passes 576 approaches across three maps and four frame intervals. Player-survival review remains open before release. Shared-scene verification is paused with the 3D revamp; review continues in the top-down game.

### Meteor encounter redesign

Reconstructed Meteor model and redesigned encounter shipped in 0.14.4: animated shell, orbiting debris, burning flyby, randomized safe sectors and advancing fire.

The private balance loadout now respects five weapon slots and declared relic health. An older movement replay fails with both current and former loadouts, so it cannot establish current full-fight balance. A separate declared-loadout offense review wins all three Epic observations before the fire deadline; owner immunity isolates damage output. The shared-scene presentation now passes source and Windows full fights through all three phases and victory at the same 153.7 seconds with the declared Epic inventory; owner immunity and suppressed hordes isolate presentation. A normal-health private late review now restores natural spawning and checks eight seconds with 113 rendered regular actors. Review actual player survival, full-pressure balance and remaining presentation polish; these fixtures do not accept those outcomes. Shared-world presentation is paused with the 3D revamp; the shipped 0.14.4 encounter is unchanged.

### Dinosaur boss animation

T-rex and Triceratops are finished in 0.14.2. Meteor is on its first reconstructed pass, with more updates coming. Other bosses wait.

Keep the finished dinosaur rework in the public build while Meteor moves through its next presentation passes. Bosses are the exception to the sprite decision: they stay 3D models in the top-down game.

### Flametorch and Rift Conduit

Packaged combat and both milestone cards passed. Stream geometry, distinct targeting and exported sound lifecycle checks pass; a private combined playtest is available.

Review the sound mix and weapon balance. Pause, reward selection, sound settings, expiration and run-exit audio checks pass in source and the private export. Repeat crowded encounters on an idle machine before performance acceptance and release.

### Scoreboard redesign

The concept screen now fills ultrawide viewports with resizable gold panels and buttons. Live text no longer overlaps header ornaments. Ordinary survivors have independent damage and weapon-kill leaders; the army survivor retains individual leaders. Source reviews cover standard, small and ultrawide windows plus resizing; private R7 renders populated results at 3440x1392. Developer requested equal metric clarity with the concept. Private R8 now uses larger serif numerals, brighter contrast and spaced thousands; matched-data source captures and native ultrawide output were inspected. R10 repeats the populated ultrawide native check; typography equality is not yet accepted.

The numeral weight is closer to the concept in inspected renders; exact visual equality still needs acceptance. R23 is a local scoreboard-only review with sound-enabled launcher, no archive/upload/publication. Finish broader interface quality and remaining gameplay/art/performance backlog.

### Companion naming and statistics

The private exported playtest combines 640 given names, 128 titles and 320 epithets. Packaged checks confirm 100,000 unique names, persistent individual leaders and unchanged combat randomness.

Developer chose to retain the current ceremonial naming tone. The longest generated names fit the actual exported score-screen frames; public release remains pending.

### Additional permanent research

Three progression-gated permanent upgrades have dedicated original artwork in the private exported playtest. Packaged archive captures verify locked silhouettes and unlocked cards; purchase protection, refunds and effect scaling pass.

Review artwork and balance in gameplay before public release; undiscovered entries remain unnamed.

### Starter melee paths

A private ground-slam prototype uses dedicated textured ruptures and ornate rank-five cards. One path widens the forward fracture; the other launches full-strength fronts in both directions.

Review the actual runtime preview and isolated playable lab before replacing the live starter. Public acceptance and balance remain open.

### Progress safety and respec

Save validation rejects malformed spent-research and discovery receipts and checks HUD settings; research respec refunds have dedicated source tests. Local source work, not yet in a public build.

Re-run the validation and respec checks on the clean 0.14.4 base before including them in the next patch. Undiscovered entries stay unnamed.

### Soul projectile effects

Soul Reaper and Soul Dominion have animated spectral skull frames, curved motion wakes and dedicated impact sparks. Frame blending, skull anchoring and evolved scaling pass source checks.

Review in crowded combat and move onto the clean top-down base. Not in a public build.

## Needs improvement

### Soundtrack polish

Map and boss themes are in game. Track crossfades now avoid the deep gain dip caused by fading in decibels; cinematic and narration ducking remain prompt.

Review transitions through in-game listening and continue production and musical polish. The revised fade passes the private R4 export checks; listening approval and production polish remain open.

### Interface polish

Settings scrolling no longer changes volume or HUD size accidentally. Keyboard focus scrolls into view, and Escape returns consistently to the menu or paused run. Actual 1024x768 and 1280x540 checks cover input, persistence and navigation; broader interface polish continues.

Settings fixes pass the private R4 export. Review remaining screens before public release.

### Horde difficulty and experience

Increased spawn pressure remains in place. Event enemies grant 30% extra XP; a 5,000-drop check preserved every reward within the 800-gem cap.

Review early survival and late crowd performance before increasing density further.

### Late-run crowd performance

A 30-second rendered test starting with 650 ordinary-health enemies averaged 8.7 ms per frame on the development RTX 5070 Ti, but keeping all 650 alive artificially cost about 42 ms. That surviving-crowd case is still open; the numbers are not a minimum-spec guarantee.

Profile the surviving-crowd case in the top-down game on an idle machine; enemy updates were about three quarters of simulation time.

## Planned

### Isometric 3D environment revamp (paused)

Paused on 14 October: the developer returned to the top-down presentation. A private shared 3D scene was built (streamed terrain and rocks, early combat, rewards and selected bosses), but it never replaced the game and is not part of any release.

No work is scheduled. The private experiment and its checks are preserved and can be revisited; production gameplay remains the top-down game.

### Animated 3D characters and monsters (paused)

Paused with the 3D revamp. Private reconstructed and rigged models exist for the 19 regular creature kinds, but regular units and playable characters keep their painted sprites. Playable-character 3D attempts did not reach the quality bar and were shelved.

Nothing from this card is in a build. Bosses stay 3D through the boss animation card.

### Next patch: consolidating reviewed work

Work finished after 0.14.4 sits in a working tree beside the paused 3D experiments. It moves onto a clean 0.14.4 base in priority order: save safety, the level-up cue, the score screen with army names and research art, then combat feel and the Kael path work.

Each item needs developer acceptance in the top-down game before it is called done. No release date is promised.

## Done

### Companion sprite animation

Developer decision: regular units and playable characters keep their existing painted 2D sprites and animation, including in the top-down game. The full-rig replacement experiment is closed.

Final for regular units. The 13 October 3D-roster request was withdrawn on 14 October; bosses remain the 3D exception.

### Cinematics and replay gallery

Opening and progression cinematics are complete, with unlocked scenes available in the gallery.

Completed and accepted by the developer.

### Main-menu redesign

Official logo, new button artwork, ambient mist and flickering lights are in place.

Shipped in 0.14.1.

### Discoveries grid

Large categorized grid with unlock states and a dedicated detail panel.

Shipped in 0.14.1.

### Early Compy stampedes

Early stampedes rush through the battlefield and push creatures and survivors.

Shipped in 0.14.1.

### Boss-defeat respite

A short pause in new spawns gives the battlefield a moment to breathe.

Shipped in 0.14.1.

### T-rex and Triceratops boss rework

Rebuilt models, grounded pursuit, directional attacks, spacing and creature sound are finished for both dinosaur bosses.

Shipped and accepted in 0.14.2.

### Level-up sound

Developer-approved sampled harp, celesta and string reward now replaces the previous cue in the local game sound bank. Repeated gameplay playback verified.

Approved by the developer. It ships with the next validated build and is not yet in a public release.

### Linux compatibility verification

Previously published Linux builds confirmed working natively by the developer.

Continue the existing Linux build process and check future release regressions.

## Active implementation — 16 October 2026

Weapon milestones, combination design and rarity celebrations are in progress. The developer delegated combination design decisions to Codex; implement the thematic pairings without a separate approval gate. Existing accepted top-down features remain intact; no work resumes on the shelved 3D roster.

Rarity source milestone: tiered celebrations, Artifact name hold, reduced-effects and unique stings are implemented. Rendered source and actual chest-award/RNG tests pass; daily reel bypass corrected. Packaged checks, audio listening/mix and final visual acceptance remain. Weapon milestones and combinations continue.

Projectile milestone source progress: ten weapons now have40choices and ornate cards. Real combat/branch/card checks pass, with sampled runtime captures inspected. Inventory confirms52runtime weapons and33still lacking complete milestone choices; this feature remains in progress.

Ordinary-delivery milestone progress: all ordinary weapon types and six existing ordinary unions now have both milestones. Current runtime coverage is38/52;14gated entries remain.116cast choices,116card bounds and selected real combat/effect checks pass. New unions and packaged verification remain unfinished.

Current-catalog milestone source coverage is52/52, with208cards rendered and gated behavior/army/ritual regressions passing. New combination weapons will extend that catalog and still need implementation, paths and packaged verification. No release or final acceptance claimed.

## 16 October 2026 — Combination source integration

Seven new ordinary unions are implemented, including both beam parents. The current catalog is59weapons, each with both milestone sets. Real fusion, retired-ingredient credit, recipe disk reload, nonduplicating refunds and rendered source encounters pass. Cards remain in progress pending packaged review and developer acceptance; broader balance is not accepted.

## 17 October — three-feature local delivery

All weapon milestones, seven additional combinations and tiered rarity celebrations are implemented and locally verified in Windows test build6. Real card claims, combat, preserved saves/refunds/recipes, small/UW effects and audio controls pass. Normal-health rendered samples survive; extreme surviving crowds remain heavier. Roadmap acceptance still belongs to the developer; older full-campaign balance and crowd optimisation work remains open.
