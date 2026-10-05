extends SceneTree
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():call_deferred("run")
func run():
	var game=preload("res://scenes/main.tscn").instantiate()
	game.progress_path="res://build/fortune-lifecycle-profile.json"
	root.add_child(game);await create_timer(.3).timeout
	var baseline=0
	for cycle in range(6):
		game.start_run();game.paused=true;game.audio.play("lightning");game.map_menu()
		await create_timer(.15).timeout
		game.release_run();game.main_menu();game.audio.shutdown();game.survivor_voice.stop()
		await create_timer(.35).timeout
		var count=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		if cycle==0:baseline=count
		check(count==baseline,"Repeated start/map/menu node ownership remains stable")
		print("LIFECYCLE / cycle=",cycle," nodes=",count," objects=",Performance.get_monitor(Performance.OBJECT_COUNT))
	game.queue_free();game=null;await create_timer(.5).timeout
	print("FORTUNE LIFECYCLE / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
