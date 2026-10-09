# Extinction Protocol devblog

[Read the devblog on the website](https://actualraptor.github.io/extinction-protocol/devblog.html) · [Development roadmap](ROADMAP.md)

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

