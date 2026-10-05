extends Node2D

const C = preload("res://scripts/catalog.gd")
const Seasonal = preload("res://scripts/seasonal_theme.gd")
var sim = null
var atlas = preload("res://assets/characters-v2.png")
var monster_sheet = preload("res://assets/monsters-04.png")
var monster_regions = []
var frontier_sheet=preload("res://assets/frontiers-07.png")
var frontier_ground=preload("res://assets/frontier-ground-07.png")
var frontier_regions=[]
var terrain = preload("res://assets/terrain.png")
var props = preload("res://assets/props.png")
var pickup_sheet = preload("res://assets/pickups.png")
var feature_sheet = preload("res://assets/terrain-features.png")
var clock = 0.0
var next_crit_flash = 0.0
var crit_bursts = []
const MAX_CRIT_BURSTS = 24
const MAX_DAMAGE_NUMBERS = 65
var shake = 0.0
var shake_enabled = true
var flashes = 0.0
var effects = []
var particles = []
var numbers = []
var emitters = []
var camera_offset = Vector2.ZERO
var camera_pos = Vector2.ZERO
var camera_run = null
var stage_landmark_sheet
var stage_landmark_regions = []
var font = preload("res://scripts/ui_art.gd").body_font()
var selected = 0
var vignette = null

func _ready():
	var ground_layer = preload("res://scripts/continuous_ground.gd").new()
	ground_layer.world = self
	ground_layer.z_index = -2
	add_child(ground_layer)
	var kael_ground=preload("res://scripts/kael_ground_fracture.gd").new()
	kael_ground.world=self
	kael_ground.z_index=-1
	add_child(kael_ground)
	for r in JSON.parse_string(FileAccess.get_file_as_string("res://assets/monster-regions.json"))[0]: monster_regions.append(Rect2(r[0],r[1],r[2],r[3]))
	for r in JSON.parse_string(FileAccess.get_file_as_string("res://assets/frontier-regions.json")): frontier_regions.append(Rect2(r[0],r[1],r[2],r[3]))
	var swarm = preload("res://scripts/swarm_renderer.gd").new()
	swarm.world = self
	swarm.z_index = 1
	add_child(swarm)
	var more_swarm = preload("res://scripts/swarm_renderer.gd").new()
	more_swarm.world = self
	more_swarm.extra = true
	more_swarm.z_index = 1
	add_child(more_swarm)
	var frontier_swarm = preload("res://scripts/swarm_renderer.gd").new()
	frontier_swarm.world=self
	frontier_swarm.frontier=true
	frontier_swarm.z_index=1
	add_child(frontier_swarm)
	for i in range(10):
		var emitter = GPUParticles2D.new()
		emitter.emitting = false
		emitter.amount = 32
		emitter.lifetime = 0.6
		emitter.one_shot = true
		emitter.explosiveness = 1.0
		emitter.visibility_rect = Rect2(-1500,-1500,3000,3000)
		var material = ParticleProcessMaterial.new()
		material.direction = Vector3(1,0,0)
		material.spread = 180
		material.gravity = Vector3(0,120,0)
		material.initial_velocity_min = 65
		material.initial_velocity_max = 280
		material.scale_min = 2
		material.scale_max = 5
		emitter.process_material = material
		var gradient = Gradient.new()
		gradient.set_color(0,Color(1,0.95,0.8,1))
		gradient.set_color(1,Color(1,0.7,0.4,0))
		var glow_texture = GradientTexture2D.new()
		glow_texture.gradient = gradient
		glow_texture.width = 16
		glow_texture.height = 16
		glow_texture.fill = GradientTexture2D.FILL_RADIAL
		glow_texture.fill_from = Vector2(0.5,0.5)
		glow_texture.fill_to = Vector2(1,0.5)
		emitter.texture = glow_texture
		material.scale_min = 0.25
		material.scale_max = 0.65
		var additive = CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		emitter.material = additive
		add_child(emitter)
		emitters.append(emitter)

	var impact_layer = preload("res://scripts/spell_fx.gd").new()
	impact_layer.world = self
	impact_layer.impacts = true
	impact_layer.z_index = 2
	add_child(impact_layer)
	var weapon_layer = preload("res://scripts/spell_fx.gd").new()
	weapon_layer.world = self
	weapon_layer.z_index = 3
	add_child(weapon_layer)
	var readable = preload("res://scripts/readability.gd").new()
	readable.world = self
	readable.z_index = 5
	add_child(readable)

func visible_rect(): return Rect2(-position,get_viewport_rect().size)

func screen(p): return p-(camera_pos if sim != null else Vector2.ZERO)+Vector2(720,465)+camera_offset

func fx(kind,p,color,size):
	if kind=="crit":
		if clock<next_crit_flash: return
		next_crit_flash=clock+0.045
		var tier=maxi(1,int(size))
		if crit_bursts.size()<MAX_CRIT_BURSTS:
			var duration=.18+mini(tier,7)*.025
			crit_bursts.append({"p":p,"tier":tier,"life":duration,"max":duration,"seed":crit_bursts.size()*1.37+clock})
		return
	if kind=="number" or kind.begins_with("crit_number_"):
		var tier=int(kind.get_slice("_",2)) if kind.begins_with("crit_number_") else 0
		if numbers.size()<MAX_DAMAGE_NUMBERS:
			var duration=.75 if tier>1 else .65
			numbers.append({"p":p,"color":color,"text":str(int(size)),"tier":tier,"life":duration,"max":duration,"sway":sin(p.x*.071+p.y*.093)})
		return
	var life = 0.10 if kind in ["muzzle","crit"] else 1.15 if kind in ["level","evolve","victory"] else 0.52
	if kind.begins_with("kael_slam_") or kind.begins_with("kael_crater_"):
		life=clampf(float(kind.get_slice("_",5))*.001,.10,.46)
		# Retire only old visual fronts; all queued damage bands still execute.
		var count=0;var oldest=-1
		for i in range(effects.size()):
			if effects[i].kind.begins_with("kael_"):
				count+=1
				if oldest<0:oldest=i
		if count>=16 and oldest>=0:effects.remove_at(oldest)
	if effects.size()<160: effects.append({"kind":kind,"p":p,"color":color,"size":size,"life":life,"max":life})
	if kind in ["level","evolve","victory","hurt","impact"]:
		shake = maxf(shake,18 if kind=="victory" else 8 if kind=="hurt" else 4)
	if kind in ["level","evolve","victory"]: flashes = 1
	if kind in ["impact","level","evolve","victory"]:
		for emitter in emitters:
			if not emitter.emitting:
				emitter.position = screen(p)
				emitter.process_material.color = color
				emitter.restart()
				emitter.emitting = true
				break
	var count = 42 if kind in ["victory","level"] else 4 if kind.begins_with("blast_") or kind=="impact" else mini(2,int(size)) if kind=="sparks" else 0
	for j in range(mini(count,240-particles.size())):
		particles.append({"p":p,"v":Vector2.from_angle(randf()*TAU)*randf_range(40,220),"color":color,"life":randf_range(0.15,0.65),"size":randf_range(1.5,4)})

func _process(dt):
	clock += dt
	if sim!=null:
		if camera_run!=sim:
			camera_pos = sim.pos
			camera_run = sim
		camera_pos = camera_pos.lerp(sim.pos,1-exp(-dt*35))
	else: camera_run = null
	shake = maxf(0,shake-dt*25)
	flashes = maxf(0,flashes-dt*1.5)
	camera_offset = Vector2(randf_range(-shake,shake),randf_range(-shake,shake)) if shake_enabled else Vector2.ZERO
	for e in effects: e.life -= dt
	effects = effects.filter(func(e):return e.life>0)
	for burst in crit_bursts: burst.life-=dt
	crit_bursts=crit_bursts.filter(func(burst):return burst.life>0)
	for p in particles:
		p.life -= dt
		p.p += p.v*dt
		p.v *= exp(-dt*2)
	particles = particles.filter(func(p):return p.life>0)
	for n in numbers:
		n.life -= dt
		n.p.y -= dt*(42+mini(n.get("tier",0),7)*5)
	numbers = numbers.filter(func(n):return n.life>0)
	if vignette != null:
		vignette.set_shader_parameter("danger",0.0 if sim==null else maxf(0,1-sim.hp/sim.max_hp*2))
		vignette.set_shader_parameter("flash",flashes)
		vignette.set_shader_parameter("frozen",1.0 if sim!=null and sim.buffs.get("freeze",0)>0 else 0.0)
	queue_redraw()

func sprite(index,p,size,flip = false,tint = Color.WHITE,angle = 0.0,target = null):
	if target==null: target = self
	var cell_size = Vector2(atlas.get_size())/3.0
	var source = Rect2(Vector2(index%3,floori(index/3.0))*cell_size,cell_size)
	var sheet = atlas
	if sim!=null and sim.halloween and index>=3 and index!=8:
		sheet=Seasonal.texture_for(0)
		source=Seasonal.regions_for(0)[index]
	target.draw_set_transform(p,angle,Vector2(-1 if flip else 1,1))
	target.draw_texture_rect_region(sheet,Rect2(Vector2(-size/2,-size*0.75),Vector2(size,size)),source,tint)
	target.draw_set_transform(Vector2.ZERO)

func glow(p,radius,color):
	for j in range(4,0,-1):
		var c = color
		c.a = 0.025*(5-j)
		draw_circle(p,radius*j*0.28,c)

func _draw():
	var biome = sim.Maps.biome(sim.map_id,sim.depth) if sim!=null else C.BIOMES[0]
	var center = camera_pos if sim != null else Vector2(clock*7,0)
	# Illustrated biome props replace geometric environment placeholders.
	if sim==null:
		for gx in range(floori((center.x-get_viewport_rect().size.x/2-100)/260),ceili((center.x+get_viewport_rect().size.x/2+100)/260)):
			for gy in range(floori((center.y-get_viewport_rect().size.y/2-100)/260),ceili((center.y+get_viewport_rect().size.y/2+100)/260)):
				var h = absi((gx*73856093)^(gy*19349663))
				if h%3!=0: continue
				var p = Vector2(gx*260+h%100,gy*260+(h/7)%100)-center+Vector2(720,465)+camera_offset
				prop(6+(sim.depth if sim!=null else 0),p,110+h%50,Color(0.55,0.62,0.62,0.85))
	for i in range(35):
		var p = Vector2(fmod(i*171.3+sin(clock+i)*15,1440),fmod(i*91.7-clock*9,900))
		draw_circle(p,1.5,Color(0.8,0.8,0.65,0.15))
	if sim == null:
		glow(Vector2(1040,400),380,Color("fd8355"))
		sprite(8,Vector2(1080,400+sin(clock)*12),480,false,Color(0.75,0.6,0.6))
		for i in range(12):
			var a = clock*0.12+i*TAU/12
			draw_circle(Vector2(1080,380)+Vector2.from_angle(a)*320,4,Color("e89f78"))
		return
	for x in range(floori((center.x-get_viewport_rect().size.x/2-100)/64),ceili((center.x+get_viewport_rect().size.x/2+100)/64)):
		for y in range(floori((center.y-get_viewport_rect().size.y/2-100)/64),ceili((center.y+get_viewport_rect().size.y/2+100)/64)):
			var c = Vector2i(x,y)
			var kind = sim.terrain.kind(c)
			if kind==0: continue
			var index = sim.depth if kind==1 else 3 if kind==2 else 4
			var tile_size = Vector2(feature_sheet.get_size())/Vector2(3,2)
			var region = Rect2(Vector2(index%3,floori(index/3.0))*tile_size,tile_size)
			var p = screen(sim.terrain.center(c))
			if kind==1:
				if sim.map_id!="cradle":
					var art=preload("res://scripts/atlas_icons.gd").frontier(8 if sim.map_id=="frostbreak" else 10)
					draw_texture_rect(art,Rect2(p-Vector2(39,49),Vector2(78,86)),false)
				else: draw_texture_rect_region(feature_sheet,Rect2(p-Vector2(39,42),Vector2(78,78)),region)
			else:
				p += Vector2.ZERO
				if sim.map_id!="cradle":
					draw_texture_rect(preload("res://scripts/atlas_icons.gd").frontier(9 if sim.map_id=="frostbreak" else 11),Rect2(p-Vector2(100,80),Vector2(200,160)),false)
				else: draw_texture_rect_region(feature_sheet,Rect2(p-Vector2(40,40),Vector2(80,80)),region)
	# Sparse local scenery follows region identity and never creates collision.
	for gx in range(floori((center.x-get_viewport_rect().size.x/2-100)/384),ceili((center.x+get_viewport_rect().size.x/2+100)/384)):
		for gy in range(floori((center.y-get_viewport_rect().size.y/2-100)/384),ceili((center.y+get_viewport_rect().size.y/2+100)/384)):
			var h=absi(gx*92821 ^ gy*68917 ^ sim.terrain.seed_value)
			if h%3!=0: continue
			var at=Vector2(gx*384+50+h%80,gy*384+50+(h/7)%80)
			if not sim.terrain.walkable(at,36): continue
			if sim.map_id=="cradle": prop(6+sim.depth,screen(at),75+h%30,Color(0.7,0.8,0.74,0.65))
			else: draw_texture_rect(preload("res://scripts/atlas_icons.gd").frontier(9 if sim.map_id=="frostbreak" else 11),Rect2(screen(at)-Vector2(50,50),Vector2(100,85)),false,Color(0.7,0.8,0.9,0.65))
	for landmark in sim.terrain.stage.get("landmarks",[]):
		var at = screen(landmark.p)
		var size_value = float(landmark.get("scale",220.0))
		if not visible_rect().grow(size_value).has_point(at): continue
		glow(at,size_value*0.65,Color("b0ac83"))
		if landmark.has("landmark_art") and ResourceLoader.exists("res://assets/stage-landmarks-092.png"):
			if stage_landmark_sheet==null:
				stage_landmark_sheet = load("res://assets/stage-landmarks-092.png")
				if FileAccess.file_exists("res://assets/stage-landmarks-092-regions.json"):
					for r in JSON.parse_string(FileAccess.get_file_as_string("res://assets/stage-landmarks-092-regions.json")): stage_landmark_regions.append(Rect2(r[0],r[1],r[2],r[3]))
			var index = int(landmark.landmark_art)
			var cell_size = Vector2(stage_landmark_sheet.get_size())/Vector2(3,2)
			var region = stage_landmark_regions[index] if index<stage_landmark_regions.size() else Rect2(Vector2(index%3,floori(index/3.0))*cell_size,cell_size)
			var dimensions = region.size*(size_value/maxf(region.size.x,region.size.y))
			draw_texture_rect_region(stage_landmark_sheet,Rect2(at-Vector2(dimensions.x*0.5,dimensions.y*0.72),dimensions),region,Color(0.82,0.87,0.86))
		elif landmark.has("frontier_art"):
			draw_texture_rect(preload("res://scripts/atlas_icons.gd").frontier(landmark.frontier_art),Rect2(at-Vector2.ONE*size_value*0.5,Vector2.ONE*size_value),false,Color(0.75,0.82,0.8))
		else: prop(landmark.get("art",6),at,size_value,Color(0.75,0.82,0.8))
		if landmark.p.distance_to(sim.pos)<500: draw_string(font,at+Vector2(-110,size_value*0.4),landmark.name,HORIZONTAL_ALIGNMENT_CENTER,220,14,Color("99aaa5"))
		if sim.halloween:
			Seasonal.draw_prop(self,at+Vector2(95,35),0,55,sim.time)
			Seasonal.draw_prop(self,at+Vector2(-85,20),1,37,sim.time)
	for chest in sim.relic_chests: draw_cache(screen(chest))
	for item in sim.pickups:
		var d = sim.Pickups.DEFINITIONS[item.id]
		var p = screen(item.p)+Vector2(0,sin(clock*3)*4)
		if not visible_rect().grow(100).has_point(p): continue
		glow(p,65,Color(d.color))
		if item.id=="amber": draw_texture_rect(preload("res://scripts/atlas_icons.gd").get_icon("lens","relic"),Rect2(p-Vector2(29,29),Vector2(58,58)),false)
		else: pickup_icon(d.icon,p,58)
		if p.distance_to(screen(sim.pos))<150: draw_string(font,p+Vector2(-55,43),d.name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(d.color))
	if sim.mode != "safari" and sim.boss_stage<3:
		if sim.cache_timer<=0: draw_cache(screen(sim.cache_pos))
		if not sim.shrine_done:
			var p = screen(sim.shrine_pos)
			draw_circle(p,105,Color(0.4,0.3,0.7,0.09))
			draw_arc(p,105,0,TAU,64,Color("917dc1"),2,true)
			draw_arc(p,108,-PI/2,-PI/2+TAU*sim.shrine_progress/sim.RIFT_CHARGE_SECONDS,64,Color("f5d3ff"),5,true)
			glow(p,90,Color("c192ff"))
			prop(1,p,155)
			draw_string(font,p+Vector2(-68,42),"HOLD THE RIFT",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("dbcded"))
	for g in sim.gems:
		var p = screen(g.p)
		if not visible_rect().grow(30).has_point(p): continue
		prop(3,p,17 if g.value<10 else 28)
	for e in sim.enemies:
		if e.dead or e.get("boss_prop",false): continue
		if e.get("breakable",false):
			var at=screen(e.p)
			if visible_rect().grow(80).has_point(at):
				draw_texture_rect(preload("res://scripts/atlas_icons.gd").field(e.prop_art+1),Rect2(at-Vector2(30,47),Vector2(60,60)),false,Color(1.7,1.7,1.7) if e.flash>0 else Color.WHITE)
			continue
		if e.boss and sim.boss_stage<3:continue
		if not e.boss and not e.elite and not e.anchor: continue
		var p = screen(e.p)
		if not visible_rect().grow(220).has_point(p): continue
		if e.boss and sim.boss_stage==3:
			draw_meteor(e,p)
			continue
		if e.anchor:
			glow(p,65,Color("f48cff"))
			draw_arc(p,43,clock,clock+TAU,24,Color("c487fa"),2,true)
			prop(2,p,115)
		else:
			var size = e.size*3.0
			draw_set_transform(p,0,Vector2(1,0.36))
			draw_circle(Vector2.ZERO,e.size,Color(0,0,0,0.28))
			draw_set_transform(Vector2.ZERO)
			var tint = Color(1.8,1.8,1.8) if e.flash>0 else Color("a2c3ff") if e.slow>0 or e.get("frozen",0)>0 or sim.buffs.get("freeze",0)>0 else Color("eabcff") if e.mutated else Color.WHITE
			if e.kind>=5:
				var region = frontier_regions[e.kind-14] if e.kind>=14 else monster_regions[e.kind-5]
				var sheet=frontier_sheet if e.kind>=14 else monster_sheet
				if sim.halloween:
					var group=2 if e.kind>=14 else 1
					sheet=Seasonal.texture_for(group)
					region=Seasonal.regions_for(group)[e.kind-14 if e.kind>=14 else e.kind-5]
				var dimensions = region.size/maxf(region.size.x,region.size.y)*size
				draw_set_transform(p,0,Vector2(-1 if e.p.x>sim.pos.x else 1,1))
				draw_texture_rect_region(sheet,Rect2(Vector2(-dimensions.x/2,-dimensions.y*0.75),dimensions),region,tint)
				draw_set_transform(Vector2.ZERO)
			else: sprite(3+e.kind,p+Vector2(0,0 if sim.rooted(e) else sin(clock*9+e.uid)*2),size,e.p.x>sim.pos.x,tint,0 if sim.rooted(e) else sin(clock*7+e.uid)*0.035)
			if e.elite: draw_arc(p,e.size+8,0,TAU,32,Color("fca25c"),2,true)
		if e.elite or e.anchor:
			draw_rect(Rect2(p+Vector2(-26,-e.size*2),Vector2(52,4)),Color("352f43"))
			draw_rect(Rect2(p+Vector2(-26,-e.size*2),Vector2(52*e.hp/e.max_hp,4)),Color("ef917a"))
	var player = screen(sim.pos)
	glow(player,65,Color(C.HEROES[sim.hero].color))
	draw_set_transform(player,0,Vector2(1,0.35))
	draw_circle(Vector2.ZERO,23,Color(0,0,0,0.6))
	draw_set_transform(Vector2.ZERO)
	draw_arc(player+Vector2(0,2),25,0,TAU,40,Color(0.75,0.9,1,0.75),1.5,true)
	for p in particles: draw_circle(screen(p.p),p.size,Color(p.color,minf(1,p.life*3)))

func prop(index,p,size_value,tint = Color.WHITE):
	var cell_size = Vector2(props.get_size())/3.0
	var source = Rect2(Vector2(index%3,floori(index/3.0))*cell_size+Vector2.ONE*4,cell_size-Vector2.ONE*8)
	draw_texture_rect_region(props,Rect2(p-Vector2(size_value/2,size_value*0.75),Vector2.ONE*size_value),source,tint)

func draw_cache(p):
	glow(p,90,Color("ffd491"))
	pickup_icon(7,p+Vector2(0,sin(clock*2)*2),100)
	draw_string(font,p+Vector2(-35,38),"RELIC CACHE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ffe6b2"))

func pickup_icon(index,p,size_value):
	var cell_size = Vector2(pickup_sheet.get_size())/3.0
	var source = Rect2(Vector2(index%3,floori(index/3.0))*cell_size,cell_size)
	draw_texture_rect_region(pickup_sheet,Rect2(p-Vector2.ONE*size_value/2,Vector2.ONE*size_value),source)

func draw_meteor(e,p):
	var arriving = clampf(sim.boss_time/3,0,1)
	p.y -= (1-arriving)*450
	var scale_value = 1+(sim.phase-1)*0.12
	glow(p,250,Color("ff784d"))
	sprite(8,p,310*scale_value,false,Color(1.35,1.1,1.0) if e.flash>0 else Color.WHITE,sin(clock*0.5)*0.08)
	if not sim.anchors.is_empty():
		draw_arc(p,150,-clock*0.3,TAU-clock*0.3,80,Color(0.65,0.52,1,0.4),3,true)
		for a in sim.anchors: draw_line(p,screen(a.p),Color(0.66,0.45,1,0.22),3,true)
	else:
		glow(p+Vector2(14,-10),90,Color("ffe28c"))
		draw_arc(p,140,0,TAU*maxf(0,sim.core_time)/12,64,Color("ffe19a"),4,true)

func draw_hazard(h,target = null):
	if target==null: target = self
	var p = screen(h.p)
	var friendly = h.kind == "friendly"
	var c = Color("8bcfe1") if friendly else Color("a8e567") if h.kind=="venom" else Color("ff766d")
	var progress = clampf(1-h.wait/maxf(0.01,h.warning),0,1)
	var alpha = 0.12 if h.wait>0 else 0.22
	if h.kind=="line":
		var dir = Vector2.from_angle(h.angle)
		var side = dir.orthogonal()*h.radius
		var end = p+dir*1000
		var points = PackedVector2Array([p+side,end+side,end-side,p-side])
		target.draw_colored_polygon(points,Color(c,alpha))
		target.draw_polyline(PackedVector2Array([p+side,end+side,end-side,p-side,p+side]),Color(c,0.7),2,true)
		for i in range(1,9):
			var mark = p+dir*i*105
			target.draw_polyline(PackedVector2Array([mark-dir*10+side*0.3,mark,mark-dir*10-side*0.3]),Color(c,0.65),2,true)
	elif h.kind=="ring":
		target.draw_arc(p,h.radius,0,TAU,80,Color(c,alpha),40,true)
		target.draw_arc(p,h.radius-20,0,TAU,80,c,1.5,true)
		target.draw_arc(p,h.radius+20,0,TAU,80,c,1.5,true)
	else:
		target.draw_circle(p,h.radius,Color(c,alpha))
		target.draw_arc(p,h.radius,-PI/2,-PI/2+TAU*progress,48,c,3,true)
		target.draw_line(p-Vector2(8,0),p+Vector2(8,0),c,2)
		target.draw_line(p-Vector2(0,8),p+Vector2(0,8),c,2)


