extends SceneTree
var game
var failures = 0
func _initialize(): call_deferred("run")
func check(ok,message):
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures += 1
func key(code):
	var e = InputEventKey.new()
	e.keycode=code
	e.pressed=true
	Input.parse_input_event(e)
func capture(name):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-061.png")
func run():
	game=preload("res://scenes/main.tscn").instantiate()
	game.progress_path="res://build/ui-061-save.json"
	root.add_child(game)
	await create_timer(0.2).timeout
	game.start_run()
	game.sim.invul=999
	game.toast_time=0
	key(KEY_TAB)
	await process_frame
	check(game.page=="map" and not game.paused,"Tab opens live overlay")
	var before=game.sim.time
	await create_timer(0.15).timeout
	check(game.sim.time>before,"Simulation continues with map visible")
	await capture("overlay")
	key(KEY_TAB)
	await process_frame
	check(game.page=="playing","Tab closes overlay")
	var nav=preload("res://scripts/navigation.gd").new()
	nav.game=game
	for marker in game.sim.landmarks: marker.found=true
	check(nav.objective()==null,"No guidance to completed discoveries, chests or shrines")
	game.sim.landmarks[0].found=false
	check(nav.objective().id==game.sim.landmarks[0].id,"Guidance selects an undiscovered unlock")
	game.sim.pos=game.sim.landmarks[0].p
	game.sim.update_exploration()
	check(game.sim.landmarks[0].found,"Landmark arrival records discovery")
	nav.free()
	game.sim.relics=["blood","storm","lens","wrap","coil","boots","magnet","flint"]
	game.sim.passives={"crit":4,"armor":4,"area":4,"speed":3,"regen":3,"haste":4,"pickup":4,"damage":5,"count":3,"luck":3}
	key(KEY_B)
	await process_frame
	check(game.page=="ledger" and game.paused,"B opens paused backpack with stats")
	await capture("backpack")
	key(KEY_B)
	await process_frame
	check(game.page=="playing" and not game.paused,"B closes backpack")
	game.paused=true
	for child in game.hud_root.get_children():
		if child.get_script()==preload("res://scripts/backpack.gd") and not child.buffs_only:
			child._process(0)
			check(child._get_tooltip(Vector2(10,10)).length()>0,"Equipment hover has item name and rank")
	game.sim.pos=game.sim.landmarks[1].p+Vector2(90,70)
	game.sim.landmarks[1].found=false
	game.sim.spawn_boss(1)
	for size in [Vector2i(960,600),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(size)
		await create_timer(0.3).timeout
		await capture("hud-"+str(size.x))
	check(game.boss_bar.scale.x<1,"Large-window HUD scales down relative to arena")
	game.queue_free()
	game=null
	await process_frame
	await process_frame
	await process_frame
	print("UI 061 / ",failures," failures")
	quit(failures)

