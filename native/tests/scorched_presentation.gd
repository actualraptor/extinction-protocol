extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game = preload("res://scenes/main.tscn").instantiate()
	game.progress_path = "res://build/scorched-presentation-save.json"
	root.add_child(game)
	game.start_run()
	game.paused = true
	game.sim.zones.clear()
	for i in range(3):
		game.sim.zones.append({"p":game.sim.pos+Vector2(200+i*120,-90+i*110),"radius":100.0,"id":"mortar","damage":10.0,"wait":0.0,"life":2.0,"duration":3.0,"age":1.0,"scorched":true})
	game.toast_time = 0
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/scorched-presentation.png")
	game.queue_free()
	await process_frame
	quit()
