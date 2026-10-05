extends SceneTree
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():call_deferred("run")
func run():
	var game=preload("res://scenes/main.tscn").instantiate()
	game.progress_path="res://build/voice-events-0112-profile.json"
	root.add_child(game);await create_timer(.2).timeout
	game.chosen_mode="safari"
	for hero in [0,1,2]:
		game.selected=hero;game.start_run();game.paused=true
		var key=game.survivor_voice.HERO_KEYS[hero]
		check(game.survivor_voice.hero_key==key and game.sim.hero==hero,"Run binds actual hero")
		check(game.survivor_voice.current_event=="boss_spawn","Actual boss spawn triggers voice")
		check(game.survivor_voice.player.stream.resource_path.contains("/"+key+"/"),"Only selected hero speaks")
		game.sim.voice_event.emit("boss_killed")
		check(game.survivor_voice.pending=="boss_killed","Simulation boss kill reaches correct voice queue")
		game.sim.finish(false)
		check(game.survivor_voice.current_event=="death" and game.survivor_voice.pending=="","Actual loss interrupts voice with death")
		game.release_run();check(game.survivor_voice.current_event=="" and not game.survivor_voice.player.playing,"Leaving run stops voice")
	game.audio.shutdown();game.survivor_voice.stop();game.queue_free();game=null
	await create_timer(.5).timeout
	print("VOICE EVENTS UI / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
