# Extinction Protocol 0.8.3 — Typography and card layout

- Bundled Cinzel semibold for headings and buttons, and Source Sans 3 medium for body text and combat numbers.
- Removed reliance on installed system fonts; heading symbols fall back to the bundled body font.
- Upgrade buttons sit above the lower fossil ornaments, with a simple inset gold border.
- Button text refits from its intended size when resized, rather than permanently shrinking.
- Adjusted timer spacing for the new font metrics.
- Validation: 768 menu/card bounds checks and 73 HUD checks across 1024x640, 1280x800, 1920x1080 and 3440x1440, at three HUD scales. Rendered menus inspected visually.

Fonts: https://github.com/google/fonts/tree/main/ofl/cinzel and https://github.com/google/fonts/tree/main/ofl/sourcesans3 — SIL Open Font License; licenses included.
