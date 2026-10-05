# Asset provenance — Fortune and Fang

Halloween selection portraits were generated with the built-in ImageGen tool on 2026-10-05 using the existing five-character selection screenshot as reference. Sheet: `assets/harvest-portraits-011.png`. No third-party character artwork was used. Original portraits remain available when Hollow Harvest is disabled.

Prompt specification: a transparent five-character horizontal sheet, full silhouettes with margins and consistent foot baselines, painterly fantasy style matching the original characters. Left to right: Kael, muscular bearded Neanderthal wielding a glowing pumpkin club; Mara Voss, red-haired leather-clad gunslinger with bat shoulder accents and pumpkin charm; Vesper, adult dark-haired purple witch with pointed hat and sapphire staff; Iona, white-haired polar hunter with goggles, fossil harpoon and skull clasp; Orin, masked lost astronomer with a haunted violet lantern. No text, frames, backdrop, detached fragments or neighboring-cell overlap.

Individual portraits were isolated into `assets/clean-icons/portrait-halloween-*.png`. The normal Iona portrait was cleaned from the existing sheet to remove a detached neighboring fragment. Boss icons and the full item/weapon/upgrade library were extracted and alpha-cleaned from existing project artwork; original sheets remain intact. Tools and authored crop regions are included in the source tree.

The 1400 × 2795 patch-note PNG is typeset from the same player-facing entries as the in-game notes, using existing Hollow Harvest cover art, clean game icons, Cinzel and Source Sans 3. It contains real rendered text rather than generated lettering. Generator: `tools/release_fortune_011.py`.
