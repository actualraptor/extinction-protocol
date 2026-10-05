# Kael ground-slam animation — 0.11.1

Two six-pose source paintings were produced with the built-in image generation
tool, using `assets/kael-walk.png` as identity and painted-style reference.
Original walk assets remain unchanged.

Normal prompt: muscular adult dark-haired, bearded Neanderthal in fur/leather and
bone jewelry; six distinct two-handed overhead ground-slam poses on a transparent
3-column/2-row sheet. Anticipation, shoulder lift, fully overhead, downstroke,
deep impact crouch and recovery; fixed three-quarter front-facing-right camera,
consistent body scale and planted feet; complete club/feet, no terrain, shockwave,
debris, text or painted blur. Original stone-headed wooden club retained.

Seasonal edit prompt: preserve all six complete poses, exact canvas, identity,
anatomy, clothing and foot placement; replace only the club head with a carved
glowing jack-o-lantern bound by bone/leather ribs while retaining grips/handle;
true transparent background and no extra effects.

Source sheets: `kael-ground-slam-normal-0111.png` and
`kael-ground-slam-halloween-0111.png`. Runtime crops are in `normal/` and
`halloween/`; `frames.json` records source bounds, authored foot anchors and the
common scale. `tools/extract_kael_slam_frames.py` uses connected-alpha ownership
to preserve crossed cell boundaries without importing a neighboring sprite.

The renderer uses real full-body painted poses, never a rotated walk frame.
Gameplay chooses pose progress. Impact contact is at 0.62 progress. Standing body
height is approximately 68px; overhead club extends higher and impact crouch
lowers the body. Root should retain an impact pose for at least one rendered frame
at extreme haste and freeze progress during pause/reward screens.

Limitations: this pass supplies one three-quarter-front direction, mirrored for
left. It does not provide a separate rear-facing attack sequence. Generated pose
anatomy has small natural variations; grounded authored anchors remove gross
baseline sliding. Ground shockwave, damage timing and scalable area remain
gameplay/FX responsibilities and are not painted into character frames.
