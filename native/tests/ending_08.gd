extends SceneTree
var game
var failures=0
func _initialize():call_deferred("run")
func check(ok,msg):
	if not ok:failures+=1
	print("PASS / " if ok else "FAIL / ",msg)
func capture(name):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/ending-"+name+"-08.png")
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/ending08-save.json";root.add_child(game)
	await create_timer(.2).timeout
	game.chosen_mode="safari";game.start_run();game.paused=true
	game.sim.boss_time=210;game.sim.update_boss(.01)
	check(game.sim.extinction_timeout and not game.sim.active,"Boss timer triggers extinction defeat")
	check(game.page=="extinction-ending" and game.defeat_cinematic!=null,"Timed defeat starts cinematic before scoreboard")
	await create_timer(1.35).timeout;await capture("shockwave")
	await create_timer(2.9).timeout;await capture("dark")
	check(game.page=="extinction-ending","Darkness holds before results")
	await create_timer(1.3).timeout;await capture("summary")
	check(game.page=="summary" and not game.hud_root.visible,"Scoreboard appears after cinematic")
	game.main_menu();await process_frame
	check(game.defeat_cinematic==null,"Leaving results cleans up cinematic")
	print("ENDING 08 / failures ",failures);quit(1 if failures else 0)
