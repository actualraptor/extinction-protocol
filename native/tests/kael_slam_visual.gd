extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	game=preload("res://scenes/main.tscn").instantiate()
	game.progress_path="res://build/slam-visual-profile.json"
	root.add_child(game);await create_timer(.3).timeout
	game.selected=1;game.chosen_mode="safari";game.start_run();game.paused=true
	game.sim.enemies.clear();game.sim.boss=null;root.size=Vector2i(1280,720)
	for seasonal in [false,true]:
		game.sim.halloween=seasonal
		var stats=game.sim.Rules.stats(game.sim,"club");stats.cooldown=.6
		preload("res://scripts/kael_slam.gd").start(game.sim,"club",Vector2.RIGHT,stats)
		for phase in [.05,.35,.65,.85]:
			game.sim.time=game.sim.kael_attack.start+game.sim.kael_attack.duration*phase
			preload("res://scripts/kael_slam.gd").update(game.sim)
			await create_timer(.08).timeout;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/slam-%s-%s.png"%[seasonal,int(phase*100)])
	game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free()
	await create_timer(.15).timeout;print("KAEL SLAM VISUAL / 8 captures");quit()
