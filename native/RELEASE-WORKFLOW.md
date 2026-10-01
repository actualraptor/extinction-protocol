# Release requirements

Every new version must include an upload-ready PNG of its patch notes. This is a standing user request. Use the game artwork, Cinzel headings and Source Sans 3 body text. Check text overflow and visually inspect the rendered PNG before delivery. Include a direct PNG link with each release. Preserve earlier release images.

Update native/scripts/patch_notes.gd for every release. Render the native notes page to the release PNG; do not use the old HTML layout.

Before changing latest notes, preserve the previous release in assets/patch-history.json. Keep complete source release notes and newest-first numeric version ordering.

Player-facing patch notes must contain only buffs, nerfs, content, gameplay or interface changes and fixes. Never include test counts, schema details, packaging or development commentary. Keep engineering evidence in PRIVATE-VALIDATION.md. Use illustrated game art and clear category headings inspired by Dota 2 patch pages.
