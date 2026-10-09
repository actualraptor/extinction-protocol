extends Node2D

var world
const Hostile = preload("res://scripts/hostile_fx.gd")
const Icons = preload("res://scripts/atlas_icons.gd")
var survivor = preload("res://scripts/survivor_animation.gd").new()
var boss_model
var boss_model_identity=""
var meteor_model
var meteor_fire
var boss_sim
var last_boss_p=Vector2.ZERO
var movement_clock=0.0
var boss_speed=0.0
var previous_physics_p=Vector2.ZERO
var latest_physics_p=Vector2.ZERO
var rendered_boss_p=Vector2.ZERO
var last_sim_time=-1.0
var boss_uid=-1
var depth_meshes=[]
var hazard_draw_meshes=[]
var depth_material:ShaderMaterial
var review_process_ms=0.0
var review_draw_ms=0.0
var held_feet={}
var foot_contacts_ready=false
var footstep_action=""

func _process(dt):
	var review_started=Time.get_ticks_usec()
	if world.sim != null: survivor.update(world.sim)
	var s=world.sim
	if s!=null and s.boss!=null and s.boss_stage==3 and "--meteor-rig-test" in OS.get_cmdline_user_args():
		if meteor_fire==null:
			meteor_fire=preload("res://scripts/meteor_fire_view.gd").new();meteor_fire.world=world;add_child(meteor_fire)
		if meteor_model==null:
			meteor_model=preload("res://scripts/meteor_model_view.gd").new();add_child(meteor_model)
		meteor_model.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED if "--meteor-no-model-render-review" in OS.get_cmdline_user_args() else SubViewport.UPDATE_ALWAYS
		if not world.get_parent().get("paused") and not s.choosing:meteor_model.present(s,dt)
		if s.meteor_entry_time>0:
			var entry_progress=1.0-s.meteor_entry_time/4.2
			world.shake=maxf(world.shake,1.8+sin(world.clock*31.0)*.7)
			if entry_progress>.84:world.shake=maxf(world.shake,8.0+sin(world.clock*46.0)*2.5)
	elif meteor_model!=null:meteor_model.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	var enabled=world.rig_bosses and s!=null and s.boss!=null and s.boss_stage!=3 and (s.boss.get("identity","")=="basalt" or (s.boss.get("identity","")=="thorn" and ("--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"))))
	if enabled:
		var identity=s.boss.get("identity","")
		if boss_model!=null and boss_model_identity!=identity:
			remove_child(boss_model)
			boss_model.queue_free()
			boss_model=null
		if boss_model==null:
			boss_model_identity=identity
			boss_model=(preload("res://scripts/triceratops_model_view.gd").new() if identity=="thorn" else preload("res://scripts/boss_model_view.gd").new());boss_model.show_sprite=false;add_child(boss_model)
			boss_model.set_process(false);boss_model.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		boss_model.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		if boss_sim!=s or boss_uid!=s.boss.uid:
			boss_sim=s;boss_uid=s.boss.uid;last_boss_p=s.boss.p;boss_speed=0;movement_clock=0;boss_model.initialized=false;held_feet.clear();foot_contacts_ready=false;footstep_action=""
			previous_physics_p=s.boss.p;latest_physics_p=s.boss.p;rendered_boss_p=s.boss.p;last_sim_time=s.time
		var frozen=world.get_parent().get("paused") or s.choosing
		if not frozen:
			if not is_equal_approx(last_sim_time,s.time):
				previous_physics_p=latest_physics_p;latest_physics_p=s.boss.p;last_sim_time=s.time
			rendered_boss_p=previous_physics_p.lerp(latest_physics_p,clampf(Engine.get_physics_interpolation_fraction(),0,1))
			movement_clock+=dt
			if last_boss_p.distance_squared_to(s.boss.p)>.001:
				boss_speed=lerpf(boss_speed,last_boss_p.distance_to(s.boss.p)/maxf(.001,movement_clock),.8)
				last_boss_p=s.boss.p;movement_clock=0
			elif movement_clock>.08:boss_speed=lerpf(boss_speed,0,1-exp(-12*dt))
			boss_model.present(s.boss,dt,boss_speed,rendered_boss_p,s.pos)
			if "--painted-foot-plant" in OS.get_cmdline_user_args() or "--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"):
				var quadruped=s.boss.get("identity","")=="thorn"
				var contacts=boss_model.contacts.anchors if quadruped else boss_model.foot_plant.anchors
				var stable_contacts=boss_model.transition_poses.is_empty()
				# Contact solvers reseed anchors after a pose blend. Those existing
				# supports are not new landings: don't play a thud for each one.
				if boss_model.action in ["walk","run","charge"] and stable_contacts and foot_contacts_ready and footstep_action==boss_model.action:
					for side in contacts:
						var lifted=quadruped and boss_model.contacts.steps.has(side)
						var replant=quadruped and boss_model.contacts.landed_feet.has(side)
						if (not held_feet.has(side) and not lifted) or replant:
							s.sound.emit("dino_thorn_step" if quadruped else "dino_basalt_step")
							world.shake=maxf(world.shake,(.7 if boss_model.action=="walk" else 1.2) if quadruped else 1.2 if boss_model.action=="walk" else 2.0)
				held_feet=contacts.duplicate()
				foot_contacts_ready=stable_contacts
				footstep_action=boss_model.action

	elif boss_model!=null:boss_model.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	queue_redraw()
	review_process_ms=(Time.get_ticks_usec()-review_started)/1000.0

func _draw():
	var review_started=Time.get_ticks_usec()
	depth_meshes.clear()
	hazard_draw_meshes.clear()
	var s = world.sim
	if s==null: return
	world.draw_dinosaur_deaths(self)
	# Boss silhouette and hostile casts stay above every friendly spell layer.
	if s.boss!=null and s.boss_stage==3:
		if meteor_model!=null and "--meteor-rig-test" in OS.get_cmdline_user_args():meteor_model.draw_ground_shadow(self,world.screen(s.boss.p),s.phase,clampf(s.boss_time/3,0,1))
		else:world.sprite(8,world.screen(s.boss.p),310*(1+(s.phase-1)*0.12),false,Color.WHITE,sin(world.clock*0.5)*0.08,self)
	elif s.boss!=null:
		var e=s.boss
		var p=world.screen(e.p)+Vector2(0,-e.get("lift",0.0))
		var tint=Color(1.6,1.6,1.6) if e.flash>0 else Color.WHITE
		tint.a=e.get("fade",1.0)
		if world.rig_bosses and (e.identity=="basalt" or (e.identity=="thorn" and ("--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")))) and boss_model!=null:
			var at=world.screen(rendered_boss_p)
			var direction=e.get("motion",e.aim)
			if direction.length_squared()<.01:direction=e.aim
			if "--painted-foot-plant" in OS.get_cmdline_user_args() or "--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"):boss_model.draw_contact_shadows(self,at)
			else:
				draw_set_transform(at-direction*34,0,Vector2(1,.32));draw_circle(Vector2.ZERO,105,Color(0,0,0,.23));draw_set_transform(Vector2.ZERO)
		else:preload("res://scripts/dinosaur_boss_art.gd").draw(self,e,world.screen(e.p),world.clock,tint)
	preload("res://scripts/boss_visuals.gd").draw(self,world)
	for h in s.hazards:
		if h.kind=="friendly": continue
		Hostile.hazard(self,h,world.screen(h.p),world.clock)
		# Retain resources owned by hazards until their canvas commands are
		# replaced. Clearing hazards on victory must not free live draw RIDs.
		if h.has("warning_soil_mesh"):hazard_draw_meshes.append(h.warning_soil_mesh)
	for e in s.enemies:
		if e.get("spit_wait",0)>0:
			var mouth = world.screen(e.p)
			Hostile.piece(self,3,mouth+e.spit_dir*14,Vector2(54,38)*(0.9+0.12*sin(world.clock*20)),e.spit_dir.angle()+PI,0.9)
		if e.get("charge_wait",0)>0:
			var start = world.screen(e.p)
			Hostile.piece(self,4,start+e.charge_dir*100,Vector2(220,75),e.charge_dir.angle(),0.7)
	# Stage rewards are static authored objects; only nearby art is submitted.
	for item in s.stage_objects:
		if item.collected:continue
		var at=world.screen(item.p)
		if not world.visible_rect().grow(110).has_point(at):continue
		var category="relic" if item.type=="cache" else item.type
		var icon="chest" if item.type=="cache" else item.id
		draw_set_transform(at,0,Vector2(1,.35))
		draw_circle(Vector2.ZERO,33,Color(.015,.025,.02,.65))
		draw_arc(Vector2.ZERO,36,0,TAU,36,Color(.75,.62,.35,.6),2,true)
		draw_set_transform(Vector2.ZERO)
		draw_texture_rect(Icons.get_icon(icon,category),Rect2(at-Vector2(28,56+sin(world.clock*2)*3),Vector2(56,56)),false)
		if s.pos.distance_squared_to(item.p)<280*280:
			var caption=item.name
			if item.get("encounter","")=="ambush":
				caption += " / "+str(item.guards.filter(func(e):return not e.dead).size())+" GUARDIANS" if item.started else " / GUARDED"
			var width=world.font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
			draw_string(world.font,at+Vector2(-width/2,25),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e7d9ab"))
	for marker in s.landmarks:
		if marker.found: continue
		var at = world.screen(marker.p)
		if not world.visible_rect().grow(100).has_point(at): continue
		var discovery=s.Discoveries.ENTRIES.get(marker.id,{})
		var art="camp" if discovery.has("hero") else "chronicle" if discovery.has("relics") else "chest"
		draw_texture_rect(Icons.get_icon(art,"relic"),Rect2(at-Vector2(46,76),Vector2(92,92)),false)
		draw_arc(at,42,0,TAU,32,Color("f4cf88"),2,true)
		draw_string(world.font,at+Vector2(-70,35),"DISCOVER / "+marker.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f7d797"))
	if s.portal!=null:
		var gate = world.screen(s.portal)
		draw_string(world.font,gate+Vector2(-100,110),"STEP INTO THE RIFT",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b4e7ff"))
		if s.portal_charge>0: draw_arc(gate,54,-PI/2,-PI/2+TAU*s.portal_charge/s.PORTAL_CHARGE_SECONDS,40,Color("e6ccff"),5,true)
	for shot in s.hostile_shots:
		if shot.has("theme"):continue
		var p = world.screen(shot.p)
		var dir = shot.v.normalized()
		Hostile.piece(self,3,p-dir*13,Vector2(65,42),dir.angle()+PI)
	if s.transition_time>0:
		var fade = s.transition_time/1.25
		draw_rect(world.visible_rect(),Color(0.04,0.08,0.16,fade))
	# Actors overlap by their ground position; ground tells stay underneath.
	for impact in world.effects:
		if impact.kind=="dino_earth_impact":
			Hostile.travelling_ground_fx(self,{"kind":"circle","radius":impact.size,"life":impact.life,"max_life":impact.max,"wave":0},world.screen(impact.p))
	var rig_active=world.rig_bosses and s.boss!=null and s.boss_stage!=3 and (s.boss.identity=="basalt" or (s.boss.identity=="thorn" and ("--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")))) and boss_model!=null
	var meteor_active=meteor_model!=null and s.boss!=null and s.boss_stage==3 and "--meteor-rig-test" in OS.get_cmdline_user_args()
	var actor_layers=[{"y":s.pos.y,"kind":"player"}]
	if rig_active or meteor_active:
		actor_layers.append({"y":s.boss.p.y if meteor_active else rendered_boss_p.y,"kind":"meteor" if meteor_active else "boss"})
		for landmark in s.terrain.stage.get("landmarks",[]):
			actor_layers.append({"y":landmark.p.y,"kind":"landmark","data":landmark})
		for enemy in s.enemies:
			if world.landmark_depth_enemy(enemy):actor_layers.append({"y":enemy.get("render_p",enemy.p).y,"kind":"enemy","data":enemy})
	actor_layers.sort_custom(func(a,b):return a.y<b.y)
	var enemy_batch=[]
	for actor in actor_layers:
		if actor.kind=="enemy":
			enemy_batch.append(actor.data);continue
		if not enemy_batch.is_empty():
			draw_depth_enemies(enemy_batch,s);enemy_batch.clear()
		if actor.kind=="landmark":world.draw_landmark_art(self,actor.data)
		elif actor.kind=="player":draw_survivor(s)
		elif actor.kind=="meteor":
			var meteor_at=world.screen(s.boss.p)
			if s.meteor_entry_time>0:
				var entry_progress=1.0-s.meteor_entry_time/4.2
				var flight=clampf(entry_progress/.64,0,1)
				var return_progress=clampf((entry_progress-.64)/.36,0,1)
				var screen=world.visible_rect().size
				# Keep the full 400px renderable body inside the camera. The old
				# +/-520 path intentionally crossed the canvas edge and clipped it.
				var edge=220.0
				var flight_at=Vector2(screen.x-edge,screen.y*.18).lerp(Vector2(edge,screen.y*.32),flight)
				# Keep the setup off-screen, then bring the full 400px texture
				# beyond its half-width before the visible return arc.
				var arc_a=Vector2(edge,screen.y*.32)
				var arc_b=Vector2(screen.x*.18,screen.y*.10)
				var arc_c=world.screen(s.boss.p)+Vector2(0,-120)
				var arc_t=arc_a.lerp(arc_b,clampf(return_progress*2,0,1)).lerp(arc_b.lerp(arc_c,clampf(return_progress*2-1,0,1)),clampf(return_progress*2,0,1))
				# Only use a brief edge transition. Once the return begins, the
				# full body must be inside the frame instead of lingering clipped.
				var edge_return=clampf(return_progress/.08,0,1)
				meteor_at=flight_at.lerp(arc_a,edge_return) if return_progress<.08 else arc_t
				draw_meteor_entry_fx(self,meteor_at,flight,return_progress,entry_progress,screen)
			meteor_model.draw_body(self,meteor_at,s.phase)
		else:
			var tint=Color(1.6,1.6,1.6) if s.boss.flash>0 else Color.WHITE
			tint.a=s.boss.get("fade",1.0)
			boss_model.draw_body(self,world.screen(rendered_boss_p)+Vector2(0,-s.boss.get("lift",0)),tint)
	if not enemy_batch.is_empty():draw_depth_enemies(enemy_batch,s)
	draw_crit_feedback()
	if s.boss!=null and s.boss_stage==3:
		if not "--meteor-rig-test" in OS.get_cmdline_user_args():draw_arc(world.screen(s.boss.p),720,0,TAU,100,Color(1,0.3,0.2,0.5),5,true)
	review_draw_ms=(Time.get_ticks_usec()-review_started)/1000.0

func draw_meteor_entry_fx(canvas:CanvasItem,at:Vector2,flight:float,return_progress:float,progress:float,screen:Vector2)->void:
	# Full-screen authored entrance language: a hot leading core, long
	# turbulent trail and an impact bloom. The model remains centered in its
	# viewport; these effects are drawn in world space and are never cropped.
	var returning=return_progress>0.0
	var direction=Vector2(-1,0) if not returning else Vector2(1,-.25).normalized()
	var trail=620.0 if not returning else 420.0
	var flicker=.82+.18*sin(world.clock*37.0)
	for band in range(5):
		var width=52.0-band*8.0
		var offset=sin(world.clock*9.0+band*1.7)*10.0
		var trail_start=at-direction*(trail+band*32)+direction.orthogonal()*offset
		var trail_end=at-direction*(24+band*8)+direction.orthogonal()*offset*.2
		canvas.draw_line(trail_start,trail_end,Color(1.0,.10,.015,(.10-band*.014)*flicker),width,true)
		canvas.draw_line(trail_start,trail_end,Color(1.0,.62,.12,(.35-band*.045)*flicker),maxf(3,width*.16),true)
	for ember in range(24):
		var seed=float(ember*31)
		var t=fposmod(world.clock*(1.4+ember*.03)+seed*.17,1.0)
		var p=at-direction*(35+t*trail)+direction.orthogonal()*sin(seed+world.clock*4.0)*18
		canvas.draw_circle(p,1.5+(ember%4),Color(1.0,.35,.06,.55*(1-t)))
	if progress>.84:
		var impact=clampf((progress-.84)/.16,0,1)
		var radius=70+impact*210
		canvas.draw_circle(at+Vector2(0,34),radius,Color(1.0,.12,.015,.11*(1-impact)))
		canvas.draw_arc(at+Vector2(0,34),radius,0,TAU,64,Color(1.0,.44,.08,.65*(1-impact)),8,true)

func draw_depth_enemies(enemies,s):
	var vertices=PackedVector3Array();var uvs=PackedVector2Array();var colors=PackedColorArray();var indices=PackedInt32Array()
	if depth_material==null:
		depth_material=ShaderMaterial.new();depth_material.shader=preload("res://shaders/depth_swarm.gdshader")
	var art=preload("res://scripts/dinosaur_art.gd")
	var frozen=s.buffs.get("freeze",0)>0
	for enemy in enemies:
		var width=enemy.size*4.0*enemy.get("visual_scale",1.0)
		var at=world.screen(enemy.get("render_p",enemy.p))
		var iced=frozen or enemy.get("frozen",0)>0
		if not iced:at.y+=sin(world.clock*9.0+float(enemy.uid%100)*.17)*.025*width*.75
		var facing=enemy.get("motion",Vector2.RIGHT).x<-.01
		var rect=art.region(enemy.kind,art.frame(enemy,world.clock,frozen))
		var tint=Color(1.8,1.8,1.8) if enemy.flash>0 else Color("a2c3ff") if frozen or enemy.slow>0 or enemy.get("frozen",0)>0 else Color("eabcff") if enemy.mutated else Color.WHITE
		tint*=enemy.get("visual_tint",Color.WHITE)
		var first=vertices.size()
		for corner in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
			vertices.append(Vector3(at.x+(corner.x-.5)*width,at.y+(corner.y*.75-.72)*width,0))
			var uv=(rect.position+Vector2(1-corner.x if facing else corner.x,corner.y)*rect.size)/Vector2(art.SHEET.get_size())
			if iced:uv.x=-uv.x-1.0
			uvs.append(uv)
			colors.append(tint)
		for index in [0,1,2,0,2,3]:indices.append(first+index)
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,depth_material)
	depth_meshes.append(mesh)
	draw_mesh(mesh,art.SHEET)

func draw_survivor(s):
	var at=world.screen(s.pos)
	draw_arc(at+Vector2(0,2),25,0,TAU,40,Color(.85,.96,1,.85),2,true)
	survivor.draw(self,s,at,Color(1,1,1,.75 if s.invul>0 and sin(s.time*40)>0 else 1))

static func crit_tint(tier: int,time: float):
	if tier>=5: return Color.from_hsv(fposmod(time*.65+(tier-5)*.17,1),.62,1)
	return [Color.WHITE,Color("ffd884"),Color("ff9a36"),Color("ff60cd"),Color("65edff")][clampi(tier,0,4)]

func draw_crit_feedback():
	for burst in world.crit_bursts:
		var tier=mini(burst.tier,8)
		var age=1-burst.life/burst.max
		var alpha=pow(1-age,1.5)
		var at=world.screen(burst.p)
		var tint=crit_tint(burst.tier,world.clock+burst.seed)
		var radius=(7+tier*3)*(0.35+age*1.5)
		# Short radial shards grow into an impact crown. No persistent opaque disk.
		var rays=4+mini(tier,6)*2
		for i in range(rays):
			var angle=TAU*i/rays+burst.seed*.3
			var direction=Vector2.from_angle(angle)
			var ray_color=Color.from_hsv(fposmod(float(i)/rays+world.clock*.7,1),.60,1) if burst.tier>=5 else tint
			draw_line(at+direction*radius*.65,at+direction*radius*(1.2+tier*.05),Color(ray_color,alpha*.85),1.2+mini(tier,4)*.3,true)
		if tier>=2:
			draw_arc(at,radius*.65,0,TAU,24,Color(tint,alpha*.40),1.3,true)
		if tier>=3:
			var core=4+mini(tier,6)
			var points=PackedVector2Array([at+Vector2(0,-core),at+Vector2(core*.45,0),at+Vector2(0,core),at-Vector2(core*.45,0)])
			draw_colored_polygon(points,Color(1,1,1,alpha*.7))
		if tier>=5:
			draw_arc(at,radius*.95,burst.seed+age*2,burst.seed+age*2+PI*.7,20,Color(tint,alpha*.65),2,true)
	for n in world.numbers:
		var tier=n.get("tier",0)
		var strength=mini(tier,8)
		var fs=18+strength*2
		var age=n.get("max",.75)-n.life
		var pop=1+(.10+strength*.035)*sin(clampf(age/.16,0,1)*PI) if tier>0 else 1.0
		var tint=crit_tint(tier,world.clock) if tier>0 else n.color
		var alpha=clampf(n.life/.25,0,1)
		var at=world.screen(n.p)+Vector2(n.get("sway",0)*sin(age*8)*strength*.6,0)
		var width=world.font.get_string_size(n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		draw_set_transform(at,0,Vector2.ONE*pop)
		var origin=Vector2(-width*.5,0)
		if tier>=3:
			draw_string_outline(world.font,origin,n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,5,Color(tint,alpha*.20))
		draw_string_outline(world.font,origin,n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,3,Color(.015,.025,.035,alpha))
		draw_string(world.font,origin,n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color(tint,alpha))
		draw_set_transform(Vector2.ZERO)


