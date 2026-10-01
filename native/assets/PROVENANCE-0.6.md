# Original assets added in 0.6

Four atlas images were generated with OpenAI image generation on 2026-09-30 specifically for Extinction Protocol. No third-party sprites or game artwork were used as references. The original PNGs are preserved; the game selects atlas regions without raster editing.

- `icons-weapons-06.png`: 5×5 atlas, 23 weapon/union icons plus compass and discovery tablet. Distinct silhouettes for lightning, storm cloud and lightning-infused ice.
- `icons-upgrades-06.png`: 5×5 atlas, ten passives and fifteen tag-specific augments. Original jeweled, bone, metal and elemental objects.
- `icons-relics-06.png`: 6×5 atlas, twenty-six relics plus map markers. Each relic has its own illustrated object.
- `hostile-fx-06.png`: 3×2 atlas, molten fissure, impact crater, annular shockwave, venom globule, charge wake and ember anticipation seal. Actual transparency is retained. Collision outlines remain independent of decorative glow.

Prompts specified isolated artwork, alpha transparency, grid dimensions, generous cell gutters, no text/borders, and the individual object list in row order. Generated sources: `exec-4f9968b5-531e-4ecc-a982-0b033ddb7cef.png`, `exec-bc1e367e-bf46-4c3a-924c-5d520a32d853.png`, `exec-856b3c28-ec52-415d-ace0-02b2518bd21c.png`, `exec-537a027b-fdc8-4a43-b32c-fba000f2aefa.png`.

`tools/compose_biomes.py` composes three original loopable stereo PCM music cues from oscillators, envelopes and deterministic noise. Each has 32 bars, a distinct four-chord progression and hook, call/response variations, drums, bass, arpeggios, stereo echoes and a final-phrase lift. Biome one is D minor at 140 BPM; biome two A minor at 152; biome three C minor at 164. No samples or existing melodies were supplied.

`tools/compose_discoveries.py` synthesizes a glassy crystal chime and a filtered metallic returning-blade whoosh. No external audio recordings are used. Existing original assets and engine license notices are retained.
