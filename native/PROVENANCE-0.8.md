# 0.8 asset provenance

## Painted assets

Generated with the built-in image generation tool in transparent-background mode. New sibling assets were added; existing artwork was not overwritten. Atlas regions are selected in Godot without modifying the source raster.

- Saved: `D:/Utveckling CODEX/Dummy test/native/assets/ui-plates-08.png` (1536x1024 RGBA).
  Source: `C:/Users/Gullberg/.codex/generated_images/01a0eeb0-2e27-7ec2-9bbf-ed290a0e8408/exec-e94ad1b3-6a17-4ed5-8e39-d818a02cd43e.png`.
  Prompt specification: a transparent 2x2 sheet of original painted prehistoric dark-fantasy UI plates: wide score and timer panels with fossil/brass framing and dark slate interiors, a larger skull-framed scoreboard, and an upgrade panel with fossil corner ornament. No text. Clear interiors for real UI labels.
- Saved: `D:/Utveckling CODEX/Dummy test/native/assets/thorns-breakables-08.png` (1280x1280 RGBA).
  Source: `C:/Users/Gullberg/.codex/generated_images/01a0eeb0-2e27-7ec2-9bbf-ed290a0e8408/exec-7354cbc1-3bf8-47c3-8cd1-b7a25e378f29.png`.
  Prompt specification: transparent 2x2 painted game-prop atlas. Upper left: emerald crystalline thorn-and-fossil buckler. Upper right: bone urn containing amber. Lower left: fossil-wood crate with amber. Lower right: cracked prehistoric egg nest containing amber. Readable orthographic/three-quarter isolated assets, coherent dark-fantasy prehistoric style, no text.

Prompt specifications above preserve the generation brief; they are not verbatim tool-call transcripts.

## Audio and effects

- `native/tools/design_sfx_08.py` synthesizes 29 original stereo 32 kHz samples; parameters are recorded in `native/assets/audio/sfx-08.json`.
- Weapon families use distinct transient/noise/harmonic envelopes. No commercial-game audio was sampled.
- `extinction_end.gdshader` creates the screen-wide fire front procedurally; `extinction_end.gd` animates existing meteor artwork and layers existing original impact samples.
- Existing music and earlier artwork retain their previous provenance.
