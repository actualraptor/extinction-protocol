extends SceneTree
var game
func _initialize(): call_deferred("run")
func capture(name):
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-04.png")
func run():
	game = preload("res://scenes/main.tscn").instantiate()
	game.progress_path = "res://build/biome-presentation-save.json"
	root.add_child(game)
	game.start_run()
	game.paused = true
	game.sim.depth = 1
	game.sim.time = 630
	game.sim.spawn_boss(2)
	game.sim.boss.hp *= 0.65
	game.toast_time = 0
	game.sim.xp = game.sim.xp_goal*0.6
	for i in range(9):
		var e = game.sim.spawn_enemy(false,Vector2(-460+i%3*440,80+floori(i/3.0)*95),i+5)
		e.size = 33
		e.mutated = false
	await capture("bestiary-boss-hud")
	game.sim.kill(game.sim.boss)
	game.sim.choose(0)
	game.clear_menu()
	game.page = "playing"
	game.sim.linger = 45
	game.toast_time = 0
	await capture("biome-portal")
	game.sim.enter_portal()
	await capture("rift-transition")
	game.queue_free()
	await process_frame
	quit()
