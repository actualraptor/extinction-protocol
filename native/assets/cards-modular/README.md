Each tier has separate AtlasTexture resources for its outer frame, title plaque,
information panel, action button and icon medallion. Text is never baked into art.
The shared reward_card.gd composes these assets in independent bounded slots.
Dense cards reserve more space for their stat table; descriptions use a separate
panel. stone_card.gd fits typography against each allocated slot and centers
icons by visible alpha bounds. Buttons tint their own artwork on hover/press.

components-a.png contains Common, Uncommon and Rare pieces.
components-b.png contains Epic, Legendary and Artifact pieces.
table-panels.png contains quieter reading panels for all six tiers.
Regenerate resource regions using native/tools/index_card_components.py.
The indexer only reads alpha bounds and writes resource metadata.

Body and title typography uses Alegreya (see ../fonts/Alegreya-OFL.txt).
Action typography uses the existing Cinzel font.
