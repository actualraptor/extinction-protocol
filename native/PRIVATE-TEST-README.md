# Extinction Protocol — Hobby playtest 0.13.1 / Framed

Halloween is enabled by default for this release. Settings → Hollow Harvest theme restores the original art and music when disabled. Your choice is saved. Kael, Voss and Vesper have event-based voice lines with chances and cooldowns; use the voice volume slider to silence them. Separate sliders cover effects, music, voices and cinematics. The new HUD is a first iteration and will have issues, especially layout, scaling and experience-bar polish.

Windows: extract the ZIP, then run Extinction Protocol.exe. No installer needed. Close the old build before starting this one.

Linux: this is an UNVERIFIED native x86-64 test candidate. Extract the .tar.gz (it preserves the executable bit) and run ./"Extinction Protocol.x86_64". Godot's Compatibility renderer requires working OpenGL drivers. This build was exported on Windows; no Linux runtime or Steam Deck is available here to validate it. Report startup/graphics/audio issues before treating Linux as supported.

Progress is stored outside the install folder. Updating the game does not require copying saves into the new folder. This version migrates older progression and keeps local safety copies. Do not delete the Godot user-data folder. To preserve a manual copy first, copy the entire Extinction Protocol user-data directory elsewhere.

Windows saves: %APPDATA%/Godot/app_userdata/Extinction Protocol
Linux default saves: ~/.local/share/godot/app_userdata/Extinction Protocol

Private test focus:
- Stack different tiers of the same relic; check XP growth and the eight-type satchel limit.
- Try the local atlas, O overview, F recenter, middle-drag pan and wheel zoom.
- Complete an Expedition through every boss and portal, then restart.
- Evolve a weapon and create a union from a chest. Confirm the freed weapon slot.
- Play Daily: each level and chest should spin, pause on the result, then continue once.
- Buy an Archive upgrade, restart the application, and confirm amber/unlocks/research.
- Try your usual window size/fullscreen and HUD scale. Note any clipped text.

On a problem, include the version, mode, character, map, approximate run time, screenshot/video and the run report from the end screen. Logs live in the user-data logs directory; reports in reports. A test report may not exist if the process crashes before the run ends. Keep the save when reporting a progression issue.

Steam features are not connected yet. Daily rankings remain local. No Steam account is required to run this private build.
