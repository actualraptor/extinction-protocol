extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game = preload("res://scenes/main.tscn").instantiate()
	game.progress_path = "res://build/lifecycle-save-06.json"
	root.add_child(game)
	game.start_run()
	game.paused = true
	game.map_menu()
	await process_frame
	game.resume()
	game.ledger_menu()
	await process_frame
	game.resume()
	game.sim.open_choices(true)
	await process_frame
	game.release_run()
	game.queue_free()
	game = null
	await process_frame
	await process_frame
	quit()
