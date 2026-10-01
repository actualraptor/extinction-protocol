extends SceneTree
var game
var failures = 0
func _initialize(): call_deferred("run")
func check(ok,message):
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures += 1
func capture(name):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-06.png")
func run():
	game = preload("res://scenes/main.tscn").instantiate()
	game.progress_path = "res://build/presentation-06-save.json"
	var file = FileAccess.open(game.progress_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"amber":500,"runs":0,"wins":0,"research":{},"records":[]}))
	file.close()
	root.add_child(game)
	await create_timer(0.3).timeout
	await capture("menu")
	game.discovery_menu()
	await capture("archive")
	game.selected = 2
	game.start_run()
	game.paused = true
	game.toast_time = 0
	check(game.audio.music_players.size()==5,"Menu score and three combat tracks loaded")
	game.sim.pos = game.sim.landmarks[0].p
	game.sim.update_exploration()
	check(game.sim.landmarks[0].found,"Walking to a discovery records it")
	check(game.sim.landmarks[0].id in game.save_data.discoveries,"Discovery persists immediately")
	game.map_menu()
	await capture("map")
	game.resume()
	game.paused = true
	game.sim.weapons = {"lightning":{"level":10,"evolved":true,"timer":0},"frost":{"level":10,"evolved":true,"timer":0},"fire":{"level":10,"evolved":true,"timer":0},"shotgun":{"level":10,"evolved":true,"timer":0},"spear":{"level":10,"evolved":true,"timer":0}}
	game.sim.relics = ["flint","blood","magnet","coil","wrap","boots","momentum","lens"]
	game.sim.passives = {"damage":5,"area":5,"haste":5,"count":3}
	game.sim.open_choices(true)
	await create_timer(3).timeout
	await capture("union")
	check(game.page=="relic-spin" and game.sim.choosing,"Union lingers on same reel")
	var press = InputEventKey.new()
	press.keycode = KEY_SPACE
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	check(game.sim.weapons.has("whiteout") and game.sim.weapons.size()==4,"Claim merges two weapons into one")
	check("whiteout" in game.save_data.recipes,"New union recipe saved")
	game.sim.options = [{"type":"augment","id":"sorcery","rarity":"RARE","refinement":true}]
	game.sim.choosing = true
	game.sim.option_is_relic = true
	game.present_upgrade(game.sim.options,true)
	await create_timer(3).timeout
	await capture("refinement")
	Input.parse_input_event(press)
	await process_frame
	check(game.sim.augments.get("sorcery",0)==1,"Full satchel refinement uses one reel claim")
	game.sim.options = [{"type":"relic","id":"glass","replace":"flint"}]
	game.sim.choosing = true
	game.present_upgrade(game.sim.options,true)
	await create_timer(3).timeout
	await capture("replacement")
	Input.parse_input_event(press)
	await process_frame
	check("flint" in game.sim.relics and "glass" not in game.sim.relics,"Space keeps current relic and salvages challenger")
	game.sim.depth = 2
	game.sim.time = 900
	game.sim.weapons.thunderstorm = {"level":10,"evolved":true,"timer":0}
	game.sim.augments = {"sorcery":4,"fork":3,"conductor":3,"linger":3,"combustion":3,"pierce":3,"reach":3,"echo":2,"winterbite":3}
	game.sim.modifier_cache.clear()
	game.sim.spawn_boss(3)
	game.sim.pos = game.sim.boss.p+Vector2(130,150)
	for i in range(160): game.sim.spawn_enemy(false,game.sim.pos+Vector2.from_angle(i*2.39)*(120+i%360),i%14)
	game.sim.build_grid()
	game.sim.next_elite = 10000
	game.sim.cache_timer = 1000
	for frame in range(95):
		game.sim.invul = 100
		game.sim.xp = 0
		game.sim.relic_chests.clear()
		game.sim.tick(1.0/30,Vector2.ZERO)
		await process_frame
	game.sim.add_hazard("line",game.sim.pos+Vector2(-210,-170),0.28,35,1.2,0.6,90)
	game.sim.add_hazard("circle",game.sim.pos+Vector2(100,-70),0,90,1.1,0.6,90)
	game.sim.add_hazard("ring",game.sim.boss.p,0,230,1.0,0.6,90)
	await capture("boss-readability")
	game.ledger_menu()
	await capture("ledger")
	check(game.page=="ledger" and game.paused,"Damage ledger pauses run")
	press.keycode = KEY_B
	Input.parse_input_event(press)
	await process_frame
	check(game.page=="playing" and not game.paused,"B closes ledger even with focused UI controls")
	check(game.loadout_label.position.y+game.loadout_label.get_minimum_size().y*game.loadout_label.scale.y<game.xp_bar.position.y,"Loadout text cannot overlap footer controls or XP")
	game.paused = true
	game.sim.choosing = false
	game.sim.open_choices(false)
	await create_timer(0.8).timeout
	await capture("levelup")
	game.queue_free()
	game = null
	await process_frame
	await process_frame
	await process_frame
	print("PRESENTATION 06 / ",failures," failures")
	quit(failures)
