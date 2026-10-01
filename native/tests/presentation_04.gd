extends SceneTree
var game
var failures = 0
func _initialize(): call_deferred("run")
func check(ok,message):
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures += 1
func capture(name):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-04.png")
func run():
	game = preload("res://scenes/main.tscn").instantiate()
	game.progress_path = "res://build/presentation-04-save.json"
	root.add_child(game)
	game.selected = 2
	game.start_run()
	game.paused = true
	game.toast_time = 0
	await create_timer(0.5).timeout
	check(game.audio.bank.size()>=36,"Dedicated weapon, impact and six rarity sounds loaded")
	check(game.audio.music_players.size()==5 and game.audio.music_players[2].playing,"Menu score and per-biome combat music playing")
	var music = game.audio.music_players[0].stream
	check(music.loop_end>2000000,"Compressed WAV loop uses sample count, not byte count")
	game.sim.open_choices(false)
	await create_timer(0.5).timeout
	await capture("backpack-levelup")
	var charges = game.sim.rerolls
	game.sim.reroll_choices()
	await create_timer(0.4).timeout
	check(game.sim.rerolls==charges-1 and game.page=="upgrade","Reroll refreshes native upgrade screen")
	game.pick_upgrade(0)
	check(not game.sim.choosing,"One click applies normal upgrade")
	game.sim.open_choices(true)
	await create_timer(0.75).timeout
	check(game.page=="relic-spin" and game.sim.choosing,"Chest reel pauses simulation")
	await capture("relic-spin")
	await create_timer(2.1).timeout
	await capture("relic-landed")
	await create_timer(2.2).timeout
	check(game.page=="relic-spin" and game.sim.choosing,"Landed reward lingers indefinitely")
	var press = InputEventKey.new()
	press.keycode = KEY_SPACE
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	check(game.page=="playing" and not game.sim.choosing and game.sim.relics.size()==1,"Fresh key press awards exactly once and resumes")
	game.sim.choosing = true
	game.sim.option_is_relic = true
	game.sim.options = [{"type":"relic","id":"chronicle"}]
	game.present_upgrade(game.sim.options,true)
	await create_timer(3).timeout
	await capture("artifact-reveal")
	await create_timer(2).timeout
	Input.parse_input_event(press)
	await process_frame
	check("chronicle" in game.sim.relics,"Artifact reveal awards its actual reward")
	game.sim.weapons = {"frost":{"level":7,"evolved":true,"timer":0},"thunderstorm":{"level":7,"evolved":true,"timer":0},"lightning":{"level":7,"evolved":true,"timer":0},"orbital":{"level":7,"evolved":true,"timer":0},"winter":{"level":7,"evolved":true,"timer":0}}
	for i in range(90): game.sim.spawn_enemy(false,game.sim.pos+Vector2.from_angle(i*2.39)*(130+i%230),i%5)
	game.sim.build_grid()
	for frame in range(18):
		game.sim.invul = 100
		game.sim.tick(1.0/30,Vector2.RIGHT)
		await process_frame
	await capture("weapon-effects-backpack")
	game.queue_free()
	await process_frame
	print("PRESENTATION 04 / ",failures," failures")
	quit(failures)
