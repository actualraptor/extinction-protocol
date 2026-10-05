# Kael voice recordings

Eighteen user-provided recordings copied without audio changes from
`Voicelines/Kael`. Original audio is preserved under the same standardized names
as runtime copies: `kael_<event>_<number>.mp3`, starting at 1. SHA-256 content
matching and the old/new names are recorded in `rename-manifest.json`.
Categories: chosen (3), boss spawn (3), boss killed
(2), death (2), hurt (3), level up (3), low health (2).

No transcript is embedded in the game assets. Playback uses an independent RNG,
avoids consecutive identical variants, limits incidental chatter and uses one
speech channel with a priority queue for boss announcements and death.
