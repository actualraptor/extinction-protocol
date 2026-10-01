extends SceneTree
var game
var failures = 0
func check(ok,message):
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func capture(name):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-05.png")
func press(echo = false):
	var event = InputEventKey.new()
	event.pressed = true
	event.echo = echo
	event.keycode = KEY_W
	Input.parse_input_event(event)
func run():
	game = preload("res://scenes/main.tscn").instantiate()
	game.progress_path = "res://build/reveal-05-save.json"
	root.add_child(game)
	game.selected = 2
	game.start_run()
	game.paused = true
	game.sim.weapons = {"lightning":{"level":10,"evolved":true,"timer":0},"frost":{"level":10,"evolved":true,"timer":0}}
	game.sim.open_choices(true)
	await create_timer(0.5).timeout
	press()
	await process_frame
	check(game.sim.choosing,"Input during spinning cannot skip the result")
	await create_timer(3).timeout
	press(true)
	await process_frame
	check(game.sim.choosing,"Held-key echo cannot dismiss landed fusion")
	await capture("whiteout-union")
	press()
	await process_frame
	check(game.sim.weapons.has("whiteout") and game.sim.weapons.size()==1 and not game.sim.choosing,"Native fusion reel consumes ingredients and frees a slot on fresh movement input")
	game.sim.enemies.clear()
	game.sim.weapons.thunderstorm = {"level":4,"evolved":false,"timer":0}
	for i in range(20):
		var e = game.sim.spawn_enemy(false,game.sim.pos+Vector2.from_angle(i*2.4)*(100+i*15),i%14)
		e.hp = 100000
		e.frozen = 10
	game.sim.build_grid()
	for frame in range(13):
		game.sim.time += 1.0/30
		game.sim.update_weapons(1.0/30)
		await process_frame
	game.world.flashes = 0
	await capture("frozen-storm")
	game.queue_free()
	await process_frame
	print("REVEAL 05 / ",failures," failures")
	quit(failures)
