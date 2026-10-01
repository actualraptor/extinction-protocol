# Directional survivor art — 0.3.1

Three original transparent sprite sheets generated with the built-in imagegen tool, using `characters-v2.png` as the identity/style reference. No third-party character assets or World of Warcraft artwork used. The blue segmented XP interface is drawn by the game's own code.

- `mara-walk.png`: red-haired gunslinger, teal coat, gold scarf and revolver; four sequential walk poses in each of south/east/north views.
- `kael-walk.png`: bearded Neanderthal, hide clothing, stone club; same view/pose specification.
- `vesper-walk.png`: purple-hooded mage, gold trim, cyan crystal staff; same view/pose specification.

Prompt constraints: detailed outlined painted fantasy style matching the reference; full upright bodies; feet at bottom even for back views; consistent scale and baseline; transparent background; four columns and three rows; left step/passing/right step/passing; no labels or grid. West views mirror east in the renderer. Original generated sheets are preserved unchanged.

`walk-regions.json` indexes each sprite's alpha-connected bounds to avoid clipping from irregular sheet spacing. `tools/index_walk_sheets.py` reads alpha and writes rectangle metadata only; it does not change the images. Runtime uses a common scale per survivor and aligns feet.

All previous asset provenance remains in PROVENANCE.md and PROVENANCE-0.3.md.
