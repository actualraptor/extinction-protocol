# Painted starter attack sequences

Built with the built-in image generation tool, 2026-10-05. Project-owned references were used: `mara-walk.png`, `vesper-walk-v2.png`, and the clean Halloween Voss/Vesper portraits. Sources remain intact as sibling versioned sheets.

Normal Voss prompt: six full-body 3-column/2-row painted poses matching red ponytail, mustard scarf, teal coat and bronze revolver; reach holster, draw, aim, brace, fire/recoil, recover. Fixed three-quarter front camera facing right; complete silhouettes and transparent alpha.

Normal Vesper prompt: six full-body 3-column/2-row painted poses matching female mage, black hair, purple/gold robes and crystal staff; gather, lift, channel, windup, release, recover. Fixed three-quarter front camera facing right; complete silhouettes and transparent alpha.

Halloween edit prompts preserve the attack sequence and identity. Voss receives the existing dark haunted gunslinger costume, bat shoulder trim and pumpkin belt charm. Vesper receives her existing broad-brim purple witch hat. The seasonal toggle selects separate textures; normal sprites remain available.

`extract_hero_attack_frames.py` uses connected alpha ownership to isolate neighbors, preserve original pixels, crop full silhouettes and record manual planted-foot anchors. These are distinct painted arm/torso/body poses, not rotation of walking sprites. Body scale is fixed to 68 pixels; raised staff may extend above the standing body. Actual gameplay-size contact evidence is `build/hero-attacks-68px-contact.png`.

Runtime API: `hero_attack_animation.gd` supports Voss (0) and Vesper (2), with release at progress 0.62. Gameplay owns pause/timing and separately renders muzzle/magic effects. Camera art is three-quarter front and can mirror for the opposite direction; dedicated rear attack art is not included. Root should retain the release frame at least one rendered frame at extreme haste.
