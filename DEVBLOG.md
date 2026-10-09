# Extinction Protocol devblog

## 2026-10-10 — Meteor reaches the public build

0.14.4 includes the reconstructed core, articulated shell and orbiting debris. A burning flyby returns for impact; the encounter begins after landing. Three-wave volleys keep one safe sector and change it between casts. Advancing fire communicates the 210-second limit.

The actual Windows export activated the model without private flags and passed rendering, volley and deadline checks. At 1080p with 400 enemies and late-fight fire, average frame time was 10.2 ms and the 95th percentile was 13.6 ms on an RTX 5070 Ti. Player feedback and balance iteration continue.



[Read the devblog on the website](https://actualraptor.github.io/extinction-protocol/devblog.html) · [Development roadmap](ROADMAP.md)



## 2026-10-09 — Following a moving target

The refreshed T-rex comparison includes its corrected chase. Triceratops now has a continuous moving-player review covering charge, horn sweep and stomp in both phases, with the camera keeping both actors visible. Contact checks found no leg overreach in that run.

Meteor core tracking passes four directional checks in the exported model. A declared Epic equipment build completes the encounter across three test seeds, but its predictive bot is stronger than a human player: this establishes possible routes, not final difficulty. Visual, auditory and full-fight acceptance remain open. These are private reviews; the public game build is unchanged.

## 2026-10-09 — Testing the build we actually ship

Private build checks uncovered two issues that source-folder checks had missed: external artwork paths and a T-rex chase failure hidden by release assertions being compiled out. Packaged artwork now has explicit paths, and the T-rex responds more sharply to a circling target.

Assertion-enabled exports pass focused dinosaur chase, attacks, pause, death and corpse handoff checks. Meteor phase transitions and victory also pass with overlapping attacks. Visual quality, perceived sound and ordinary-build encounter balance remain under review. No public game build was changed.

## 2026-10-09 — Aiming from the moving skull

A focused bite review found a spatial aiming error that horizontal direction checks had missed. Rotating the neck moves the skull, so the private T-rex now refines its aim from that updated position while preserving the committed target and damage geometry.

96 normal and slow-frame commitment cases pass. Across24 bite-impact samples, spatial aim stays within8 degrees of the target; a short actual-game capture retains planted feet. Continuous motion, sound and full three-boss acceptance remain open. Comparison footage needs refreshing after this correction. No game assets or builds were released.

## 2026-10-09 — Giving attacks their own sound

The encounter prototype previously reused weapon sounds for its major attacks. A private effects study now separates pressure bursts, falling debris and ground fractures, with three variations per cue. A protected audio pool keeps rapid weapon sounds from cutting those cues off.

Runtime checks cover variant rotation, competing weapon cues, gain preservation, pause/resume and disabling sound. The recorded mix still needs auditory review; passing signal checks does not establish sound quality. Motion, interactions and full-fight acceptance remain open. No game assets or builds were released.

## 2026-10-09 — Finding the hitch outside the boss



A private combat profile traced repeated frame spikes to the HUD minimap rebuilding its terrain image. The minimap now reuses cell samples and assembles pixels in a batch, preserving its existing appearance. Attack artwork is also prepared before its first use, and the boss shares depth ordering with nearby actors.



Eighteen comparisons retained identical terrain and exploration pixels. On the test machine, a matched 60 FPS paced encounter reduced the worst observed frame from 58 ms to 20 ms. This is a focused result, not a guarantee for every machine or dense build. Continuous animation, audible mix, full-fight balance and developer acceptance remain open. No game assets or builds were released.



## 2026-10-09 — A deadline with room to fight



Full encounter review exposed a mismatch between the advancing fire and the boss's physical footprint: the last usable ground vanished before the intended deadline. The private prototype now preserves a narrow refuge until the deadline, then ignites that remaining ground. Rendering and damage use the same boundary values.



Ground clearance checks across three encounter seeds, camera stability and fire damage contracts pass. A repeated full-fight diagnostic reached overtime without early fire damage; it still lost. That is useful timing evidence, not proof of balanced difficulty or finished art. Continuous animation, sound, performance and developer acceptance remain open. No game assets or builds have been released with this change.



## 2026-10-09 — Room to hunt



Moving-target review exposed brief player overlap during Triceratops recovery. More attack space corrects that case. Grounded movement also now escapes a wall when forward travel is blocked, and dinosaur footsteps, bites and tail sounds have a separate audio pool.



Both dinosaurs passed stationary and moving-target obstacle checks at normal and slow frame rates. Rendered wall routes retained body clearance; summon melee and audio interruption checks passed. A subsequent combined combat review exposed a rare support-leg failure during stomp windup, prompting another weight-transfer correction. Repeated combat, continuous animation, audible mix, dense performance and full-fight review remain open. These studies are private and await developer acceptance.



## 2026-10-09 — Keeping the weight in the stride



The private T-rex pass corrects source leg reach at touchdown and adds alternating support steps during the tail turn. Exported leg-length checks cover all twelve clips; fixed-frame attack and weapon-active combat reviews retained foot contacts. Nearby creatures also retain movement and frozen effects when passing scenery.



Full-fight diagnostics now require an explicit encounter selection, keeping legacy Meteor baselines separate from the redesigned fight. Continuous motion, sound, dense performance and developer acceptance remain open. These assets are still private.



## 2026-10-09 — Keeping the prey in sight



Private Triceratops review exposed a close-range turning limit: when the player moved inside the normal attack spacing, the physical body could lag even though the renderer followed correctly. A faster defensive turn addresses that case. Nearby creatures and landmark artwork also share a local depth pass.



Repeated Godot checks covered turning, both combat phases, head tracking and corpse handling, including a 330-actor stress scenario. Dense frame-time spikes, frozen-creature effect parity, continuous motion and sound still need work. These changes remain private and are not accepted as finished.



## 2026-10-08 — Keeping busy encounters responsive



The private Meteor pass now uses connected rubble for the travelling ground rupture. Profiling also found that each fissure warning drew dozens of separate feathered edges. Combining those into cached meshes preserved the warning shape while reducing draw calls.



In one matched local encounter, median frame interval fell from about 30 ms to 9 ms. Fresh Godot renders and all nine phase/attack timing samples passed. Frame spikes, motion, sound and full-fight balance still need review. This is development progress, not a public release or final acceptance.



## 2026-10-08 — Attacks that respect terrain



The private dinosaur pass now checks the body's turn through an attack, rather than only its chase route. T-rex and Triceratops step into a reachable stance when a nearby obstacle blocks the swing. Forward attacks can still commit in tighter passages.



Runtime review also caught a timing mismatch between the T-rex's body turn and tail animation. They now follow the same strike progress. The wall scenarios pass body clearance and impact alignment checks; continuous movement, sound and broader gameplay acceptance remain under review. These changes are not in the public playtest.



## 2026-10-08 — Contact and surface refinement



The private three-boss pass continues with contact, deformation and presentation fixes. Dinosaur summons now use the turning torso for contact and melee reach. Triceratops frill weighting and Meteor fracture surfaces received another refinement pass.



Actual summon swings and exported attack transitions were checked in Godot. Automated encounter reviews also exposed poor dodge planning; correcting the diagnostic changed the survival results, without changing fight difficulty. These checks do not establish finished motion, sound or full-fight balance. Visual and ordinary-build reviews remain open before developer acceptance.



## 2026-10-08 — Three bosses, reviewed in the game engine



### Encounter presentation review



Work continues on environmental effects and the relationship between visible danger and gameplay. Runtime review exposed a mismatch between the new presentation and terrain clearance; that mismatch has been corrected in the private prototype.



Focused checks provide useful evidence, but do not establish full-fight balance or finished art. Continuous motion, ordinary builds, sound and visual polish still need review. These prototypes are not in the public release.



The current pass focuses on T-rex, Triceratops and Meteor. Other bosses wait. Meteor artwork now has an editable reconstruction and a private shell-motion study rendered in Godot. One coordinated opening-and-reforming clip survives export with sixteen transform tracks.



This establishes portability, not finished art. The fracture surfaces still need refinement; a cavity experiment produced broken geometry and was rejected after visual review. Combat clips and encounter integration follow, with the existing fight deadline preserved. Dinosaur pursuit, attack transitions and sound acceptance also remain open.



## 2026-10-08 — Triceratops takes its first steps



**Prototype and testing**



A dedicated four-legged rig now animates the painted Triceratops reconstruction. The first walk and run clips have been exported and inspected in Godot. Ground contact, turning and attack weight remain under review; this is not yet a public gameplay replacement.



[Watch the preview](https://actualraptor.github.io/extinction-protocol/assets/devblog-triceratops-walk.mp4)



Early Triceratops motion study, rendered in Godot against ground markings. This short silent preview shows two walk cycles; it is not a finished combat animation.



### What changed



The original painted reconstruction now has four independent limb chains, a weighted torso and a rigid skull and frill. A slow four-beat walk and a faster diagonal gait are the first motion studies.



### How we checked it



Exported clips were rendered in Godot from four angles. A separate measurement sampled deformed sole vertices through every authored frame; grounded feet stayed at floor height in the current source clips. This does not yet prove turning or runtime contact quality.



### What we learned



Each creature needs its own anatomy and stance. Reusing the T-rex joint layout would not give a convincing quadruped.



### Next steps



Review skin deformation and moving contact, then build the horn charge, horn sweep and stomp around clear anticipation, impact and recovery.



## 2026-10-08 — A heavier predator, and a clearer development board



**Refinement and review**



The T-rex motion pass now covers pursuit, turns, bite, rush, tail gust, roar pressure wave and seismic stomp. It remains a development preview awaiting final play review. The remaining boss animation work follows next. Cinematics are accepted as complete; beam prototypes are paused while bosses take priority.



[Watch the preview](https://actualraptor.github.io/extinction-protocol/assets/devblog-trex-comparison.mp4)



Development comparison: original sprite fight versus the new T-rex rig. Chase, turns and all five attacks; boss sound without character speech. Final play review is pending.



### What changed



Longer strides, player-directed head tracking, a continuous tail swing, travelling pressure waves and heavier footfalls now give the T-rex more presence. Promotional comparison footage focuses on creature sound, with character speech removed.



### How we checked it



Matched old and new gameplay captures cover chase, turns and all five attacks. Further live runs checked foot contact, attack direction, pause and death interactions.



### What we learned



A fixed-frame recording missed a small turning lag seen in a fresh live run. Adding modest visual catch-up capacity corrected it without increasing the physical turn cap.



### Next steps



Complete developer play review before including the rig in a public build. Continue the remaining dinosaur rigs while keeping their progress visible.



