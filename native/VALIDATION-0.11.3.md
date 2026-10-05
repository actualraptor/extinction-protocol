# 0.11.3 local validation

Boss pursuit and emission: 107 checks pass across all three maps, six roaming bosses and stationary Extinction. Recovery navigation is terrain-aware; committed attacks retain their windups. Normal/Halloween and mirrored muzzle/crystal positions verified, including follow-up volleys and vertical targets. Eight native graphical captures were inspected.

Integrated expedition/Daily runs: 3,416 checks pass, combining bosses, portals, chest rewards and evolutions. Existing starter attack timing: 638 checks. Lifecycle: 214 checks. Boss resistance: 35 checks. Boss health: 28 checks. Encounter mechanics: 58 checks. Obsolete fixtures were updated for linear crit chance and the existing tenfold boss-health increase.

Crit/Luck probability checks pass: 10,000 rolls at 250% critical chance produced 4,973 double and 5,027 triple crits. Every non-Common tier increases monotonically across tested Luck values; probabilities normalize to 100%. At +84% Luck without pity: 14.925% Common, 38.776% Uncommon, 25.522% Rare, 14.015% Epic, 5.709% Legendary and 1.052% Artifact. Seven crit/charger regression checks pass. Six critical tiers were visually verified; number count and font-size growth remain bounded.

Starter audio: 34 runtime checks pass. Nine new WAVs have no clipped samples, peak amplitude at most 0.82, and RMS capped below their original banks. Original files and SHA-256 backups are preserved. Tonal preference remains a human playtest decision; an eight-second repeated listening preview accompanies the backups.

Windows release executable launches and exits cleanly with Voss/Halloween and Vesper/original verification modes. Both render starter attacks. No script or missing-resource errors in export/smoke logs. Restricted-environment certificate-store, editor user-directory and shader-cache warnings persist. Release PNG was inspected for text fit. Packages use an explicit allowlist and archive integrity checks; player reports, saves, previews and logs are excluded.

Linux was exported on Windows and remains an UNVERIFIED test candidate. No Linux runtime test was performed.
