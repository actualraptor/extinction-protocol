extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=preload("res://scenes/main.tscn").instantiate()
 game.progress_path="res://build/supplies-ui-save.json"
 root.add_child(game)
 await process_frame
 game.chosen_mode="safari";game.start_run();game.paused=true
 game.sim.options=[{"type":"supplies","id":"supplies"}];game.sim.choosing=true
 game.upgrade_menu(game.sim.options,false)
 await create_timer(.35).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/supplies-ui-091.png")
 var amber=game.sim.amber;game.sim.choose(0)
 assert(game.sim.amber==amber+25)
 game.release_run();game.queue_free();await process_frame;await process_frame
 print("SUPPLIES UI / PASS")
 quit()
