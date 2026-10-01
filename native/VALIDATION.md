# Native 0.2 verification

Godot 4.7.2, Windows x64. Native GPU rendering verified on the available NVIDIA GPU through the Compatibility renderer. Release EXE opened and exercised through Windows UI automation; character selection, expedition start, death summary, local progression write and restart controls were present. The gameplay preview was captured from Godot's rendered viewport.

- 38 simulation integration checks passed, including all eight weapons, XP, evolution, relics, collision safe zones, accurate effective damage, seeded placement, daily-mode research isolation, all meteor phase gates, victory and deadline failure.
- Full-run regression: 991.4 seconds of simulation, 4,303 kills, peak 659 total entities including special enemies; final fight 91.4 seconds. This test uses an invulnerable pilot and a prepared six-evolution build.
- Isolated boss throughput comparison with invulnerable pilots: mediocre build timed out at 210 seconds with 1,090,787 core HP remaining; fully evolved six-weapon build won in 76.9 seconds. These are throughput checks, not player win rates.
- Save write verified in the native app's progress JSON. Windows package contains the EXE, quick-start instructions, engine license and third-party notices.
- No script or renderer errors in the native visual smoke-test logs. Headless sandbox runs emit host certificate-store/user-directory warnings; these do not occur in the normal native visual run.

Remaining validation: extended human runs for each character, lower-end hardware, Windows versions/drivers beyond this machine, long-session audio comfort, and item/build win-rate distributions. Current animations and synthesized audio are the first production pass.
