# Clean sprite extraction

These PNGs are deterministic isolated copies of the project's existing painted
atlases, not replacement artwork. Originals remain unchanged.

`tools/extract_clean_icons.py` classifies connected opaque-alpha components by
their authored sprite cell, then restores nearby translucent edges with stable
ownership. Cropping follows the complete owned silhouette rather than a fixed
grid inset. Each output has transparent padding and consistent perceived size.

`manifest.json` records source painting, original cell index, silhouette bounds
and component count. Boss images use actual game species and optional seasonal
skins: triceratops, volcanic golem, ice sabretooth, spectral ammonite, meridian
beetle, fungal brood spider and Extinction Engine meteor.

Portrait outputs isolate the supplied seasonal full-body sheet and the original
Iona walk frame. No gameplay or profile state is changed by extraction.

Rebuild all outputs with bundled Python/Pillow/NumPy. For visual proof without
re-extracting, use `--contact-only`; contact sheets are written under `build`
at 40px HUD and 160px reel sizes on light, dark and checker backgrounds.
