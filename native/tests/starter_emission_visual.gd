extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	game=preload("res://scenes/main.tscn").instantiate()
	game.progress_path="res://build/emission-visual-profile.json"
	root.add_child(game);await create_timer(.3).timeout
	root.size=Vector2i(1280,720)
	for hero in [0,2]:
		game.selected=hero;game.chosen_mode="safari";game.start_run();game.paused=true
		var g=game.sim
		g.enemies.clear();g.boss=null;g.shots.clear();g.strikes.clear();g.zones.clear();g.hazards.clear()
		var id="revolver" if hero==0 else "lightning"
		g.weapons={id:{"level":1,"evolved":false,"timer":100}}
		for seasonal in [false,true]:
			for side in [-1,1]:
				g.halloween=seasonal;g.enemies.clear();g.shots.clear();g.strikes.clear()
				var e=g.spawn_enemy(false,g.pos+Vector2(side*210,0),0);e.p=g.pos+Vector2(side*210,0);e.hp=1e8;g.build_grid()
				preload("res://scripts/starter_attack.gd").start(g,id,Vector2(side,0),g.Rules.stats(g,id))
				g.time+=1;preload("res://scripts/starter_attack.gd").update(g)
				await create_timer(.08).timeout;await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://build/emission-%s-%s-%s.png"%[hero,seasonal,side])
		game.release_run()
	game.audio.shutdown();game.survivor_voice.stop();game.queue_free()
	await create_timer(.15).timeout;print("EMISSION VISUAL / 8 captures");quit()
