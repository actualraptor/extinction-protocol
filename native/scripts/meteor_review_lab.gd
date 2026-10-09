extends Node
## Private runtime review using the real Meteor encounter and renderer.
var game
func _ready():
	call_deferred("review")
func review():
	var g=game.sim
	if "--meteor-balance-replay" in OS.get_cmdline_user_args():
		await replay_balance(g)
		return
	g.weapons.clear();g.passives.clear();g.enemies=g.anchors.duplicate();g.enemies.append(g.boss)
	g.next_boss=100000;g.spawn_budget=-100000;g.xp_goal=1000000
	game.survivor_voice.enabled=false;game.survivor_voice.stop()
	var directory="res://build/boss-animation-review/meteor"
	if "--meteor-fresh-study" in OS.get_cmdline_user_args():directory+="/fresh-study"
	elif "--meteor-concept-study" in OS.get_cmdline_user_args():directory+="/concept-study"
	elif "--meteor-fracture-study" in OS.get_cmdline_user_args():directory+="/fracture-study"
	if "--meteor-deadline-film" in OS.get_cmdline_user_args():directory+="/deadline"
	if "--meteor-render-quality-review" in OS.get_cmdline_user_args():directory+="/render-quality"
	if "--meteor-rock-heat-review" in OS.get_cmdline_user_args():directory+="/rock-heat"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	print("METEOR REVIEW DISPLAY / monitor index=",DisplayServer.window_get_current_screen())
	if "--meteor-depth-review" in OS.get_cmdline_user_args():
		await review_depth(g,directory)
		g.hazards.clear()
		game.paused=true;game.audio.shutdown()
		await get_tree().create_timer(.25).timeout
		get_tree().quit();return
	if "--meteor-moving-film" in OS.get_cmdline_user_args():
		await moving_combat(g,directory)
		g.hazards.clear()
		game.paused=true;game.audio.shutdown()
		await get_tree().create_timer(.1).timeout
		get_tree().quit();return
	if "--meteor-shell-film" in OS.get_cmdline_user_args():
		g.pos=g.boss.p+Vector2(280,160);g.boss_timer=1000;g.invul=1000;g.spawn_respite=100
		g.boss_time=20;g.velocity=Vector2.ZERO
		game.world.camera_pos=g.pos.lerp(g.boss.p,.5);game.world.camera_run=g
		game.hud_root.visible=false;game.clear_menu()
		await get_tree().create_timer(.75).timeout
		for anchor in g.anchors.duplicate():g.hit(anchor,1e12,"revolver",false,false)
		await get_tree().create_timer(2.0).timeout
		g.make_anchors()
		await get_tree().create_timer(1.5).timeout
		game.paused=true;game.audio.shutdown();await get_tree().create_timer(.1).timeout
		print("METEOR SHELL FILM / actual anchor destruction, exposed hold and closing")
		get_tree().quit();return
	if "--meteor-transition-only" in OS.get_cmdline_user_args():
		g.invul=1000
		await review_transitions(g,directory)
		game.paused=true;game.audio.shutdown()
		await get_tree().create_timer(.1).timeout
		get_tree().quit();return
	if "--meteor-fire-review" in OS.get_cmdline_user_args():
		g.boss_timer=1000;g.invul=1000
		for elapsed in [30.0,120.0,180.0,205.0]:
			g.boss_time=elapsed
			g.pos=g.boss.p+Vector2(280,160)
			await get_tree().create_timer(3.0 if "--meteor-fire-film" in OS.get_cmdline_user_args() else .35).timeout;await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/fire-%d.png"%int(elapsed))
		game.paused=true;game.audio.shutdown()
		await get_tree().create_timer(.1).timeout
		get_tree().quit();return
	for phase in [1,2,3]:
		for pattern in [0,1,2]:
			g.phase=phase;g.boss.reform=0;g.boss_pattern=pattern;g.boss_timer=0
			g.boss_time=155 if phase==3 else 20
			g.pos=g.boss.p+Vector2(280,160);g.velocity=Vector2.ZERO
			g.hazards.clear();g.invul=100
			g.update_boss(.01);g.boss_timer=100
			game.show_toast("METEOR / PHASE %d"%phase,["CRUST ERUPTION" if "--meteor-rig-test" in OS.get_cmdline_user_args() else "CORONAL FLARE","HEAVEN FALLS","SEISMIC COLLAPSE"][pattern])
			await get_tree().create_timer(.65).timeout
			await RenderingServer.frame_post_draw
			verify_visual_clip(pattern,true)
			get_viewport().get_texture().get_image().save_png(directory+"/warning-%d-%d.png"%[phase,pattern])
			# Random rubble openings can need a longer relocation warning.
			# Sample this cast's actual boundary, not the old fixed duration.
			await get_tree().create_timer(maxf(.08,float(g.boss.meteor_cast.warning)-.65+.08)).timeout
			await RenderingServer.frame_post_draw
			verify_visual_clip(pattern,false)
			get_viewport().get_texture().get_image().save_png(directory+"/impact-%d-%d.png"%[phase,pattern])
			await get_tree().create_timer(1.8).timeout
			assert(g.active and g.boss!=null,"Encounter ended unexpectedly during review")
			print("METEOR RUNTIME / phase=",phase," pattern=",pattern," survived warning and impact")
	if "--meteor-transition-review" in OS.get_cmdline_user_args():await review_transitions(g,directory)
	game.paused=true;game.audio.shutdown()
	await get_tree().create_timer(.1).timeout
	get_tree().quit()

func replay_balance(_previous):
	game.set_physics_process(false)
	game.survivor_voice.enabled=false;game.survivor_voice.stop()
	var path="res://build/boss-animation-review/meteor-movement-1101-private-stepwise-epic-body-safe-orbit.json"
	var trace=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not trace is Array or trace.is_empty():
		push_error("Missing verified Meteor movement trace");get_tree().quit(1);return
	# setup configures a fresh run; it does not clear every prior campaign
	# field. Reusing the already-started human fixture retains content state.
	game.release_run()
	var g=preload("res://scripts/expedition.gd").new()
	game.sim=g;game.world.sim=g
	g.effect.connect(game.world.fx)
	g.sound.connect(func(id):game.audio.play(id))
	g.setup(1,"expedition",{},1101)
	preload("res://scripts/meteor_review_loadout.gd").apply(g,"EPIC")
	g.spawn_boss(3);g.pos=g.boss.p+Vector2(300,100);g.build_grid()
	var elapsed=0.0;var index=0;var direction=Vector2.ZERO;var frames=0
	var phases=[1];var maximum_position_error=0.0
	while g.active and elapsed<230:
		while index<trace.size() and float(trace[index].time)<=elapsed+.00001:
			var point=trace[index]
			maximum_position_error=maxf(maximum_position_error,g.pos.distance_to(Vector2(point.p[0],point.p[1])))
			direction=Vector2(point.direction[0],point.direction[1]);index+=1
		if g.choosing:g.choose(0)
		g.tick(1.0/30,direction);elapsed+=1.0/30
		if not phases.has(g.phase):phases.append(g.phase)
		for render_frame in range(2):
			await get_tree().process_frame;frames+=1
	print("METEOR BALANCE REPLAY / won=",g.won," elapsed=",elapsed," hp=",g.hp," hits=",g.hits," phases=",phases," trace position error=",maximum_position_error," rendered frames=",frames)
	var passed=g.won and phases.size()==3 and maximum_position_error<1.0
	game.paused=true;game.audio.shutdown();await get_tree().create_timer(.1).timeout
	get_tree().quit(0 if passed else 1)

func review_depth(g,directory):
	game.set_physics_process(false);game.clear_menu();game.hud_root.visible=false
	g.phase=3;g.boss_time=155;g.boss.reform=0;g.boss_timer=1000
	g.hazards.clear();g.invul=100;g.velocity=Vector2.ZERO
	g.add_hazard("circle",g.boss.p,0,180,1.0,.5,90)
	for label in ["behind","front"]:
		g.pos=g.boss.p+Vector2(0,-60 if label=="behind" else 100)
		for frame in range(30):
			game.world.camera_pos=g.boss.p
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory+"/depth-"+label+".png")
	print("METEOR DEPTH REVIEW / player behind and in front, overlapping ground warning; visual review required")

func moving_combat(g,directory):
	# Continuous visual review, not a survival or weapon-balance gate.
	if "--meteor-performance-review" in OS.get_cmdline_user_args():
		# Uncapped fixed-step simulation outruns wall-clock audio: music seeks
		# would benchmark the harness rather than rendered combat.
		game.audio.enabled=false;game.audio.music_enabled=false
		game.audio.shutdown()
	game.set_physics_process(false)
	var deadline_pressure="--meteor-deadline-film" in OS.get_cmdline_user_args()
	var late_pressure="--meteor-late-film" in OS.get_cmdline_user_args() or deadline_pressure
	g.phase=3;g.boss_time=205 if deadline_pressure else (186 if late_pressure else 155);g.boss.reform=0;g.boss_timer=0;g.boss_pattern=0
	g.spawn_respite=100;g.pos=g.terrain.open_position(g.boss.p+Vector2(330,100))
	if late_pressure:g.pos=g.boss.p+Vector2.RIGHT*preload("res://scripts/meteor_fire_front.gd").radius_at(g.boss_time,0)*.78
	g.hazards.clear();g.invul=100;g.velocity=Vector2.ZERO
	game.hud_root.visible=false;game.clear_menu()
	var peak_hazards=0
	var render_frame_ms=[]
	var simulation_ms=[]
	var process_ms=[]
	var draw_calls=[]
	var slow_frames=[]
	var previous_render_usec=Time.get_ticks_usec()
	for frame in range(480 if late_pressure else 720):
		var elapsed=frame/60.0
		var bearing=elapsed*.48
		var orbit_radius=preload("res://scripts/meteor_fire_front.gd").radius_at(g.boss_time,bearing)*.78 if late_pressure else 330.0
		if deadline_pressure:orbit_radius=maxf(g.boss.size+40,orbit_radius)
		var target=g.boss.p+Vector2.from_angle(bearing)*orbit_radius
		var direction=(target-g.pos).normalized()
		var tick_started=Time.get_ticks_usec()
		g.tick(1.0/60,direction)
		if frame>120:simulation_ms.append((Time.get_ticks_usec()-tick_started)/1000.0)
		g.invul=100;g.choosing=false
		peak_hazards=maxi(peak_hazards,g.hazards.size())
		await get_tree().process_frame
		var now=Time.get_ticks_usec()
		if frame>120 and (now-previous_render_usec)>25000 and "--meteor-performance-review" in OS.get_cmdline_user_args():
			var readability=game.world.get_children().filter(func(node):return node.get_script()==preload("res://scripts/readability.gd"))[0]
			slow_frames.append({"frame":frame,"interval_ms":(now-previous_render_usec)/1000.0,"simulation_ms":simulation_ms[-1],"present_ms":readability.review_process_ms,"draw_ms":readability.review_draw_ms,"hazards":g.hazards.size(),"casts":g.boss_pattern})
		if frame>120:render_frame_ms.append((now-previous_render_usec)/1000.0)
		if frame>120:
			process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
			draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		previous_render_usec=now
		if frame%120==0 and not "--meteor-performance-review" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/moving-%03d.png"%frame)
	print("METEOR MOVING REVIEW / late=",late_pressure," base movement / casts=",g.boss_pattern," peak hazards=",peak_hazards," position=",g.pos," encounter time=",g.boss_time)
	if not slow_frames.is_empty():
		slow_frames.sort_custom(func(a,b):return a.interval_ms>b.interval_ms)
		print("METEOR SLOW FRAME CONTEXT / ",slow_frames.slice(0,mini(10,slow_frames.size())))
	if not render_frame_ms.is_empty():
		render_frame_ms.sort()
		print("METEOR RENDER FRAME INTERVAL / median ms=",render_frame_ms[render_frame_ms.size()/2]," p95 ms=",render_frame_ms[int(render_frame_ms.size()*.95)]," max ms=",render_frame_ms[-1]," movie=",OS.has_feature("movie"))
		simulation_ms.sort()
		print("METEOR SIMULATION COST / median ms=",simulation_ms[simulation_ms.size()/2]," p95 ms=",simulation_ms[int(simulation_ms.size()*.95)])
		process_ms.sort();draw_calls.sort()
		print("METEOR SCENE PROCESS / median ms=",process_ms[process_ms.size()/2]," p95 ms=",process_ms[int(process_ms.size()*.95)]," draw calls median=",draw_calls[draw_calls.size()/2]," max=",draw_calls[-1])

func verify_visual_clip(pattern:int,warning:bool):
	if not "--meteor-rig-test" in OS.get_cmdline_user_args():return
	for child in game.world.get_children():
		if child.get_script()==preload("res://scripts/readability.gd"):
			var expected=["flare","skyfall","collapse"][pattern]+("_windup" if warning else "")
			assert(child.meteor_model!=null,"Private Meteor renderer missing")
			assert(child.meteor_model.current_clip==expected,"Meteor visual clip disagrees with hazard phase: "+expected)
			print("METEOR VISUAL TIMING / ",expected)
			return
	assert(false,"Readability layer unavailable for Meteor review")

func review_transitions(g,directory):
	# Exercise the damage gates rather than substituting a phase number.
	var overlap_review="--meteor-transition-overlap" in OS.get_cmdline_user_args()
	if overlap_review:
		directory+="/transition-overlap"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	g.pos=g.boss.p+Vector2(280,160)
	g.phase=1;g.boss.hp=g.boss.max_hp;g.boss.reform=0;g.boss_time=20;g.hazards.clear();g.boss_timer=100
	for expected_phase in [2,3]:
		if overlap_review:
			g.boss_pattern=2;g.boss_timer=0;g.update_boss(.01)
			await get_tree().create_timer(1.15).timeout
			g.boss_timer=0;g.update_boss(.01)
			assert(g.boss.meteor_casts.size()>=2,"Transition review failed to overlap real casts")
		for anchor in g.anchors.duplicate():g.hit(anchor,1e12,"revolver",false,false)
		await get_tree().create_timer(.8).timeout;await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory+"/exposed-%d.png"%(expected_phase-1))
		for child in game.world.get_children():
			if child.get_script()==preload("res://scripts/readability.gd") and child.meteor_model!=null:
				assert(child.meteor_model.opening>.95,"Destroyed anchors failed to expose core")
		g.hit(g.boss,1e12,"revolver",false,false)
		assert(g.phase==expected_phase,"Core damage failed to advance Meteor phase")
		assert(g.anchors.size()==3,"Meteor phase failed to rebuild its anchors")
		await get_tree().create_timer(.35).timeout;await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory+"/transition-%d.png"%expected_phase)
		await get_tree().create_timer(2.3).timeout
		assert(g.boss.reform<=0,"Meteor remained locked in reformation")
		print("METEOR TRANSITION / phase=",g.phase," real damage gate / reformation complete")
	for anchor in g.anchors.duplicate():g.hit(anchor,1e12,"revolver",false,false)
	g.hit(g.boss,1e12,"revolver",false,false)
	assert(g.won and not g.active,"Meteor final core hit failed to finish the run")
	assert(g.hazards.is_empty(),"Meteor victory retained hostile footprints")
	await get_tree().create_timer(1).timeout;await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory+"/victory.png")
	print("METEOR VICTORY / actual final core hit and clean hostile teardown")
