# Extinction Protocol devblog

[Read the devblog on the website](https://actualraptor.github.io/extinction-protocol/devblog.html) · [Development roadmap](ROADMAP.md)

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

