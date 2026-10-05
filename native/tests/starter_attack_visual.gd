extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	game=preload("res://scenes/main.tscn").instantiate()
	game.progress_path="res://build/starter-visual-profile.json"
	root.add_child(game);await create_timer(.3).timeout
	root.size=Vector2i(1280,720)
	for hero in [0,2]:
		game.selected=hero;game.chosen_mode="safari";game.start_run();game.paused=true
		game.sim.enemies.clear();game.sim.boss=null
		var id="revolver" if hero==0 else "lightning"
		for seasonal in [false,true]:
			game.sim.halloween=seasonal
			preload("res://scripts/starter_attack.gd").start(game.sim,id,Vector2.RIGHT,game.sim.Rules.stats(game.sim,id))
			for phase in [.05,.35,.65,.85]:
				game.sim.time=game.sim.starter_attack.start+game.sim.starter_attack.duration*phase
				preload("res://scripts/starter_attack.gd").update(game.sim)
				await create_timer(.08).timeout;await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://build/starter-%s-%s-%s.png"%[hero,seasonal,int(phase*100)])
		game.release_run()
	game.audio.shutdown();game.survivor_voice.stop();game.queue_free()
	await create_timer(.15).timeout;print("STARTER VISUAL / 16 captures");quit()
