# 0.11.2 validation

- Voice banks: 531 checks pass across Voss, Kael and Vesper, including all 66 clips, event counts, hero isolation, anti-repeat, priority, mute, and switching. Existing Kael voice checks: 161 pass. Source and runtime audio hashes match.
- Actual main scene event wiring: 18 checks pass. Boss spawn/kill and loss use the selected survivor. Leaving the run now stops queued/active speech.
- Starter attacks: 638 focused timing checks pass. Release occurs at the painted attack frame; high haste and coarse updates retain every scheduled shot. Movement, pause, live retargeting, extra volleys, weapon unions, portals and endings verified. Kael's 23 slam checks still pass.
- Animation art: 152 checks pass. Four normal/Halloween six-pose sequences; 16 real-main captures reviewed, stable feet and no neighboring-frame bleed. Art is a mirrored three-quarter front view; dedicated rear attacks are not included.
- Rarity cards: 1,184 layout checks pass at 1024, 1280 and 3440 widths, with all six actual rarity rolls and long Artifact descriptions. Three repeated graphical tests each exit cleanly after shutting down audio. The reported native Godot tool crash did not recur; its exact cause remains unconfirmed.
- Boss health: 28 checks pass across all three maps/stages and Daily scaling. Baselines are 90,000 / 900,000 / 60,000,000. Innate DR still applies once; anchors remain weak points. Existing DR suite: 35 checks pass.
- Existing combat 54 and lifecycle integration 214 pass. Full run suite: 3,414 checks pass; repeated six-run lifecycle keeps stable node counts.

Exported Windows graphical smoke logs and screenshots are in build/release-0.11.2 and build/package-0112-*.log. Linux is exported as UNVERIFIED because no Linux runtime is available here. The restricted host's certificate/cache warnings are distinct from script errors.

Health is an intentional tenfold tuning change requested after the previous bosses died instantly. Tester runs are still needed to assess fight length and build thresholds; these checks verify mechanics rather than promising that every good build will win.
