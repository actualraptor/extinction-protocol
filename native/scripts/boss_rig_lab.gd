extends Node
## Private combat review: real encounter logic, with isolated progression.
var game
var immortal=true
var caption
func _ready():
	print("BOSS TEST DISPLAY / monitor index=",DisplayServer.window_get_current_screen())
	immortal=not "--meteor-balance-test" in OS.get_cmdline_user_args()
	launch()
	if "--quad-attack-film" in OS.get_cmdline_user_args():call_deferred("capture_quad_attacks")
	elif "--close-spacing-review" in OS.get_cmdline_user_args():call_deferred("capture_close_spacing")
	elif "--boss-combat-readability" in OS.get_cmdline_user_args():call_deferred("capture_combat_readability")
	elif "--attack-terrain-review" in OS.get_cmdline_user_args():call_deferred("review_attack_terrain")
	elif "--obstacle-boss-film" in OS.get_cmdline_user_args():call_deferred("capture_obstacle")
	elif "--pr-boss-capture" in OS.get_cmdline_user_args():call_deferred("capture_pr")
	elif "--verify-boss-rig" in OS.get_cmdline_user_args():call_deferred("verify")
func launch():
	game.selected=1;game.chosen_mode="expedition";game.selected_map="cradle";game.start_run()
	var g=game.sim;g.next_boss=100000;g.time=560;g.xp_goal=1000000;g.enemies.clear();g.hazards.clear()
	g.spawn_boss(1 if "--triceratops-rig-test" in OS.get_cmdline_user_args() else 2)
	g.boss.p=g.terrain.open_position(g.pos+Vector2(250,-110));g.boss.origin=g.boss.p;g.boss.target=g.boss.p
	g.boss.hp=1000000;g.boss.max_hp=1000000;g.build_grid();game.clear_menu()
	caption=game.label(game.menu_root,"T-REX COMBAT PLAYTEST\nF1 restart · F2 compare artwork · F3 next attack · F4 crowds · F5 phase 2 · F7 defeat boss · F9 invulnerability\nWASD move · Esc pause · F11 fullscreen",16,"e7dfc7")
	if "--triceratops-rig-test" in OS.get_cmdline_user_args():caption.text=caption.text.replace("T-REX COMBAT PLAYTEST","TRICERATOPS COMBAT PLAYTEST")
	caption.position=Vector2(25,185)
	if "--boss-detail-review" in OS.get_cmdline_user_args():
		g.enemies=[g.boss];g.spawn_budget=-100000;g.weapons.clear()
		game.hud_root.visible=false;caption.visible=false
func _process(_dt):
	if game.sim!=null and immortal:game.sim.hp=game.sim.max_hp;game.sim.invul=maxf(game.sim.invul,.08)
func _unhandled_input(event):
	if not event is InputEventKey or not event.pressed or event.echo:return
	var g=game.sim
	match event.keycode:
		KEY_F1:launch()
		KEY_F2:game.world.rig_bosses=not game.world.rig_bosses
		KEY_F3:
			if g.boss!=null:g.hazards.clear();preload("res://scripts/boss_encounters.gd").prepare(g)
		KEY_F4:
			for i in range(30):g.spawn_enemy(false,g.pos+Vector2.from_angle(i*TAU/30)*(250+i%4*40),i%6)
			g.build_grid()
		KEY_F5:
			if g.boss!=null:g.phase=2;g.boss.hp=g.boss.max_hp*.44
		KEY_F7:
			if g.boss!=null:g.kill(g.boss)
		KEY_F9:immortal=not immortal
func review_attack_terrain():
	game.survivor_voice.enabled=false;game.survivor_voice.stop()
	game.set_physics_process(false)
	var g=game.sim;g.weapons.clear();g.spawn_respite=100
	g.terrain.arena=Vector2.INF;g.terrain.configure(g.terrain.stage,g.terrain.depth)
	for x in range(-12,20):
		for y in range(-12,20):
			var tile=Vector2i(x,y)
			g.terrain.cached[tile]=1 if Rect2(128,-256,64,512).has_point(g.terrain.center(tile)) else 0
	var b=g.boss;b.p=Vector2(32,32);b.rig_heading=PI/2;b.aim=Vector2.DOWN;b.motion=b.aim;b.reform=0
	g.enemies=[b];g.pos=b.p+Vector2(-160,0);g.invul=100
	g.relic_chests.clear();g.gems.clear();g.choosing=false;g.transition_time=0
	b.attack_index=2 if g.boss_stage==2 else 1
	preload("res://scripts/boss_encounters.gd").prepare(g)
	var blocked=0;var sampled=0;var impact_checked=false;var misaligned=false
	for frame in range(300):
		g.tick(1.0/60,Vector2.ZERO);g.invul=100;g.choosing=false
		await get_tree().process_frame
		# process_frame fires before Node._process; inspect the pose that was
		# actually rendered, rather than the preceding frame's rig heading.
		await RenderingServer.frame_post_draw
		if b.action in ["windup","strike"]:
			sampled+=1
			if not preload("res://scripts/dinosaur_attacks.gd").ground_body_clear(g.terrain,b.p,b.rig_heading,90 if g.boss_stage==2 else 70):blocked+=1
			if b.action=="strike" and b.contact_done:
				impact_checked=true
				var hit_heading=b.rig_heading+(PI if b.move=="TAIL SWEEP" else 0)
				if absf(wrapf(hit_heading-b.attack_angle,-PI,PI))>.12:print("WALL IMPACT DRIFT / frame=",frame," progress=",1-b.action_left/b.action_length," rendered=",hit_heading," committed=",b.attack_angle)
				misaligned=misaligned or absf(wrapf(hit_heading-b.attack_angle,-PI,PI))>.12
		elif sampled>0:break
	print("ATTACK TERRAIN REVIEW / ",b.move," sampled=",sampled," obstructed rendered frames=",blocked," impact checked=",impact_checked," misaligned=",misaligned)
	game.paused=true;game.audio.shutdown();await get_tree().create_timer(.1).timeout
	get_tree().quit(1 if blocked>0 or sampled==0 or not impact_checked or misaligned else 0)

func capture_obstacle():
	game.survivor_voice.enabled=false;game.survivor_voice.stop()
	game.set_physics_process(false)
	var g=game.sim;g.weapons.clear();g.passives.clear();g.spawn_respite=100
	g.terrain.arena=Vector2.INF;g.terrain.configure(g.terrain.stage,g.terrain.depth)
	var origin=Vector2(32,32)
	var route_angle=PI if "--reverse-obstacle-route" in OS.get_cmdline_user_args() else 0.0
	for x in range(-12,20):
		for y in range(-12,20):
			var tile=Vector2i(x,y)
			var local=(g.terrain.center(tile)-origin).rotated(-route_angle)+origin
			g.terrain.cached[tile]=1 if Rect2(192,-128,64,320).has_point(local) else 0
	var b=g.boss;b.p=origin;b.aim=Vector2.from_angle(route_angle);b.motion=b.aim;b.rig_heading=route_angle
	b.action="recover";b.action_left=100;b.action_length=100;b.reform=0
	g.enemies=[b];g.pos=origin+Vector2(518,0).rotated(route_angle);g.invul=100
	g.relic_chests.clear();g.gems.clear();g.choosing=false;g.transition_time=0
	var directory="res://build/boss-animation-review/obstacle-"+("triceratops" if g.boss_stage==1 else "trex")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var blocked=0
	for frame in range(900):
		g.tick(1.0/60,Vector2.ZERO);g.invul=100;g.choosing=false
		var half=70.0 if g.boss_stage==1 else 90.0
		for fraction in [-1.0,-.5,0.0,.5,1.0]:
			if not g.terrain.walkable(b.p+Vector2.from_angle(b.rig_heading)*half*fraction,43):blocked+=1
		await get_tree().process_frame
		if frame%120==0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/%03d.png"%frame)
	print("BOSS OBSTACLE FILM / stage=",g.boss_stage," gap=",g.pos.distance_to(b.p)," terrain intersections=",blocked," time=",g.time," active=",g.active," action=",b.action)
	var contact_failures=0
	if g.boss_stage==1:
		for child in game.world.get_children():
			if child.get_script()==preload("res://scripts/readability.gd"):
				var contacts=child.boss_model.contacts
				contact_failures=contacts.unreachable
				print("QUAD OBSTACLE CONTACT / overreach=",contacts.unreachable," adaptive steps=",contacts.adaptive_steps," drop=",contacts.maximum_body_drop," contact error=",contacts.maximum_contact_error)
	else:
		for child in game.world.get_children():
			if child.get_script()==preload("res://scripts/readability.gd"):
				var contacts=child.boss_model.foot_plant
				contact_failures=contacts.unreachable_releases
				print("TREX OBSTACLE CONTACT / releases=",contacts.unreachable_releases," drop=",contacts.maximum_body_drop)
	game.paused=true;game.audio.shutdown();await get_tree().create_timer(.1).timeout
	get_tree().quit(1 if blocked>0 or contact_failures>0 or g.pos.distance_to(b.p)>250 else 0)

func verify():
	game.survivor_voice.enabled=false
	game.survivor_voice.stop()
	if "--triceratops-rig-test" in OS.get_cmdline_user_args() and not "--verify-charge-gaze" in OS.get_cmdline_user_args():await verify_triceratops();return
	if "--trex-sound-review" in OS.get_cmdline_user_args():
		game.audio.music_enabled=false
		for track in game.audio.music_players:track.stop()
		game.sim.weapons.clear()
	await get_tree().create_timer(1).timeout
	var readability=game.world.get_children().filter(func(n):return n.get_script()==preload("res://scripts/readability.gd"))[0]
	assert(readability.boss_model!=null and (readability.boss_model.player.has_animation("bite") or "--verify-charge-gaze" in OS.get_cmdline_user_args()))
	if "--verify-roar-gaze" in OS.get_cmdline_user_args():
		var g=game.sim;var b=g.boss;var view=readability.boss_model
		g.weapons.clear();g.enemies=[b];g.hazards.clear();g.spawn_budget=-100000;g.cache_timer=100000;g.shrine_done=true
		g.pos=b.p+Vector2(390,100);b.target=g.pos;b.aim=(g.pos-b.p).normalized();b.attack_angle=b.aim.angle();b.move="APEX ROAR"
		preload("res://scripts/boss_encounters.gd").execute(g)
		var highest=-1.0;var lowest=1.0;var sampled=0
		for frame in range(310):
			g.choosing=false;game.clear_menu()
			await get_tree().process_frame;await RenderingServer.frame_post_draw
			var skeleton=view.rig_skeleton
			var forward=(skeleton.global_basis*skeleton.get_bone_global_pose(skeleton.find_bone("head")).basis.y).normalized()
			highest=maxf(highest,forward.y);lowest=minf(lowest,forward.y);sampled+=1
			assert(forward.y<=.04,"Roar or recovery lifted skull toward sky")
			if frame in [30,120,210,290]:get_viewport().get_texture().get_image().save_png("res://build/boss-animation-review/trex-roar-gaze-%d.png"%frame)
		print("ROAR GAZE / samples=",sampled," vertical forward range=",lowest," to ",highest)
		game.paused=true;game.audio.shutdown();await get_tree().create_timer(.1).timeout;get_tree().quit();return
	if "--verify-charge-gaze" in OS.get_cmdline_user_args():
		var charge_game=game.sim;var b=charge_game.boss
		charge_game.weapons.clear();charge_game.hazards.clear();charge_game.enemies=[b];charge_game.spawn_budget=-100000
		b.move="HORN CHARGE" if b.identity=="thorn" else "PREDATORY RUSH";b.action="charge";b.action_length=1.2;b.action_left=1.2
		b.origin=b.p;b.target=b.p+Vector2.RIGHT*320;b.aim=Vector2.RIGHT;b.motion=Vector2.RIGHT;b.rig_heading=0.0
		readability.boss_model.initialized=false
		var sampled=0;var minimum_alignment=1.0
		for frame in range(90):
			# The target dodges sideways and ends behind the passing boss.
			charge_game.pos=b.origin+Vector2(-60,180)
			await get_tree().process_frame;await RenderingServer.frame_post_draw
			if b.action=="charge" and frame>12:
				var skeleton=readability.boss_model.rig_skeleton
				var forward=(skeleton.global_basis*skeleton.get_bone_global_pose(skeleton.find_bone("head")).basis.y).normalized()
				var alignment=Vector2(forward.x,forward.z).normalized().dot(b.aim)
				minimum_alignment=minf(minimum_alignment,alignment);sampled+=1
				assert(alignment>.9,"Charge head followed the dodge instead of its committed corridor")
				assert(forward.y<=.04,"Charge head tilted toward the sky")
		assert(sampled>10,"Charge gaze review did not sample active motion")
		print("CHARGE GAZE / boss=",b.identity," active samples=",sampled," minimum corridor alignment=",minimum_alignment)
		b.action="recover";b.action_left=100;b.action_length=100
		await get_tree().create_timer(3.0).timeout
		var recovery_error=absf(wrapf(readability.boss_model.heading+(charge_game.pos-readability.rendered_boss_p).angle(),-PI,PI))
		print("CHARGE RECOVERY / boss=",b.identity," player-facing error=",recovery_error)
		assert(recovery_error<.15,"Boss failed to reacquire the player after a dodged charge")
		game.paused=true;game.audio.shutdown();await get_tree().create_timer(.1).timeout;get_tree().quit();return
	if "--verify-close-spacing" in OS.get_cmdline_user_args():
		var close_game=game.sim
		close_game.weapons.clear();close_game.hazards.clear()
		close_game.boss.action="recover";close_game.boss.action_left=100;close_game.boss.action_length=100
		close_game.pos=close_game.boss.p+Vector2(60,0)
		await get_tree().create_timer(3.0).timeout
		var distance=close_game.pos.distance_to(close_game.boss.p)
		var face_error=absf(wrapf(readability.boss_model.heading+(close_game.pos-close_game.boss.p).angle(),-PI,PI))
		print("TREX CLOSE SPACING / distance=",distance," body facing error=",face_error," contact releases=",readability.boss_model.foot_plant.unreachable_releases)
		assert(distance>145 and distance<225,"T-rex did not establish attack spacing")
		assert(face_error<.15,"T-rex turned away while retreating")
		assert(readability.boss_model.foot_plant.unreachable_releases==0,"Retreat exceeded supporting leg reach")
	var review_dir=OS.get_executable_path().get_base_dir().path_join("review") if OS.has_feature("boss_rig_playtest") else ProjectSettings.globalize_path("res://build/boss-animation-review/combat")
	DirAccess.make_dir_recursive_absolute(review_dir)
	if "--capture-rig-cycles" in OS.get_cmdline_user_args():
		await capture_cycles(review_dir)
	if "--verify-rig-pursuit" in OS.get_cmdline_user_args():
		var pursuit_dir=review_dir.path_join("pursuit");DirAccess.make_dir_recursive_absolute(pursuit_dir)
		var g=game.sim;g.boss.action="recover";g.boss.action_left=100;g.boss.action_length=100
		var heading_error=0.0
		var before_releases=readability.boss_model.foot_plant.unreachable_releases
		var extended="--long-rig-pursuit" in OS.get_cmdline_user_args()
		if extended:g.phase=2;g.boss.hp=g.boss.max_hp*.44
		var pursuit_start=g.time
		var showcase="--pursuit-showcase" in OS.get_cmdline_user_args()
		var route_origin=g.pos;var previous_time=g.time;var captured_paths=[];var captured_times=[]
		var escape_review="--pursuit-escape-review" in OS.get_cmdline_user_args()
		if escape_review:
			g.pos=g.boss.p+Vector2(350,0);g.boss.rig_heading=0.0;g.boss.rig_turn_velocity=0.0;g.boss.aim=Vector2.RIGHT;g.boss.motion=Vector2.RIGHT
			g.passives.erase("speed");g.augments.erase("speed");g.invul=100
			readability.boss_model.initialized=false
		var frame_limit=1440 if extended else 240
		var capture_stride=12 if extended else 4
		for frame in range(frame_limit):
			g.relic_chests.clear();g.gems.clear();g.choosing=false;game.clear_menu()
			var elapsed=g.time-pursuit_start
			# Keep the target route in simulation time at any rendering rate.
			var target_angle=elapsed*1.1+.45*sin(elapsed*.6) if extended else elapsed*1.4
			if escape_review:
				g.pos+=Vector2.RIGHT*g.speed()*maxf(0,g.time-previous_time)
			elif showcase:
				var route=[Vector2(-200,-100),Vector2(200,-100),Vector2(200,120),Vector2(-200,120)]
				var destination=route_origin+route[int(elapsed/5)%4]
				var delta=destination-g.pos;var step_time=maxf(0,g.time-previous_time)
				g.velocity=delta.normalized()*85
				g.pos=g.terrain.move(g.pos,delta.normalized()*minf(delta.length(),85*step_time),15)
			else:g.pos=g.terrain.open_position(g.boss.p+Vector2.from_angle(target_angle)*230)
			# The route starts by placing the player on a new side. Align only
			# this initial placement; subsequent turns use ordinary runtime motion.
			if frame==0 and not escape_review and not showcase:
				g.boss.rig_heading=(g.pos-g.boss.p).angle();g.boss.rig_turn_velocity=0.0
				readability.boss_model.initialized=false
			previous_time=g.time
			await get_tree().process_frame;await RenderingServer.frame_post_draw
			if g.boss.motion.length_squared()>.01:
				var facing_error=absf(wrapf(readability.boss_model.heading+(g.pos-readability.rendered_boss_p).angle(),-PI,PI))
				if facing_error>heading_error and facing_error>.1:
					print("PURSUIT DIVERGENCE / frame=",frame," sim time=",elapsed," heading=",readability.boss_model.heading," physical=",g.boss.motion.angle()," render dt=",readability.boss_model.get_process_delta_time())
				heading_error=maxf(heading_error,facing_error)
			if frame%capture_stride==0 and not "--no-review-frames" in OS.get_cmdline_user_args():
				var path=pursuit_dir.path_join("%03d.png"%(frame/capture_stride))
				get_viewport().get_texture().get_image().save_png(path);captured_paths.append(path);captured_times.append(g.time)
		var manifest=FileAccess.open(pursuit_dir.path_join("frames.ffconcat"),FileAccess.WRITE);manifest.store_line("ffconcat version 1.0")
		for i in captured_paths.size():
			manifest.store_line("file '%s'"%captured_paths[i].replace("\\","/"))
			if i+1<captured_times.size():manifest.store_line("duration %.6f"%(captured_times[i+1]-captured_times[i]))
		manifest.close()
		print("PURSUIT max rendered facing error / ",heading_error," new anchor releases / ",readability.boss_model.foot_plant.unreachable_releases-before_releases," maximum body drop / ",readability.boss_model.foot_plant.maximum_body_drop," maximum body shift / ",readability.boss_model.foot_plant.maximum_body_shift)
		# Release builds omit assert statements. A private exported review
		# must still fail rather than printing PASS after a broken chase.
		if heading_error>=.25 or readability.boss_model.foot_plant.unreachable_releases!=before_releases:
			push_error("Pursuit review failed: facing or supporting-leg reach")
			game.paused=true;game.audio.shutdown();get_tree().quit(1);return
		if escape_review:
			var final_gap=g.pos.distance_to(g.boss.p)
			print("UNBOOSTED ESCAPE / player speed=",g.speed()," initial gap=350 final gap=",final_gap)
			assert(final_gap<230,"Unboosted player escaped the T-rex's pursuit")
	if "--trex-sound-review" in OS.get_cmdline_user_args():
		game.sim.boss.action="recover";game.sim.boss.action_left=100;game.sim.boss.action_length=100
		game.sim.pos=game.sim.boss.p+Vector2(400,100)
		await get_tree().create_timer(3.0).timeout
	var attack_order=[4,2,3] if "--seismic-review" in OS.get_cmdline_user_args() else [3,2,1,0] if "--trex-sound-review" in OS.get_cmdline_user_args() else [2,1,0,3] if "--tail-target-review" in OS.get_cmdline_user_args() else [0,1,2,3]
	if "--tail-target-review" in OS.get_cmdline_user_args():
		game.sim.pos=game.sim.boss.p+Vector2(200,0)
		game.sim.boss.rig_heading=0.0;readability.boss_model.heading=0.0
	for i in attack_order:
		var g=game.sim;g.boss.attack_index=i;g.hazards.clear()
		if i==3 and "--trex-slow-roar-review" in OS.get_cmdline_user_args():g.buffs.slow=10.0
		preload("res://scripts/boss_encounters.gd").prepare(g)
		await get_tree().create_timer(.8).timeout
		await RenderingServer.frame_post_draw
		if not DisplayServer.get_name()=="headless":get_viewport().get_texture().get_image().save_png(review_dir.path_join("windup-%d.png"%i))
		await get_tree().create_timer(maxf(.01,g.boss.action_left)+preload("res://scripts/dinosaur_attacks.gd").shape(g.boss.move).duration*.45 if g.boss.action=="windup" else .01).timeout
		await RenderingServer.frame_post_draw
		if not DisplayServer.get_name()=="headless":get_viewport().get_texture().get_image().save_png(review_dir.path_join("attack-%d.png"%i))
		if i>0 and "--painted-foot-plant" in OS.get_cmdline_user_args():
			var captured=false
			for frame in range(300):
				if g.boss.action=="strike" and g.boss.contact_done:
					await RenderingServer.frame_post_draw
					if g.boss.move in ["TAIL SWEEP","CRUSHING BITE"]:
						var rendered_attack=-readability.boss_model.heading+(PI if g.boss.move=="TAIL SWEEP" else 0.0)
						print("ATTACK ALIGN / ",g.boss.move," heading ",readability.boss_model.heading," hit ",g.boss.attack_angle," rendered ",rendered_attack)
						assert(absf(wrapf(rendered_attack-g.boss.attack_angle,-PI,PI))<.12,"Rendered attack misses committed hit direction")
						var peak=.25 if readability.boss_model.action=="bite" else .30
						assert(absf(readability.boss_model.animation_clock-peak)<.12,"Strike render missed physical impact pose")
					var rig=readability.boss_model.rig_skeleton
					var head_forward=(rig.global_basis*rig.get_bone_global_pose(rig.find_bone("head")).basis.y).normalized()
					print("ATTACK HEAD / ",g.boss.move," forward=",head_forward)
					if g.boss.move=="APEX ROAR" and "--trex-slow-roar-review" in OS.get_cmdline_user_args():
						print("SLOW ROAR RUNTIME / audio pitch=",game.audio.boss_roar_voice.pitch_scale," slow remaining=",g.buffs.get("slow",0))
						assert(is_equal_approx(game.audio.boss_roar_voice.pitch_scale,.7),"Main runtime did not synchronize slowed roar audio")
					assert(head_forward.y<=.04,"Attack lifted the head toward the sky")
					get_viewport().get_texture().get_image().save_png(review_dir.path_join("impact-%d.png"%i));captured=true;break
				await get_tree().process_frame
			assert(captured,"Physical impact not reached during rig review")
		if "--seismic-review" in OS.get_cmdline_user_args():
			if i==4:
				for wave in range(3):
					await get_tree().create_timer(.25 if wave==0 else .27).timeout
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png(review_dir.path_join("seismic-wave-%d.png"%wave))
					print("SEISMIC WAVE REVIEW / sample=",wave," active bursts=",game.sim.hazards.filter(func(h):return h.get("seismic",false) and h.wait<=0).size())
			await get_tree().create_timer(2.0).timeout
		if "--trex-sound-review" in OS.get_cmdline_user_args():
			while g.boss.action in ["windup","strike","charge"]:await get_tree().process_frame
			await get_tree().create_timer(.35).timeout
		assert(g.boss!=null and g.boss.hp>0)
		assert(readability.boss_model.player.get_animation_list().size()>=8)
		if "--trex-slow-roar-review" in OS.get_cmdline_user_args():g.buffs.erase("slow")
	game.sim.phase=2;game.sim.boss.hp=game.sim.boss.max_hp*.44
	for i in range(60):game.sim.spawn_enemy(false,game.sim.pos+Vector2.from_angle(i*TAU/60)*(250+i%4*40),i%6)
	game.sim.build_grid()
	var frame_times=[]
	for i in range(180):
		await get_tree().process_frame
		frame_times.append(get_process_delta_time()*1000)
	frame_times.sort()
	print("CROWD FRAME TIME / median %.2f ms / p95 %.2f ms / %d enemies"%[frame_times[90],frame_times[171],game.sim.enemies.size()])
	await RenderingServer.frame_post_draw
	if not DisplayServer.get_name()=="headless":get_viewport().get_texture().get_image().save_png(review_dir.path_join("crowd-phase-2.png"))
	# Short overlap review at the boss's front and back ground planes.
	for offset in [Vector2(0,-25),Vector2(0,25)]:
		game.sim.pos=game.sim.boss.p+offset
		await get_tree().process_frame;await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(review_dir.path_join("player-behind.png" if offset.y<0 else "player-front.png"))
	game.world.rig_bosses=false;await get_tree().process_frame;await get_tree().process_frame;assert(readability.boss_model.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED)
	game.world.rig_bosses=true;await get_tree().process_frame;await get_tree().process_frame
	game.paused=true;var before=readability.boss_model.animation_clock
	await get_tree().create_timer(.1).timeout;assert(is_equal_approx(before,readability.boss_model.animation_clock));game.paused=false
	game.sim.kill(game.sim.boss);await get_tree().process_frame;assert(game.sim.boss==null)
	assert(preload("res://scripts/dinosaur_boss_art.gd").corpse("basalt")!=null)
	print("CONTACT AUDIT / releases=",readability.boss_model.foot_plant.unreachable_releases," edge adjustments=",readability.boss_model.foot_plant.edge_contact_adjustments," turn steps=",readability.boss_model.foot_plant.completed_turn_steps)
	print("PASS: imported 3D T-rex, ",attack_order.size()," combat actions, comparison, pause, death and original corpse API")
	game.paused=true
	game.audio.shutdown()
	await get_tree().create_timer(.1).timeout
	get_tree().quit()
func capture_cycles(review_dir:String):
	var g=game.sim
	g.weapons.clear();g.relic_chests.clear();g.gems.clear()
	for move in range(4):
		g.pos=g.terrain.open_position(g.boss.p+Vector2(-230,70))
		g.boss.attack_index=move;g.hazards.clear();preload("res://scripts/boss_encounters.gd").prepare(g)
		var folder=review_dir.path_join("cycle-%d"%move);DirAccess.make_dir_recursive_absolute(folder)
		var start=g.time;var last=-1.0;var stamps=[];var paths=[]
		var telemetry=FileAccess.open(folder.path_join("poses.csv"),FileAccess.WRITE)
		telemetry.store_line("simulation_time,action,clip,clip_time")
		while g.time-start<8:
			g.relic_chests.clear();g.gems.clear();g.choosing=false;game.clear_menu()
			await get_tree().process_frame
			if is_equal_approx(last,g.time):continue
			await RenderingServer.frame_post_draw
			last=g.time
			var path=folder.path_join("%03d.png"%paths.size())
			get_viewport().get_texture().get_image().save_png(path)
			stamps.append(g.time);paths.append(path)
			var view=game.world.get_children().filter(func(n):return n.get_script()==preload("res://scripts/readability.gd"))[0].boss_model
			telemetry.store_line("%.5f,%s,%s,%.5f"%[g.time,g.boss.action,view.action,view.animation_clock])
			if g.boss.action=="recover" and g.boss.action_left<.2:break
		telemetry.close()
		var manifest=FileAccess.open(folder.path_join("frames.ffconcat"),FileAccess.WRITE);manifest.store_line("ffconcat version 1.0")
		for i in paths.size():
			manifest.store_line("file '%s'"%paths[i].replace("\\","/"))
			if i+1<paths.size():manifest.store_line("duration %.6f"%(stamps[i+1]-stamps[i]))
		manifest.close()
		print("CAPTURED complete attack cycle / ",move," frames / ",paths.size()," simulation seconds / ",g.time-start)

func capture_quad_attacks():
	assert("--triceratops-rig-test" in OS.get_cmdline_user_args())
	game.survivor_voice.enabled=false;game.survivor_voice.stop();game.set_physics_process(false)
	game.hud_root.hide();caption.hide();game.clear_menu()
	var g=game.sim;g.weapons.clear();g.spawn_budget=-100000;g.cache_timer=100000;g.shrine_done=true
	var center=g.pos+Vector2(1400,1400)
	var moving_prey="--quad-moving-prey-film" in OS.get_cmdline_user_args()
	g.terrain.arena=center;g.terrain.arena_radius=1000
	for phase in [1,2]:
		for attack in range(3):
			g.spawn_boss(1);g.phase=phase;g.boss.p=center;g.boss.origin=center;g.boss.reform=0
			g.boss.action="recover";g.boss.action_left=100;g.boss.action_length=100
			g.boss.rig_heading=0;g.boss.aim=Vector2.RIGHT;g.boss.motion=Vector2.RIGHT
			g.pos=center+Vector2(260,65);g.enemies=[g.boss];g.hazards.clear();g.build_grid()
			game.world.camera_pos=center+Vector2(130,30)
			g.boss.attack_index=attack
			for frame in range(360):
				if frame==30:
					preload("res://scripts/boss_encounters.gd").prepare(g)
					print("QUAD ATTACK FILM / phase=",phase," move=",g.boss.move)
				# Move through the real player/collision path, including a lateral
				# dodge after anticipation begins. Do not teleport during a shot.
				var direction=Vector2.ZERO
				if moving_prey:
					var t=frame/60.0
					var destination=center+Vector2(260+75*sin(t*.8),65+170*sin(t*1.2))
					direction=(destination-g.pos).normalized()
				g.tick(1.0/60,direction);g.invul=100;g.choosing=false
				if frame>30 and g.boss.action=="recover":g.boss.action_left=100
				await get_tree().process_frame
	var view=game.world.get_children().filter(func(n):return n.get_script()==preload("res://scripts/readability.gd"))[0].boss_model
	print("QUAD ATTACK FILM / overreach=",view.contacts.unreachable," drop=",view.contacts.maximum_body_drop," limb error=",view.contacts.maximum_length_error)
	var invalid_contacts=view.contacts.unreachable>0 or view.contacts.maximum_length_error>.001
	game.paused=true;game.audio.shutdown();await get_tree().create_timer(.1).timeout;get_tree().quit(1 if invalid_contacts else 0)

func capture_close_spacing():
	game.survivor_voice.enabled=false;game.survivor_voice.stop();game.set_physics_process(false)
	var g=game.sim;g.weapons.clear();g.enemies=[g.boss];g.spawn_budget=-100000;g.cache_timer=100000;g.shrine_done=true
	g.boss.action="recover";g.boss.action_left=100;g.boss_timer=1000
	game.hud_root.hide();caption.hide();game.clear_menu()
	var segment=-1
	var crossover="--continuous-spacing-review" in OS.get_cmdline_user_args()
	var route_origin=g.boss.p
	if crossover:
		g.pos=route_origin+Vector2(230,0)
		g.boss.rig_heading=0;g.boss.motion=Vector2.RIGHT;g.boss.aim=Vector2.RIGHT
	for frame in 480:
		var next_segment=frame/120
		if not crossover and next_segment!=segment:
			segment=next_segment;g.pos=g.boss.p+Vector2.from_angle(segment*PI*.5)*120
		var direction=Vector2.ZERO
		if crossover:
			# Continuous figure-eight crosses the body vicinity at ordinary
			# player speed. tick owns movement, collisions and spacing.
			var t=(frame+1)/60.0
			var destination=route_origin+Vector2(230*cos(t*.8),145*sin(t*1.6))
			direction=(destination-g.pos).normalized()
		g.tick(1.0/60,direction);g.invul=100;g.choosing=false
		await get_tree().process_frame
	var view=game.world.get_children().filter(func(n):return n.get_script()==preload("res://scripts/readability.gd"))[0].boss_model
	if "--triceratops-rig-test" in OS.get_cmdline_user_args():
		print("CLOSE SPACING RIG / quad overreach=",view.contacts.unreachable," drop=",view.contacts.maximum_body_drop," final gap=",g.pos.distance_to(g.boss.p))
	else:
		print("CLOSE SPACING RIG / releases=",view.foot_plant.unreachable_releases," drop=",view.foot_plant.maximum_body_drop," final gap=",g.pos.distance_to(g.boss.p))
	game.paused=true;game.audio.shutdown();await get_tree().create_timer(.1).timeout;get_tree().quit()

func capture_combat_readability():
	game.survivor_voice.enabled=false;game.survivor_voice.stop()
	game.set_physics_process(false)
	var g=game.sim
	g.weapons={"revolver":{"level":4,"evolved":false,"timer":0.0,"casts":0},"fire":{"level":3,"evolved":false,"timer":0.0,"casts":0},"orbital":{"level":3,"evolved":false,"timer":0.0,"casts":0}}
	g.spawn_budget=-100000;g.cache_timer=100000;g.shrine_done=true;g.boss_timer=.5
	var origin=g.boss.p;g.pos=origin+Vector2(270,50)
	for index in range(60):g.spawn_enemy(false,origin+Vector2.from_angle(index*TAU/60)*(450+index%5*55),index%6)
	g.build_grid()
	var moves={}
	var started=g.time;var frame=0;var captured_drop=0.0
	var freeze_captures={}
	while g.time-started<20:
		var target=g.boss.p+Vector2.from_angle((g.time-started)*.45)*260
		g.tick(clampf(get_process_delta_time(),.001,.12),(target-g.pos).normalized())
		g.invul=100;g.choosing=false;game.clear_menu()
		if "--depth-freeze-review" in OS.get_cmdline_user_args():
			var elapsed=g.time-started
			if elapsed>=5 and elapsed<8:g.buffs["freeze"]=.2
			var capture="frozen" if elapsed>=6 and elapsed<8 else "thawed" if elapsed>=9 else ""
			if capture!="" and not freeze_captures.has(capture):
				freeze_captures[capture]=true
				await get_tree().process_frame;await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://build/boss-animation-review/combat/depth-%s.png"%capture)
		if g.boss!=null:moves[g.boss.get("move","")]=true
		await get_tree().process_frame
		if "--trace-foot-contact" in OS.get_cmdline_user_args() and not "--triceratops-rig-test" in OS.get_cmdline_user_args():
			var contact_view=game.world.get_children().filter(func(n):return n.get_script()==preload("res://scripts/readability.gd"))[0].boss_model
			if contact_view!=null and contact_view.foot_plant.body_drop>captured_drop+.02:
				captured_drop=contact_view.foot_plant.body_drop
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://build/boss-animation-review/combat/trex-body-drop-peak.png")
		if frame%240==0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/boss-animation-review/combat/weapon-readability-%d.png"%frame)
		frame+=1
	print("WEAPON COMBAT READABILITY / weapons=",g.weapons," boss moves=",moves.keys()," actors=",g.enemies.size()," invulnerable visual review; not balance acceptance")
	var view=game.world.get_children().filter(func(n):return n.get_script()==preload("res://scripts/readability.gd"))[0].boss_model
	if "--triceratops-rig-test" in OS.get_cmdline_user_args():
		print("WEAPON CONTACT / overreach=",view.contacts.unreachable," body drop=",view.contacts.maximum_body_drop," contact error=",view.contacts.maximum_contact_error)
		assert(view.contacts.unreachable==0,"Weapon combat exhausted a supporting quadruped leg")
		assert(view.contacts.maximum_body_drop<.2,"Weapon combat caused excessive quadruped crouching")
	else:
		print("WEAPON CONTACT / releases=",view.foot_plant.unreachable_releases," body drop=",view.foot_plant.maximum_body_drop)
		assert(view.foot_plant.unreachable_releases==0,"Weapon combat released an unreachable supporting foot")
	game.paused=true;game.audio.shutdown();await get_tree().create_timer(.1).timeout;get_tree().quit()

func capture_pr():
	game.survivor_voice.enabled=false;game.survivor_voice.stop()
	# Controlled comparison takes use the real movement, encounter and hazard code.
	var old="--pr-old-sprite" in OS.get_cmdline_user_args()
	game.world.rig_bosses=not old;caption.hide();game.hud_root.hide();game.menu_root.hide()
	game.set_physics_process(false);game.audio.music_enabled=false
	for track in game.audio.music_players:track.stop()
	var g=game.sim
	g.weapons.clear();g.passives.clear();g.augments.clear();g.setup(1,"expedition",{},31415,"cradle")
	g.halloween=false;g.level=1;g.xp_goal=1000000;g.next_boss=100000
	var center=Vector2(1500,850)
	var sequences=[["PURSUIT",4.0],["TURNING",4.0],["CRUSHING BITE",4.0],["PREDATORY RUSH",4.0],["TAIL SWEEP",5.0],["APEX ROAR",7.0],["SEISMIC STOMP",5.0]]
	if "--pr-bite-study" in OS.get_cmdline_user_args():sequences=sequences.filter(func(sequence):return sequence[0]=="CRUSHING BITE")
	for sequence in sequences:
		var move:String=sequence[0]
		g.enemies.clear();g.hazards.clear();g.gems.clear();g.shots.clear();g.relic_chests.clear()
		g.time=560;g.phase=1;g.spawn_respite=1000;g.portal=null;g.choosing=false
		g.spawn_boss(2);g.boss.p=center;g.boss.origin=center;g.boss.target=center
		g.boss.hp=1000000;g.boss.max_hp=1000000;g.boss.action="recover";g.boss.action_left=100;g.boss.action_length=100
		g.boss.aim=Vector2.RIGHT;g.boss.motion=Vector2.RIGHT;g.boss.rig_heading=0.0;g.boss.rig_turn_velocity=0.0
		g.terrain.arena=center;g.pos=center+Vector2(350,0)
		if move=="CRUSHING BITE":g.pos=center+Vector2(195,65)
		if move=="TAIL SWEEP":g.pos=center+Vector2(400,100)
		if move=="APEX ROAR":g.pos=center+Vector2(390,100)
		if move=="SEISMIC STOMP":g.pos=center+Vector2(330,70)
		g.invul=100;g.build_grid()
		game.world.effects.clear();game.world.particles.clear();game.world.numbers.clear();game.world.emitters.clear()
		game.world.camera_pos=g.pos.lerp(center,.5)
		for j in range(10):g.spawn_enemy(false,center+Vector2.from_angle(j*TAU/10)*(650+j%3*70),j%6)
		g.build_grid()
		var elapsed=0.0;var accumulator=0.0;var started=false
		print("PR SHOT / ",move," / ","sprite" if old else "rig")
		for frame in range(round(float(sequence[1])*60)):
			var direction=Vector2.ZERO
			if move=="PURSUIT":direction=Vector2.RIGHT
			elif move=="TURNING":
				var destination=center+Vector2.from_angle(elapsed*.8)*310
				direction=(destination-g.pos).normalized()
			if elapsed>=.4 and not started and move not in ["PURSUIT","TURNING"]:
				started=true
				if not (old and move=="SEISMIC STOMP"):
					g.boss.move=move
					var index=preload("res://scripts/dinosaur_attacks.gd").MOVES.basalt.find(move)
					g.boss.attack_index=4 if move=="SEISMIC STOMP" else index
					preload("res://scripts/boss_encounters.gd").prepare(g)
			accumulator+=1.0/60
			while accumulator>=1.0/30:
				g.tick(1.0/30,direction);accumulator-=1.0/30
				if started and g.boss.action=="recover":g.boss.action_left=100
			g.choosing=false;g.invul=100;g.hp=g.max_hp
			elapsed+=1.0/60
			await get_tree().process_frame
	var readability=game.world.get_children().filter(func(n):return n.get_script()==preload("res://scripts/readability.gd"))[0]
	if not old:print("PR CONTACTS / releases=",readability.boss_model.foot_plant.unreachable_releases)
	game.paused=true;game.audio.shutdown()
	await get_tree().create_timer(.1).timeout
	get_tree().quit()

func verify_triceratops():
	await get_tree().create_timer(1).timeout
	var readability=game.world.get_children().filter(func(n):return n.get_script()==preload("res://scripts/readability.gd"))[0]
	var view=readability.boss_model
	assert(view!=null and view.player.has_animation("sweep"))
	var g=game.sim;g.weapons.clear();game.survivor_voice.enabled=false;game.survivor_voice.stop()
	# Keep this isolated animation check out of cache and shrine rewards.
	g.cache_timer=100000;g.shrine_done=true
	if "--quadruped-gaze-trace" in OS.get_cmdline_user_args():
		g.enemies=[g.boss];g.spawn_budget=-100000;g.hazards.clear()
		g.boss.action="recover";g.boss.action_left=100;g.boss.action_length=100
		for offset in [Vector2(180,0),Vector2(0,180),Vector2(-180,0),Vector2(0,-180)]:
			g.pos=g.boss.p+offset
			for sample in range(20):
				await get_tree().create_timer(.1).timeout
				var head=view.rig_skeleton.find_bone("head")
				var forward=(view.rig_skeleton.global_basis*view.rig_skeleton.get_bone_global_pose(head).basis.y).normalized()
				var alignment=Vector2(forward.x,forward.z).normalized().dot((g.pos-g.boss.p).normalized())
				if sample in [0,5,11,19]:print("GAZE TRACE / offset=",offset," sample=",sample," action=",g.boss.action," heading=",view.heading," desired=",view.desired_heading," yaw=",view.gaze_yaw," alignment=",alignment)
		game.paused=true;game.audio.shutdown();await get_tree().create_timer(.1).timeout;get_tree().quit();return
	if "--quadruped-turn-review" in OS.get_cmdline_user_args():
		if not "--scenery-depth-review" in OS.get_cmdline_user_args():g.enemies=[g.boss]
		else:
			var crowd_count=300 if "--scenery-dense-review" in OS.get_cmdline_user_args() else 30
			for index in range(crowd_count):g.spawn_enemy(false,g.pos+Vector2.from_angle(index*TAU/crowd_count)*(250+index%8*40),index%6)
			g.build_grid()
			print("SCENERY CROWD REVIEW / actors=",g.enemies.size())
		g.spawn_budget=-100000;g.hazards.clear()
		g.boss.action="recover";g.boss.action_left=100;g.boss.action_length=100
		var origin=g.boss.p
		var started=g.time
		var previous=g.time
		var maximum_error=0.0
		var review_intervals=[];var review_ticks=[];var review_present=[];var review_draws=[];var previous_render=Time.get_ticks_usec();var peak_local=0
		for frame in range(600):
			var elapsed=g.time-started
			# Continuous figure-eight movement reverses lateral travel without
			# teleporting the target. Keep the ordinary terrain and pursuit.
			var destination=origin+Vector2(sin(elapsed*.8)*230,cos(elapsed*1.6)*120)
			var delta=destination-g.pos
			g.pos=g.terrain.move(g.pos,delta.normalized()*minf(delta.length(),g.speed()*maxf(0,g.time-previous)),14)
			previous=g.time
			await get_tree().process_frame;await RenderingServer.frame_post_draw
			var now=Time.get_ticks_usec()
			if frame>120:
				review_intervals.append((now-previous_render)/1000.0);review_ticks.append(game.review_tick_ms)
				review_present.append(readability.review_process_ms);review_draws.append(readability.review_draw_ms)
			previous_render=now
			if "--scenery-depth-review" in OS.get_cmdline_user_args():
				var local_count=0
				for enemy in g.enemies:
					if game.world.landmark_depth_enemy(enemy):local_count+=1
				peak_local=maxi(peak_local,local_count)
			if elapsed>2:
				var facing_error=absf(wrapf(view.heading+(g.pos-g.boss.p).angle(),-PI,PI))
				if facing_error>maximum_error+.02 and facing_error>.25:
					print("TURN LAG TRACE / elapsed=",elapsed," error=",facing_error," gap=",g.pos.distance_to(g.boss.p)," physical error=",absf(wrapf(g.boss.get("rig_heading",0.0)-(g.pos-g.boss.p).angle(),-PI,PI))," rendered/desired=",view.heading,"/",view.desired_heading," turn velocity=",g.boss.get("rig_turn_velocity",0.0)," tick ms=",game.review_tick_ms)
				maximum_error=maxf(maximum_error,facing_error)
			if frame in [120,300,480]:
				get_viewport().get_texture().get_image().save_png("res://build/boss-animation-review/triceratops-turn-%d.png"%frame)
		print("TRICERATOPS TURN REVERSALS / facing error=",maximum_error," overreach=",view.contacts.unreachable," contact error=",view.contacts.maximum_contact_error," body drop=",view.contacts.maximum_body_drop)
		if not review_intervals.is_empty():
			review_intervals.sort()
			print("SCENERY FRAME REVIEW / median=",review_intervals[review_intervals.size()/2]," p95=",review_intervals[int(review_intervals.size()*.95)]," peak local actors=",peak_local)
			review_ticks.sort()
			print("SCENERY SIMULATION REVIEW / median=",review_ticks[review_ticks.size()/2]," p95=",review_ticks[int(review_ticks.size()*.95)])
			review_present.sort();review_draws.sort()
			print("SCENERY PRESENT/DRAW / median=",review_present[review_present.size()/2],"/",review_draws[review_draws.size()/2]," p95=",review_present[int(review_present.size()*.95)],"/",review_draws[int(review_draws.size()*.95)])
		assert(maximum_error<.25,"Triceratops lost the player during continuous turn reversals")
		assert(view.contacts.maximum_body_drop<.20,"Turn reversals forced excessive body crouching")
		assert(view.contacts.unreachable==0,"Turn reversal exhausted a supporting leg")
	for phase in [1,2]:
		g.phase=phase
		for move in range(3):
			g.boss.attack_index=move;g.hazards.clear();preload("res://scripts/boss_encounters.gd").prepare(g)
			var locked_angle=g.boss.attack_angle
			if "--moving-target-review" in OS.get_cmdline_user_args():
				await get_tree().create_timer(.4).timeout
				g.pos=g.terrain.open_position(g.pos+g.boss.aim.orthogonal()*140)
			while g.boss.action=="windup":await get_tree().process_frame
			assert(is_equal_approx(g.boss.attack_angle,locked_angle),"Moving player redirected the committed Triceratops tell")
			if g.boss.move=="HORN CHARGE":
				# A dodged charge has no contact event. Review its travelling
				# pose, rather than mislabelling a later recovery frame as impact.
				while g.boss.action=="charge" and 1-g.boss.action_left/g.boss.action_length<.45:await get_tree().process_frame
				await RenderingServer.frame_post_draw
				assert(g.boss.action=="charge" and view.action=="charge","Charge review missed the active travelling pose")
				var charge_head=view.rig_skeleton.find_bone("head")
				var charge_forward=(view.rig_skeleton.global_basis*view.rig_skeleton.get_bone_global_pose(charge_head).basis.y).normalized()
				assert(charge_forward.y<=.04,"Charge raised the head toward the sky")
				print("TRICERATOPS CHARGE POSE / phase=",phase," contact=",g.boss.contact_done," head=",charge_forward)
			else:
				while g.boss.action in ["charge","strike"] and not g.boss.contact_done:await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var progress=clampf(1-g.boss.action_left/maxf(.01,g.boss.action_length),0,1)
			print("TRICERATOPS IMPACT / phase=",phase," move=",g.boss.move," state=",g.boss.action," physical progress=",progress," clip=",view.action," clock=",view.animation_clock)
			get_viewport().get_texture().get_image().save_png("res://build/boss-animation-review/triceratops-impact-%d-%d.png"%[phase,move])
			await get_tree().create_timer(1.5).timeout
	print("TRICERATOPS COMBAT / three attacks / contact overreach=",view.contacts.unreachable," max body drop=",view.contacts.maximum_body_drop)
	# Review player-directed gaze from four approach angles after combat.
	g.boss.action="recover";g.boss.action_left=100;g.hazards.clear()
	g.pos=g.boss.p+Vector2(60,0)
	await get_tree().create_timer(3).timeout
	var separation=g.pos.distance_to(g.boss.p)
	print("TRICERATOPS CLOSE SPACING / after retreat=",separation)
	assert(separation>115 and separation<185,"Boss did not recover usable attack spacing")
	for offset in [Vector2(180,0),Vector2(0,180),Vector2(-180,0),Vector2(0,-180)]:
		# This isolated pose review must not open a nearby cache's choice
		# menu: that freezes the renderer while the review timer continues.
		g.relic_chests.clear();g.gems.clear();g.choosing=false;game.clear_menu()
		g.pos=g.boss.p+offset;g.boss.action_left=100
		await get_tree().create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		var head=view.rig_skeleton.find_bone("head")
		var forward=(view.rig_skeleton.global_basis*view.rig_skeleton.get_bone_global_pose(head).basis.y).normalized()
		print("TRICERATOPS GAZE / approach=",offset," paused=",game.paused," choosing=",g.choosing," active=",g.active," action=",g.boss.action," heading=",view.heading," desired=",view.desired_heading," forward=",forward," correction=",view.gaze_pitch," contacts=",view.contacts.unreachable)
		assert(forward.y<=.03 and forward.y>-.9,"Head escaped the grounded gaze range")
		assert(Vector2(forward.x,forward.z).normalized().dot((g.pos-g.boss.p).normalized())>.9,"Head did not follow the actual player position")
		get_viewport().get_texture().get_image().save_png("res://build/boss-animation-review/triceratops-gaze-%d-%d.png"%[int(offset.x),int(offset.y)])
	print("TRICERATOPS FULL CONTACT REVIEW / overreach=",view.contacts.unreachable," support shift=",view.contacts.maximum_support_shift," contact error=",view.contacts.maximum_contact_error," bone length error=",view.contacts.maximum_length_error)
	assert(view.contacts.unreachable==0,"A supporting leg exhausted its reach")
	game.paused=true
	var before=view.animation_clock
	await get_tree().create_timer(.15).timeout
	assert(is_equal_approx(before,view.animation_clock),"Boss animation continued while paused")
	game.paused=false
	g.kill(g.boss);await get_tree().process_frame
	assert(g.boss==null,"Boss remained active after death")
	assert(preload("res://scripts/dinosaur_boss_art.gd").corpse("thorn")!=null,"Original corpse API is missing")
	print("TRICERATOPS INTEGRATION / two phases, pause, death and original corpse API passed")
	# Release playback while the mixer can still process its stop commands.
	game.paused=true
	game.audio.shutdown()
	await get_tree().create_timer(.1).timeout
	get_tree().quit()
