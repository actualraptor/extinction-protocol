extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/reel087-save.json";root.add_child(game)
 await create_timer(.3).timeout
 game.chosen_mode="daily";game.start_run();game.paused=true
 game.sim.open_choices(false)
 await create_timer(3.2).timeout
 assert(game.sim.choosing)
 assert(game.page=="relic-spin")
 var reel=game.menu_root.get_child(0)
 assert(reel.daily_level and reel.landed and reel.offered_data.size()>0)
 reel.awarded.emit()
 assert(not game.sim.choosing)
 game.sim.open_choices(true)
 await create_timer(3.2).timeout
 assert(game.sim.choosing and game.page=="relic-spin")
 game.menu_root.get_child(0).awarded.emit()
 assert(not game.sim.choosing)
 print("DAILY REELS / level and chest reveal, hold and claim passed")
 game.release_run();game.queue_free();await process_frame;await process_frame;quit()

