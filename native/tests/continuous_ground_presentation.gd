extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game = preload("res://scenes/main.tscn").instantiate()
	game.progress_path = "res://build/continuous-ground-save.json"
	root.add_child(game)
	game.start_run()
	game.paused = true
	for id in ["cradle","frostbreak","observatory"]:
		game.sim.map_id = id
		game.sim.terrain.layout = game.sim.Maps.DATA[id].layout
		game.sim.pos = Vector2(7000,0)
		game.sim.terrain.configure({"regions":[{"p":Vector2(7000,0),"radius":5000.0,"kind":"grove" if id=="cradle" else "ice" if id=="frostbreak" else "ruins","color":game.sim.Maps.DATA[id].grounds[0]}],"landmarks":[{"id":"test","name":"ANCIENT LANDMARK","p":Vector2(7380,-160),"art":6,"scale":270.0}]},0)
		game.toast_time = 0
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/continuous-ground-"+id+".png")
	game.queue_free()
	await process_frame
	quit()
