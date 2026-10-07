extends SceneTree
const R=preload("res://scripts/remnant_system.gd")
const OUT="D:/Utveckling CODEX/Dummy test/native/build/"
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1920,1080);root.content_scale_size=root.size
	var game=preload("res://scripts/main.gd").new();game.progress_path=OUT+"ground-mobs-profile.json";root.add_child(game)
	await process_frame
	for child in game.layer.get_children():
		if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
	game.selected=5;game.chosen_mode="safari";game.start_run();game.paused=true;game.clear_menu()
	var g=game.sim;g.enemies.clear();g.weapons.clear();g.invul=1000;g.landmarks.clear();g.portal=null
	g.spawn_boss(1);g.boss.p=g.pos+Vector2(0,-150);R.leave(g,g.boss);g.boss=null;g.enemies.clear()
	var corpse=g.boss_corpses[0];corpse.raising=true;corpse.ritual=4;corpse.stain_time=4
	var ground=game.world.get_children().filter(func(node):return node.get_script()==preload("res://scripts/ritual_ground.gd"))[0]
	for point in [1.0,3.0,5.0,8.0,11.0,12.0]:
		var samples=[];var draws=[]
		corpse.consumed=point>=12;corpse.raising=point<12
		for frame in range(45):
			corpse.ritual=minf(12,point+frame/60.0);corpse.stain_time=corpse.ritual;g.time=corpse.ritual
			await process_frame;await RenderingServer.frame_post_draw
			if frame>5:
				samples.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
				draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var total=0.0;var calls=0.0
		for sample in samples:total+=sample
		for sample in draws:calls+=sample
		print("RITUAL PROFILE ",point," seconds: process_ms=",snappedf(total/samples.size(),.01)," draw_calls=",snappedf(calls/draws.size(),1))
	game.sim=null;game.queue_free();await process_frame;quit()
