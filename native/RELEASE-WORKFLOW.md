# Release requirements

Every new version must include an upload-ready PNG of its patch notes. This is a standing user request. Use the game artwork, Cinzel headings and Source Sans 3 body text. Check text overflow and visually inspect the rendered PNG before delivery. Include a direct PNG link with each release. Preserve earlier release images.

Update native/scripts/patch_notes.gd for every release. Render the native notes page to the release PNG; do not use the old HTML layout.

Before changing latest notes, preserve the previous release in assets/patch-history.json. Keep complete source release notes and newest-first numeric version ordering.

Player-facing patch notes must contain only buffs, nerfs, content, gameplay or interface changes and fixes. Never include test counts, schema details, packaging or development commentary. Keep engineering evidence in PRIVATE-VALIDATION.md. Use illustrated game art and clear category headings inspired by Dota 2 patch pages.

For every release, publish native source to GitHub, upload Windows and unverified Linux packages, checksums and the native patch-notes PNG to a new versioned Release. Update docs/index.html, docs/site.js and README latest-version/download links, publish GitHub Pages, and verify the live page. Preserve older release assets. Keep the AI-assisted hobby-project disclosure visible.

Public release archives must contain only player-facing files. Never include gameplay/soundtrack/test launchers, isolated test profiles, test instructions, debug captures or private validation fixtures. Keep playtest packages separate. Check archive contents with an explicit allowlist before uploading.
