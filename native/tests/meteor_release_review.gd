extends SceneTree
var game
var frames=[]
const OUT="D:/Utveckling CODEX/Dummy test/native/build/meteor-release-capture"

func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.audio.enabled=false
	game.audio.music_enabled=false
	game.progress_path="res://build/meteor-review-profile.json"
	game.start_run()
	game.sim.spawn_boss(3)
	game.sim.invul=9999
	game.paused=true
	await process_frame
	await RenderingServer.frame_post_draw
	game.sim.meteor_entry_time=4.2
	game.sim.boss_time=0
	if "--meteor-late-stress" in OS.get_cmdline_user_args():
		game.sim.meteor_entry_time=0
		game.sim.boss_time=175
		game.sim.phase=3
		game.sim.pos=game.sim.boss.p+Vector2(230,0)
	game.paused=false
	assert(game.sim.meteor_entry_time>0 or "--meteor-late-stress" in OS.get_cmdline_user_args(),"Public Meteor entrance is disabled")
	var started=Time.get_ticks_usec()
	var previous=started
	var snapshots=[.6,1.4,2.3,3.2,3.7,4.1,5.0,10.0,20.0]
	var next_snapshot=0
	var duration=25.0
	if "--performance-horde" in OS.get_cmdline_user_args():
		for index in range(400):game.sim.spawn_enemy(false,game.sim.pos+Vector2.from_angle(index*2.39996)*(120+index%12*30),0,false)
	while (Time.get_ticks_usec()-started)/1000000.0<duration:
		await process_frame
		var now=Time.get_ticks_usec()
		var elapsed=(now-started)/1000000.0
		if elapsed>6:frames.append((now-previous)/1000.0)
		previous=now
		var visual_elapsed=4.2-game.sim.meteor_entry_time+game.sim.boss_time
		if next_snapshot<snapshots.size() and visual_elapsed>=snapshots[next_snapshot]:
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png(OUT.path_join("meteor-review-%02d.png"%next_snapshot))
			next_snapshot+=1
	var layer=game.world.get_node_or_null("Readability")
	# The imported scene must be visible through a real 3D viewport.
	var found=false
	for child in game.world.get_children():
		if child.get("meteor_model")!=null:
			assert(child.meteor_model.player!=null,"Meteor animation did not load")
			var image=child.meteor_model.viewport.get_texture().get_image()
			assert(image.get_used_rect().size.x>50,"Meteor viewport is empty")
			var border_alpha=0.0
			for index in range(image.get_width()):
				border_alpha=maxf(border_alpha,image.get_pixel(index,0).a)
				border_alpha=maxf(border_alpha,image.get_pixel(index,image.get_height()-1).a)
			for index in range(image.get_height()):
				border_alpha=maxf(border_alpha,image.get_pixel(0,index).a)
				border_alpha=maxf(border_alpha,image.get_pixel(image.get_width()-1,index).a)
			assert(border_alpha<.05,"Meteor is clipped by its render viewport")
			found=true
	assert(found,"New Meteor renderer never activated")
	frames.sort()
	game.sim.meteor_entry_time=0
	game.sim.boss_timer=0
	game.sim.boss_pattern=2
	game.sim.hazards.clear()
	game.sim.update_boss(0)
	var first_gap=game.sim.boss.meteor_last_gap
	var waves=game.sim.hazards.filter(func(h):return h.get("meteor_rupture",false))
	assert(waves.size()==3,"Meteor volley must contain three waves")
	for wave in waves:assert(is_equal_approx(wave.angle,waves[0].angle),"Safe sector changed within a volley")
	game.sim.boss_timer=0
	game.sim.boss_pattern=5
	game.sim.update_boss(0)
	assert(absf(wrapf(game.sim.boss.meteor_last_gap-first_gap,-PI,PI))>=PI*.55-.001,"Consecutive safe sectors overlap")
	var fire=load("res://scripts/meteor_fire_front.gd")
	assert(not fire.burning(game.sim.boss.p,game.sim.boss.p,209.9))
	assert(fire.burning(game.sim.boss.p,game.sim.boss.p,210.0))
	assert(fire.damage_fraction(213)>fire.damage_fraction(210))
	var sum_ms=0.0
	for frame in frames:sum_ms+=frame
	print("METEOR_RELEASE ",JSON.stringify({"frames":frames.size(),"mean_ms":sum_ms/max(1,frames.size()),"p95_ms":frames[int(frames.size()*.95)],"new_model":found,"public_feature":OS.has_feature("meteor_rework")}))
	quit()
