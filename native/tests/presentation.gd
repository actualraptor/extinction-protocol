extends SceneTree
var game
var failures = 0
func check(ok,message):
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func capture(name):
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-03.png")
func run():
	game = preload("res://scenes/main.tscn").instantiate()
	game.progress_path = "res://build/test-progress.json"
	var file = FileAccess.open(game.progress_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"amber":321,"wins":2,"runs":9,"research":{"power":2},"records":[],"settings":{"sound":false,"music":false,"shake":false}}))
	file.close()
	root.add_child(game)
	check(game.save_data.amber==321 and game.save_data.research.power==2,"Existing version-one progression loads")
	game.save_data.amber += 7
	game.persist()
	game.load_progress()
	check(game.save_data.amber==328 and FileAccess.file_exists("res://build/test-progress.backup.json"),"Atomic progression save preserves backup")
	await capture("menu")
	game.characters()
	await capture("characters")
	game.selected = 2
	game.chosen_mode = "expedition"
	game.start_run()
	game.paused = true
	game.sim.weapons = {"winter":{"level":7,"evolved":false,"timer":0.0},"pyre":{"level":7,"evolved":false,"timer":0.0},"lightning":{"level":7,"evolved":false,"timer":0.0},"aegis":{"level":7,"evolved":false,"timer":0.0}}
	game.sim.pos = Vector2(340,330)
	for i in range(120): game.sim.spawn_enemy(false,game.sim.pos+Vector2.from_angle(i*2.39)*(130+i%200),i%5)
	game.sim.build_grid()
	for id in game.sim.Pickups.DEFINITIONS:
		game.sim.pickups.append({"id":id,"p":game.sim.pos+Vector2(-220+game.sim.pickups.size()*75,190),"life":60.0,"magnet":false})
	game.sim.update_weapons(0.1)
	await capture("auras-terrain")
	game.sim.open_choices(false)
	await create_timer(0.3).timeout
	game.sim.options = [{"type":"weapon","id":"winter"},{"type":"augment","id":"pulse"},{"type":"weapon","id":"aegis"}]
	game.upgrade_menu(game.sim.options,false)
	await capture("level-up")
	check(game.page=="upgrade" and game.sim.choosing,"Level choices pause simulation")
	game.pick_upgrade(1)
	check(game.sim.augments.get("pulse",0)==1 and not game.sim.choosing,"New upgrade cards apply and resume")
	game.sim.open_choices(true)
	await capture("chest-anticipation")
	await create_timer(2.4).timeout
	await capture("relic-reveal")
	check(game.page=="relic-spin" and game.sim.choosing,"Reel reveal keeps gameplay paused")
	await create_timer(2.5).timeout
	var press = InputEventKey.new()
	press.keycode = KEY_SPACE
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	check(game.sim.relics.size()==1 and not game.sim.choosing,"Relic applies exactly one reward after fresh input")
	game.pause_menu()
	check(game.paused and game.page=="pause","Pause screen")
	game.resume()
	check(not game.paused,"Pause resumes")
	game.start_run()
	game.paused = true
	check(game.sim.relics.is_empty() and game.sim.time==0 and game.sim.augments.is_empty(),"Restart resets all run-only systems")
	# Render a stress pack with live FX. Do not bank currency or touch real saves.
	game.sim.time = 425
	game.sim.cache_timer = 9999
	game.sim.shrine_done = true
	game.sim.next_boss = 600
	game.sim.weapons = {"winter":{"level":10,"evolved":true,"timer":0},"frost":{"level":10,"evolved":true,"timer":0},"lightning":{"level":10,"evolved":true,"timer":0},"orbital":{"level":10,"evolved":true,"timer":0}}
	for i in range(2200): game.sim.spawn_enemy(false,game.sim.pos+Vector2.from_angle(i*2.399)*(70+i%800),4).hp=1000000
	game.sim.build_grid()
	var ticks = []
	for frame in range(180):
		var start = Time.get_ticks_usec()
		game.sim.invul = 10
		game.sim.tick(1.0/60,Vector2.RIGHT)
		await process_frame
		ticks.append((Time.get_ticks_usec()-start)/1000.0)
	await capture("horde-stress")
	ticks.sort()
	print("RENDER STRESS / median ",ticks[90],"ms / p95 ",ticks[171],"ms / ",game.sim.enemies.size()," enemies, four apex weapons; frame+simulation wall time")
	# Repeat with live fixed-step gameplay instead of coroutine-driven ticks.
	game.sim.invul = 100
	game.paused = false
	ticks.clear()
	var last = Time.get_ticks_usec()
	for frame in range(180):
		await process_frame
		var now = Time.get_ticks_usec()
		ticks.append((now-last)/1000.0)
		last = now
	ticks.sort()
	print("LIVE STRESS / median ",ticks[90],"ms / p95 ",ticks[171],"ms / fps ",Engine.get_frames_per_second()," / ",game.sim.enemies.size()," enemies")
	game.queue_free()
	await process_frame
	print("PRESENTATION RESULT / ",failures," failures")
	quit(failures)
