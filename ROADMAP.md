# Development roadmap



Updated 9 October 2026 · Public playtest 0.14.1



[View the status-card board and devlog](https://actualraptor.github.io/extinction-protocol/roadmap.html)



Done means accepted by the developer. A private preview is not a shipped feature. No release dates are promised.



## In progress



### Dinosaur boss animation



Current focus: T-rex, Triceratops and Meteor. Dinosaur tracking and combat remain under review; Meteor has an original-art 3D reconstruction and a private shell-motion study. Other bosses wait.



Pursuit, spacing, wall routes and audio interruption checks pass focused reviews. Assertion-enabled private exports now cover chase, committed attacks, pause, death and corpse handoff; packaged artwork paths have been verified. Minimap pixel equivalence and a paced combat profile verify a targeted frame-cost reduction. Spatial bite aiming has been corrected and verified in normal/slow-frame commitment cases. Updated comparison footage and moving-target Triceratops attack captures are available privately. Meteor core tracking and three-seed Epic-build route checks pass; predictive routes do not establish human difficulty. Continue reviewing continuous animation, audible mix, dense performance and full-fight gameplay interactions before acceptance.



### Meteor encounter redesign



Private fire timing preserves usable ground until the deadline. Distinct attack sound prototypes and protected mixing pass focused runtime checks; auditory review remains open. Continue full-fight balance, continuous visual review and developer acceptance.



Refine animation, environmental effects and encounter readability to match the new boss presentation. Private gameplay and visual reviews continue; full-fight balance, sound and developer acceptance remain open.



## Needs improvement



### T-rex final play review



New rig, pursuit, directional attacks, pressure waves and heavy sound are ready for review.



Developer acceptance and a final playtest are still required before a public build.



### Soundtrack polish



Map and boss themes are in game; further production and musical polish remain open.



Refine balance, orchestration and transitions through in-game listening.



### Interface polish



Continue checking readability, button sizing and consistency across screens.



Keep frames and text clear at supported window sizes.



### Horde difficulty and experience



Tune spawn density so hordes pose a stronger threat and reward more experience.



Validate early pressure, progression and performance together.



### Level-up sound



Replace the notification-like cue with a satisfying fantasy level-up sound.



Needs approval after repeated listening in gameplay.



### Linux compatibility verification



A Linux archive is available; runtime compatibility is not yet verified.



Test actual Linux gameplay before calling it supported.



## Planned



### Flametorch and Rift Conduit



Targeted flowing flame and plasma tether prototypes are on hold during the boss pass.



Resume fluid animation, sound, upgrade-path cards and balance after bosses.



### Scoreboard redesign



Bring run statistics into the current UI style with clear framed sections.



Define text fitting and support long names, large totals and older records.



### Companion naming and statistics



Procedural names that persist for an individual companion and appear in run history.



Use component-based generation and separate display names from internal IDs.



### Additional permanent research



Expand permanent upgrades with progression-aware presentation.



Keep undiscovered entries as silhouettes without revealing their details.



## Done



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



## Maintaining this board



`docs/roadmap.json` is the source of truth. Update the relevant card when work starts, changes priority, reaches review, or receives developer acceptance. Keep unfinished work visible. Add a dated devlog entry for meaningful milestones. Public cards must not reveal undiscovered progression content.



Private Meteor milestone: ground-warning batching reduced median frame interval from approximately 30 ms to 9 ms in a matched local test. Motion, frame spikes, sound and full-fight balance remain in progress.

