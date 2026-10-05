extends SceneTree
const Slam=preload("res://scripts/kael_slam.gd")
const Combat=preload("res://scripts/combat_engine.gd")
var game
func _initialize():call_deferred("run")
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/fracture-preview-profile.json"
	root.add_child(game);await create_timer(.3).timeout
	game.selected=1;game.chosen_mode="safari";game.start_run();game.paused=true
	root.size=Vector2i(1280,720)
	var g=game.sim;var world=game.world
	world.set_process(false);world.shake_enabled=false
	g.halloween=false;g.enemies.clear();g.boss=null;g.weapons.clear();g.hazards.clear();g.zones.clear();g.shots.clear();g.map_id="cradle";g.depth=0
	for i in range(12):
		var e=g.spawn_enemy(false,g.pos+Vector2.from_angle(i*TAU/12)*180);e.hp=1e8;e.max_hp=e.hp
	g.build_grid()
	for test in [["club",false,.8,180.0,"normal"],["club",true,.12,280.0,"world-breaker-fast"],["earthshaker",true,.04,320.0,"earthshaker-extreme"]]:
		g.weapons.clear();g.weapons[test[0]]={"level":1,"evolved":test[1],"timer":9999,"casts":0}
		g.echoes.clear();g.kael_attack.clear();world.effects.clear()
		var s=g.Rules.stats(g,test[0]);s.cooldown=test[2];s.radius=test[3];s.repeat=0
		var next=g.time;var base=g.time
		for frame in range(90):
			world._process(1.0/60);g.time+=1.0/60;Combat.update(g,1.0/60)
			if g.time>=next:Slam.start(g,test[0],Vector2.RIGHT,s);next=g.time+test[2]
			if frame in [20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88]:
				await process_frame;await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://build/fracture-%s-%s.png"%[test[4],frame])
	game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free()
	await create_timer(.15).timeout;print("KAEL FRACTURE PREVIEW / 54 captures");quit()
