extends Node2D

var world
const Hostile = preload("res://scripts/hostile_fx.gd")
const Icons = preload("res://scripts/atlas_icons.gd")
var survivor = preload("res://scripts/survivor_animation.gd").new()

func _process(_dt):
	if world.sim != null: survivor.update(world.sim)
	queue_redraw()

func _draw():
	var s = world.sim
	if s==null: return
	# Boss silhouette and hostile casts stay above every friendly spell layer.
	if s.boss!=null and s.boss_stage==3:
		world.sprite(8,world.screen(s.boss.p),310*(1+(s.phase-1)*0.12),false,Color.WHITE,sin(world.clock*0.5)*0.08,self)
	elif s.boss!=null:
		var e=s.boss
		var p=world.screen(e.p)
		var tint=Color(1.6,1.6,1.6) if e.flash>0 else Color.WHITE
		if e.kind>=5:
			var region=world.frontier_regions[e.kind-14] if e.kind>=14 else world.monster_regions[e.kind-5]
			var dims=region.size/maxf(region.size.x,region.size.y)*e.size*3
			draw_set_transform(p,0,Vector2(-1 if e.p.x>s.pos.x else 1,1))
			draw_texture_rect_region(world.frontier_sheet if e.kind>=14 else world.monster_sheet,Rect2(Vector2(-dims.x/2,-dims.y*0.75),dims),region,tint)
			draw_set_transform(Vector2.ZERO)
		else: world.sprite(3+e.kind,p,e.size*3,e.p.x>s.pos.x,tint,0,self)
	for h in s.hazards:
		if h.kind=="friendly": continue
		Hostile.hazard(self,h,world.screen(h.p),world.clock)
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
		var p = world.screen(shot.p)
		var dir = shot.v.normalized()
		Hostile.piece(self,3,p-dir*13,Vector2(65,42),dir.angle()+PI)
	if s.transition_time>0:
		var fade = s.transition_time/1.25
		draw_rect(world.visible_rect(),Color(0.04,0.08,0.16,fade))
	var player = world.screen(s.pos)
	draw_arc(player+Vector2(0,2),25,0,TAU,40,Color(0.85,0.96,1,0.85),2,true)
	survivor.draw(self,s,player,Color(1,1,1,0.75 if s.invul>0 and sin(s.time*40)>0 else 1))
	for n in world.numbers:
		draw_string(world.font,world.screen(n.p),n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(n.color,n.life/0.65))
	if s.boss!=null and s.boss_stage==3: draw_arc(world.screen(s.boss.p),720,0,TAU,100,Color(1,0.3,0.2,0.5),5,true)


