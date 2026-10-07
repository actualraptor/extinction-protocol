extends SceneTree
const R=preload("res://scripts/remnant_system.gd")
const OUT="D:/Utveckling CODEX/Dummy test/native/build/"
class Bench extends Node2D:
	var sim
	var cost_usec=0
	func screen(p):return p-sim.pos+Vector2(960,540)
	func visible_rect():return Rect2(0,0,1920,1080)
	func _process(_dt):queue_redraw()
	func _draw():
		var started=Time.get_ticks_usec()
		preload("res://scripts/remnant_system.gd").draw(self,sim)
		cost_usec=Time.get_ticks_usec()-started
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
	game.world.hide();game.world.process_mode=Node.PROCESS_MODE_DISABLED
	var bench=Bench.new();bench.sim=g;root.add_child(bench)
	var ground=preload("res://scripts/ritual_ground.gd").new();ground.world=bench;ground.z_index=-1;bench.add_child(ground)
	for point in [1.0,3.0,5.0,8.0,11.0,14.0,17.0,18.0]:
		var samples=[];var draws=[]
		corpse.consumed=point>=R.RITUAL;corpse.raising=point<R.RITUAL
		for frame in range(45):
			corpse.ritual=minf(R.RITUAL,point+frame/60.0);corpse.stain_time=corpse.ritual;g.time=corpse.ritual
			await process_frame;await RenderingServer.frame_post_draw
			if frame>5:
				samples.append(bench.cost_usec/1000.0)
				draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var total=0.0;var calls=0.0
		for sample in samples:total+=sample
		for sample in draws:calls+=sample
		print("RITUAL PROFILE ",point," seconds: ritual_submission_ms=",snappedf(total/samples.size(),.01)," draw_calls=",snappedf(calls/draws.size(),1))
	game.sim=null;game.queue_free();await process_frame;quit()
