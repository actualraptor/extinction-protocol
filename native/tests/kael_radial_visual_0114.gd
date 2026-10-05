extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/kael-radial-visual-profile.json"
	root.add_child(game);await create_timer(.2).timeout;root.size=Vector2i(1280,720)
	game.selected=1;game.chosen_mode="safari";game.start_run();game.paused=true
	var g=game.sim;g.enemies.clear();g.boss=null;g.hazards.clear();g.shots.clear();g.strikes.clear()
	for map in ["cradle","frostbreak","observatory"]:
		g.map_id=map;g.depth=0
		for id in ["club","earthshaker"]:
			game.world.effects.clear();g.echoes.clear()
			g.weapons={id:{"level":10,"evolved":id=="earthshaker","timer":100}}
			var stats=g.Rules.stats(g,id);stats.repeat=0
			preload("res://scripts/kael_slam.gd").start(g,id,Vector2.RIGHT,stats)
			g.time+=g.kael_attack.duration*.64;preload("res://scripts/kael_slam.gd").update(g)
			for i in range(3):
				g.time+=.065;g.update_weapons(.065);await create_timer(.035).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/kael-radial-%s-%s.png"%[map,id])
	game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free()
	await create_timer(.15).timeout;print("KAEL RADIAL VISUAL / 6 captures");quit()
