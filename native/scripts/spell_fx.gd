extends Node2D

var world
var impacts = false
var sheet
var grid_size
const Icons = preload("res://scripts/atlas_icons.gd")

func _ready():
	sheet = preload("res://assets/impact-fx.png") if impacts else preload("res://assets/weapon-fx.png")
	grid_size = Vector2(4,4) if impacts else Vector2(4,2)
	var shader = ShaderMaterial.new()
	shader.shader = preload("res://shaders/spell_glow.gdshader")
	shader.set_shader_parameter("atlas_grid",grid_size)
	shader.set_shader_parameter("intensity",0.48 if impacts else 0.75)
	material = shader

func _process(_dt): queue_redraw()

func piece(index,p,size_value,angle = 0.0,alpha = 1.0,tint = Color.WHITE):
	# A clear center preserves the player and nearby tells under dense builds.
	var center_distance = p.distance_to(world.screen(world.sim.pos)) if world.sim!=null else 999.0
	if center_distance<110: alpha *= lerpf(0.24,0.8,center_distance/110)
	if world.sim!=null and world.sim.boss!=null: alpha *= 0.7
	var cell_size = Vector2(sheet.get_size())/grid_size
	var source = Rect2(Vector2(index%4,floori(index/4.0))*cell_size,cell_size)
	draw_set_transform(p,angle)
	draw_texture_rect_region(sheet,Rect2(-size_value/2,size_value),source,Color(tint,alpha))
	draw_set_transform(Vector2.ZERO)

func burst(row,p,size_value,progress,alpha = 1.0,angle = 0.0):
	var frame = clampf(progress*3.7,0,3.0)
	var index = floori(frame)
	var blend = frame-index
	piece(row*4+index,p,size_value,angle,alpha*(1-blend))
	if blend>0 and index<3: piece(row*4+index+1,p,size_value,angle,alpha*blend)

func _draw():
	var s = world.sim
	if s==null: return
	if impacts:
		for zone in s.zones:
			if zone.wait>0: continue
			if zone.get("scorched",false):
				var ground = world.screen(zone.p)
				if not Rect2(-zone.radius,-zone.radius,1440+zone.radius*2,900+zone.radius*2).has_point(ground): continue
				var cooling = clampf(zone.life/0.45,0.0,1.0)
				var heat = 0.88+sin(world.clock*6+zone.p.x*0.01)*0.12
				# The authored ember/crater frame stays visible between damage ticks.
				# Its circular footprint shares the simulation's world-space radius.
				piece(3,ground,Vector2.ONE*zone.radius*2.2,zone.p.x*0.017,0.9*cooling*heat,Color("ffb77d"))
				for ember in range(4):
					var angle = ember*TAU/4+zone.p.y*0.01
					var phase = fmod(world.clock*0.65+ember*0.23,1.0)
					var location = ground+Vector2.from_angle(angle)*zone.radius*0.55
					burst(0,location,Vector2.ONE*zone.radius*0.52,phase,0.4*cooling,angle)
				continue
			if zone.id!="thunderstorm": continue
			var center = world.screen(zone.p)
			var fade = minf(1,zone.life*3)
			piece(13,center,Vector2.ONE*zone.radius*2.2,-world.clock*0.4,0.3*fade,Color("668eff"))
			for j in range(5):
				var angle = j*TAU/5+world.clock*0.6
				piece(10,center+Vector2.from_angle(angle)*zone.radius*0.68,Vector2.ONE*zone.radius*0.65,angle,0.28*fade,Color("acdfff"))
		if s.portal!=null:
			var gate = world.screen(s.portal)
			piece(13,gate,Vector2.ONE*(190+sin(world.clock*3)*8),world.clock*0.5,0.8,Color("73cfff"))
			piece(14,gate,Vector2.ONE*135,-world.clock*0.7,0.9,Color("ac8aff"))
			for i in range(6):
				var angle = world.clock+i*TAU/6
				piece(12,gate+Vector2.from_angle(angle)*75,Vector2.ONE*35,angle,0.65)
		for id in s.weapons:
			var d = s.C.WEAPONS[id]
			if d.delivery!="aura": continue
			var stats = s.Rules.stats(s,id)
			var radius = stats.radius
			var row = 1 if "ICE" in d.tags else 0 if "FIRE" in d.tags else 3
			var tint = Color(d.color)
			for j in range(8):
				var angle = world.clock*0.25+j*TAU/8
				var p = world.screen(s.pos)+Vector2.from_angle(angle)*radius*0.8
				var phase = fmod(world.clock*0.8+j*0.17,1)
				piece(row*4+mini(3,int(phase*4)),p,Vector2.ONE*radius*0.7,angle,0.3,tint)
		if s.shield>0:
			piece(13,world.screen(s.pos),Vector2.ONE*135,world.clock*0.3,0.5,Color("86dfff"))
		var effect_budget = 28 if s.boss!=null else 44
		for e in world.effects:
			if effect_budget<=0: break
			effect_budget -= 1
			var p = world.screen(e.p)
			var progress = 1-e.life/e.max
			var kind = e.kind
			var row = 0
			var size_value = clampf(e.size*1.5,45,360)
			var alpha = 0.6*minf(1.0,18.0/maxi(1,world.effects.size()))
			if kind in ["level","evolve","ring"]:
				row = 3
				size_value = 470 if kind=="level" else 650 if kind=="evolve" else 210
			elif kind=="victory": size_value = 700
			elif kind in ["blast_frost","impact_frost"]: row = 1
			elif kind in ["impact_lightning","blast_lightning","blast_thunderstorm"]: row = 2
			elif kind=="thermal":
				burst(1,p,Vector2.ONE*size_value*1.3,progress,alpha)
				row = 0
			elif kind.begins_with("impact_"):
				row = 0 if kind=="impact_fire" else 3
				size_value = 52
			elif kind=="blast_orbital":
				row = 3
				alpha = 0.28
			elif kind in ["muzzle","sparks","hurt","blast_club","blast_thorns","blast_thornking"]: continue
			elif kind=="crit":
				piece(8,p,Vector2.ONE*(22+minf(3,e.size)*3),0,0.7*(1-progress),Color("ffe49b"))
				continue
			elif not kind.begins_with("blast_") and kind!="impact": continue
			burst(row,p,Vector2.ONE*size_value,progress,alpha*(1-progress*0.45))
			if kind in ["impact_frost","blast_frost"]:
				for shard in range(5):
					var angle = shard*TAU/5+e.p.x
					piece(5,p+Vector2.from_angle(angle)*progress*size_value*0.45,Vector2.ONE*size_value*0.22,angle,alpha*(1-progress))
		# Enemies carry small authored frost and flame accents while afflicted.
		var accents = 0
		for e in s.enemies:
			if accents>=64: break
			if e.dead: continue
			if not world.visible_rect().grow(80).has_point(world.screen(e.p)): continue
			if s.rooted(e):
				accents += 1
				piece(5,world.screen(e.p)+Vector2(0,-e.size*0.3),Vector2.ONE*e.size*2.6,0,0.38,Color("b6f4ff"))
				piece(6,world.screen(e.p),Vector2(e.size*2.8,e.size*1.5),0,0.3)
			elif e.burn>0 and e.uid%3==0:
				accents += 1
				burst(0,world.screen(e.p)+Vector2(0,-15),Vector2(45,65),fmod(world.clock*1.5+e.uid*0.23,1),0.38)
			elif e.slow>0 and e.uid%2==0:
				accents += 1
				burst(1,world.screen(e.p),Vector2.ONE*e.size*2.7,0.5,0.28)
		return
	var alpha = clampf(22.0/maxi(1,s.shots.size()),0.24,0.8)
	for shot in s.shots:
		if shot.id in ["lantern","sunbow"]:
			var p=world.screen(shot.p)
			var tint=Color(s.C.WEAPONS[shot.id].color)
			for j in range(3): piece(1 if shot.id=="lantern" else 5,p-shot.v.normalized()*j*18,Vector2(52,32)*(1-j*0.2),shot.v.angle(),alpha*(1-j*0.25),tint)
			continue
		if shot.id in ["ricochet","return","harpoon","glacier"]:
			var at = world.screen(shot.p)
			draw_set_transform(at,world.clock*12 if shot.id in ["return","glacier"] else shot.v.angle())
			draw_texture_rect(Icons.get_icon(shot.id),Rect2(-23,-23,46,46),false,Color(1,1,1,alpha))
			draw_set_transform(Vector2.ZERO)
			continue
		var tags = s.C.WEAPONS[shot.id].tags
		var index = 0 if "FIRE" in tags else 1 if "ICE" in tags else 7 if "MELEE" in tags else 5
		var direction = shot.v.normalized()
		var evolved = s.weapons.get(shot.id,{}).get("evolved",false)
		var size_value = Vector2(80,54) if shot.id=="fire" else Vector2(88,48) if shot.id=="frost" else Vector2(58,22)
		if "AREA" in tags: size_value *= minf(1.25,s.area_scale())
		if evolved: size_value *= 1.1
		var p = world.screen(shot.p)-direction*size_value.x*0.22
		var angle = direction.angle()
		if shot.id in ["fire","frost"] and s.shots.size()<100:
			piece(index,p-direction*21,size_value*0.85,angle,alpha*0.25)
			piece(index,p-direction*40,size_value*0.65,angle,alpha*0.12)
		piece(index,p,size_value,angle,alpha)
		if shot.id=="frost" and s.shots.size()<100:
			for spark in range(4):
				var phase = fmod(world.clock*2.8+spark*0.25+shot.p.x*0.001,1)
				var glint = p-direction*phase*75+direction.orthogonal()*sin(phase*TAU+spark)*12
				piece(1,glint,Vector2(12,24)*(1-phase*0.6),world.clock*2+spark,alpha*(1-phase)*0.8,Color("ddffff"))
			piece(index,p+direction*8,size_value*Vector2(0.55,0.5),angle,alpha*0.8)
			for j in range(2):
				var tail = p-direction*(18+j*18)+direction.orthogonal()*sin(world.clock*22+j*PI)*7
				piece(1,tail,Vector2(22,14),angle+0.25*j,alpha*0.4)
		elif shot.id=="fire" and s.shots.size()<100:
			piece(0,p,size_value*(0.75+sin(world.clock*30)*0.05),angle,alpha*0.6)
	var strike_budget = 42
	for strike in s.strikes:
		if strike_budget<=0: break
		strike_budget -= 1
		if strike.get("wait",0)>0: continue
		var a = world.screen(strike.a)
		var b = world.screen(strike.b)
		var d = b-a
		if strike.get("kind","")=="spear":
			piece(7,(a+b)*0.5,Vector2(d.length()+30,70),d.angle(),minf(1,strike.life*6))
			continue
		var width = 32+sin(world.clock*65)*5
		piece(2,(a+b)*0.5,Vector2(d.length()+18,width),d.angle(),minf(1,strike.life*6))
		piece(2,(a+b)*0.5,Vector2(d.length(),width*0.55),d.angle()+0.015*sin(world.clock*80),strike.life*2)
		# Re-seeded jagged filaments make each jump snap rather than slide.
		var points = PackedVector2Array([a])
		var segments = clampi(int(d.length()/22),3,18)
		for j in range(1,segments):
			var offset = sin(j*17.13+floor(world.clock*35)*7.7+a.x)*13
			points.append(a+d*float(j)/segments+d.normalized().orthogonal()*offset)
		points.append(b)
		draw_polyline(points,Color(0.4,0.6,1,minf(0.3,strike.life*2)),4,true)
		draw_polyline(points,Color(0.9,0.98,1,minf(0.55,strike.life*4)),1.5,true)
		piece(2,b,Vector2(44,44),world.clock*5,minf(1,strike.life*6))
		if strike.get("ice",false):
			piece(1,b,Vector2(62,45),d.angle(),minf(1,strike.life*5),Color("d2ffff"))
	var blade_id = "bastion" if s.weapons.has("bastion") else "orbital"
	if s.weapons.has(blade_id):
		var stats = s.Rules.stats(s,blade_id)
		var count = stats.count
		for i in range(count):
			var angle = s.time*2.3+i*TAU/count
			var p = world.screen(s.pos)+Vector2.from_angle(angle)*stats.radius
			piece(3,p,Vector2.ONE*(70 if s.weapons[blade_id].evolved else 52),angle+PI/2)
			for j in range(1,3):
				var tail_angle = angle-j*0.12
				piece(3,world.screen(s.pos)+Vector2.from_angle(tail_angle)*stats.radius,Vector2.ONE*52,tail_angle+PI/2,0.16/j)
	for e in world.effects:
		var p = world.screen(e.p)
		var progress = 1-e.life/e.max
		if e.kind=="muzzle": piece(4,p+Vector2.from_angle(e.size)*13,Vector2(74,58),e.size,e.life/e.max)
		if e.kind in ["impact_revolver","impact_shotgun"]: piece(4,p,Vector2(45,45),e.p.x,1-progress)
		if e.kind in ["blast_thorns","blast_thornking"]:
			for j in range(10):
				var angle=j*TAU/10
				var at=p+Vector2.from_angle(angle)*e.size*progress
				draw_set_transform(at,angle+progress*2)
				draw_texture_rect(Icons.field(0),Rect2(-Vector2.ONE*26,Vector2.ONE*52),false,Color(1,1,1,(1-progress)*0.8))
				draw_set_transform(Vector2.ZERO)
		if e.kind=="blast_club":
			piece(7,p,Vector2.ONE*e.size*2,progress*TAU,1-progress)
			piece(7,p,Vector2.ONE*e.size*1.6,progress*TAU+PI,(1-progress)*0.55)
	for h in s.hazards:
		if h.has("launch") and h.wait>0:
			var t=clampf(1.0-h.wait/h.flight,0,1)
			var base=h.launch.lerp(h.p,t)
			var lift=4*t*(1-t)*minf(230,100+h.launch.distance_to(h.p)*0.25)
			var p=world.screen(base)+Vector2(0,-lift)
			var tangent=(h.p-h.launch)/h.flight+Vector2(0,-4*(1-2*t)*minf(230,100+h.launch.distance_to(h.p)*0.25)/h.flight)
			piece(6,p,Vector2(55,34),tangent.angle(),1.0)
			for j in range(1,4):
				var tail=maxf(0,t-j*0.025)
				var tp=world.screen(h.launch.lerp(h.p,tail))+Vector2(0,-4*tail*(1-tail)*minf(230,100+h.launch.distance_to(h.p)*0.25))
				piece(6,tp,Vector2(40,23),tangent.angle(),0.2/j)
			continue
		if h.wait>0 and h.wait<0.7 and h.kind in ["friendly","circle"]:
			var p = world.screen(h.p)+Vector2(-100,-400)*h.wait/0.7
			piece(6,p,Vector2(160,85),1.32,clampf((0.7-h.wait)*4,0,0.85))
	if s.boss!=null and s.boss_stage==3:
		var center = world.screen(s.boss.p)
		for i in range(7):
			var angle = world.clock*0.4+i*TAU/7
			piece(6,center+Vector2.from_angle(angle)*180,Vector2(75,40),angle+PI/2,0.6)
