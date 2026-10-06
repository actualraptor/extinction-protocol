# Character HUD art

Selectable HUDs in this pass: Kael, Mara Voss, Vesper, Nagash. Each is unlocked with its character. Existing Iona/Orin gameplay retains fallback art; they have no separate selectable HUD yet.

Master frame, event banner, portrait, level badge, resource shell, weapon/item slots and utility plaques are independent complete assets. Health uses a shared shaped ruby insert clipped by percentage underneath character-specific foreground trim. The shell shader removes only the dark aperture; theme aperture coordinates are defined in hud_resource_bar.gd.

The HUD layout is shared and attached to the viewport bottom. XP retains the accepted previous design. Inventory overflow uses eight-item pages and never discards carried items. The minimap and full map share markers.

Run tests/hero_hud.gd with Godot to render four characters at three resolutions, check bottom attachment, unlock gating, paging and resource fill ratios. Live screenshots are written to build/hud-concepts.
