# 0.14.3 Windows performance review

Hardware: NVIDIA RTX 5070 Ti, OpenGL Compatibility renderer. Silent graphical tests used the exported EXE's embedded package with the same Godot 4.7.2 engine, not a headless renderer. Each sample ran for 20 seconds, excluding its first five seconds from frame statistics.

| Scenario | Resolution | Average frame time | 95th percentile |
| --- | --- | --- | --- |
| T-rex + 400 enemies, exported | 1280 x 800 | 15.84 ms | 18.95 ms |
| Triceratops + 400 enemies, final exported package | 1280 x 800 | 16.93 ms | 20.69 ms |
| Meteor + 400 enemies, exported public encounter | 1280 x 800 | 10.99 ms | 14.72 ms |

These captures contain no runtime errors. The reported 2 FPS failure was not reproduced on this hardware. The withdrawn package did repeatedly attempt to load an external stomp image that was absent from its archive. Attack textures are now imported package resources; missing runtime dependencies and audio assets were restored. Experimental beam audio is gated behind its test flag.

These measurements cover short automated encounters on one PC. They do not establish low-end hardware compatibility or a full-run performance guarantee. Meteor's public encounter still uses its existing public presentation; the private reconstructed model is not enabled by the public export feature.
