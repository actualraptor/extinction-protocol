# Extinction Protocol — Private test 0.9.0

Windows: extract the ZIP, then run Extinction Protocol.exe. No installer needed. Close the old build before starting this one.

Linux: this is an UNVERIFIED native x86-64 test candidate. Extract the .tar.gz (it preserves the executable bit) and run ./"Extinction Protocol.x86_64". Godot's Compatibility renderer requires working OpenGL drivers. This build was exported on Windows; no Linux runtime or Steam Deck is available here to validate it. Report startup/graphics/audio issues before treating Linux as supported.

Progress is stored outside the install folder. Updating the game does not require copying saves into the new folder. This version migrates older progression and keeps local safety copies. Do not delete the Godot user-data folder. To preserve a manual copy first, copy the entire Extinction Protocol user-data directory elsewhere.

Windows saves: %APPDATA%/Godot/app_userdata/Extinction Protocol
Linux default saves: ~/.local/share/godot/app_userdata/Extinction Protocol

Private test focus:
- Complete an Expedition through every boss and portal, then restart.
- Evolve a weapon and create a union from a chest. Confirm the freed weapon slot.
- Play Daily: each level and chest should spin, pause on the result, then continue once.
- Buy an Archive upgrade, restart the application, and confirm amber/unlocks/research.
- Try your usual window size/fullscreen and HUD scale. Note any clipped text.

On a problem, include the version, mode, character, map, approximate run time, screenshot/video and the run report from the end screen. Logs live in the user-data logs directory; reports in reports. A test report may not exist if the process crashes before the run ends. Keep the save when reporting a progression issue.

Steam features are not connected yet. Daily rankings remain local. No Steam account is required to run this private build.
