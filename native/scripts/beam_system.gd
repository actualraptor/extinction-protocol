extends RefCounted
const Prototype=preload("res://scripts/beam_prototype.gd")
static var next_visual=0
static var glow_texture
const FLAME_SPEED=360.0
const FLAME_SPIN=3.0   # radians per second; the torch turns around Kael constantly, firing or not
static func flame_angle(g):return float(g.get_meta("flame_spin",0.0))
const Bodies=preload("res://scripts/army_collision.gd")
static func living_target(e):return e.hp>0 and not e.get("dead",false)
static func damage_segments(path:PackedVector2Array)->PackedVector4Array:
	var segments=PackedVector4Array()
	for j in range(1,path.size()):
		var delta:Vector2=path[j]-path[j-1]
		if not segments.is_empty():
			var previous:Vector4=segments[-1]
			var start:Vector2=Vector2(previous.x,previous.y)
			var previous_delta:Vector2=Vector2(previous.z,previous.w)-start
			var extended:Vector2=path[j]-start
			# Remove only collinear, forward points. The full curved path still
			# drives rendering; bends retain their individual capsule segments.
			if previous_delta.length_squared()>.000001 and previous_delta.dot(delta)>=0 and absf(previous_delta.cross(extended))<=.0001*previous_delta.length():
				segments[-1]=Vector4(start.x,start.y,path[j].x,path[j].y)
				continue
		segments.append(Vector4(path[j-1].x,path[j-1].y,path[j].x,path[j].y))
	return segments
static func touches_segments(segments:PackedVector4Array,point:Vector2,radius:float)->bool:
	var radius_sq:float=radius*radius
	for segment:Vector4 in segments:
		var closest:Vector2=Geometry2D.get_closest_point_to_segment(point,Vector2(segment.x,segment.y),Vector2(segment.z,segment.w))
		if point.distance_squared_to(closest)<=radius_sq:return true
	return false
static func flame_path(b,sample_age=-1.0):
	var points=PackedVector2Array()
	if sample_age<0:sample_age=b.age
	var length=minf(b.stats.range,sample_age*FLAME_SPEED)
	# Points move backwards through the same chronological history. Keep one
	# cursor instead of scanning it from the beginning for every point.
	var history_index:int=b.history.size()-1
	for i in range(25):
		var distance=length*i/24.0
		var time=maxf(0,sample_age-distance/FLAME_SPEED)
		while history_index>0 and b.history[history_index].t>time:history_index-=1
		var sample=b.history[history_index]
		var origin:Vector2=sample.p
		var aim:Vector2=sample.aim
		if history_index+1<b.history.size():
			var next=b.history[history_index+1]
			var weight:float=clampf((time-sample.t)/maxf(.000001,next.t-sample.t),0,1)
			origin=origin.lerp(next.p,weight);aim=aim.slerp(next.aim,weight)
		points.append(origin+aim*distance)
	# Moving drags the old origins, which squishes or stretches the trail; rescale the curve so its arc length is always `length`.
	var arc=0.0
	for i in range(1,points.size()):arc+=points[i].distance_to(points[i-1])
	if arc>.001 and length>.001:
		var scale=length/arc;var previous=points[0];var original=points.duplicate()
		for i in range(1,points.size()):
			var step=(original[i]-original[i-1])*scale
			previous+=step;points[i]=previous
	return points
static func glow():
	if glow_texture==null:
		var gradient=Gradient.new();gradient.colors=PackedColorArray([Color(1,1,1,.7),Color(1,1,1,0)])
		glow_texture=GradientTexture2D.new();glow_texture.gradient=gradient;glow_texture.width=64;glow_texture.height=64;glow_texture.fill=GradientTexture2D.FILL_RADIAL;glow_texture.fill_from=Vector2(.5,.5);glow_texture.fill_to=Vector2(1,.5)
	return glow_texture
static func cast(g,id,s):
	var targets=g.nearby(g.pos,s.range).filter(func(e):return living_target(e))
	if targets.is_empty():return false
	targets.sort_custom(func(a,b):return a.p.distance_squared_to(g.pos)<b.p.distance_squared_to(g.pos))
	var spinning=g.C.WEAPONS[id].get("beam_base",id)=="flametorch"
	# Flame beams ignore targeting: they leave at the torch's current heading, spread evenly around the circle.
	for i in range(s.count if spinning else mini(s.count,targets.size())):
		var target=targets[mini(i,targets.size()-1)]
		next_visual+=1
		var offset=i*TAU/maxf(1.0,float(s.count))
		var aim=Vector2.from_angle(flame_angle(g)+offset) if spinning else (target.p-g.pos).normalized()
		if aim.length_squared()<.0001:aim=Vector2(-1 if g.facing<0 else 1,0)
		g.beams.append({"visual_id":next_visual,"union_pulse":0,"id":id,"target":target,"aim":aim,"spin_offset":offset,"age":0.0,"life":s.duration,"tick":0.0,"stats":s.duplicate(),"seed":i*1.7,"history":[{"t":0.0,"p":g.pos,"aim":aim}],"last_origin":g.pos})
	return true
static func update(g,dt):
	var damage_candidates={}
	g.set_meta("flame_spin",fposmod(flame_angle(g)+FLAME_SPIN*dt,TAU))
	for b in g.beams:
		var elapsed=minf(dt,b.life-b.age)
		if elapsed<=0:continue
		var s=b.stats
		var flame=g.C.WEAPONS[b.id].get("beam_base",b.id)=="flametorch"
		if flame:b.aim=Vector2.from_angle(flame_angle(g)+b.get("spin_offset",0.0))
		elif not living_target(b.target) or b.target.p.distance_squared_to(g.pos)>s.range*s.range:
			var targets=g.nearby(g.pos,s.range).filter(func(e):return living_target(e))
			# Split beams spread over distinct living targets rather than stacking
			# all connections onto the closest survivor after their targets die.
			targets=targets.filter(func(e):return not g.beams.any(func(other):return other.visual_id!=b.visual_id and other.id==b.id and other.age<other.life and other.target.uid==e.uid))
			if not targets.is_empty():
				targets.sort_custom(func(a,c):return a.p.distance_squared_to(g.pos)<c.p.distance_squared_to(g.pos))
				b.target=targets[0]
			elif not flame:
				b.age=b.life
				continue
		if not flame and living_target(b.target):
			var desired=(b.target.p-g.pos).normalized()
			if desired.length_squared()>.0001:
				b.aim=desired if g.C.WEAPONS[b.id].get("beam_base",b.id)=="plasma_tether" else b.aim.slerp(desired,1-exp(-4*elapsed)).normalized()
		var old_age=b.age
		b.age+=elapsed;b.tick+=elapsed
		if flame:
			var next_time=b.history[-1].t+.025
			while next_time<=b.age+.000001:
				b.history.append({"t":next_time,"p":b.last_origin.lerp(g.pos,clampf((next_time-old_age)/elapsed,0,1)),"aim":b.aim})
				next_time+=.025
			while b.history.size()>2 and b.history[1].t<b.age-s.range/FLAME_SPEED-.05:b.history.pop_front()
			b.last_origin=g.pos
			b.path=flame_path(b)
			var shift:Vector2=g.pos-b.path[0]  # shift the whole trail so it stays anchored without changing its length
			for k in range(b.path.size()):b.path[k]+=shift
		var length=minf(s.range,b.target.p.distance_to(g.pos)) if g.C.WEAPONS[b.id].get("beam_base",b.id)=="plasma_tether" else s.range
		while b.tick>=.1-0.000001:
			b.tick-=.1
			var hit_aim=b.aim
			var path=flame_path(b,b.age-b.tick) if flame else PackedVector2Array([g.pos,g.pos+hit_aim*length])
			var segments=damage_segments(path)
			var bounds=Rect2(path[0],Vector2.ZERO)
			for point in path:bounds=bounds.expand(point)
			bounds=bounds.grow(s.width*.5+100.0)
			var query_radius=s.range+100.0
			for p in path:query_radius=maxf(query_radius,g.pos.distance_to(p)+s.width+100)
			var query_key=ceili(query_radius)
			if not damage_candidates.has(query_key):damage_candidates[query_key]=g.nearby(g.pos,float(query_key))
			for e in damage_candidates[query_key]:
				if living_target(e) and bounds.has_point(e.p) and touches_segments(segments,e.p,s.width*.5+Bodies.enemy_radius(e)):
					g.hit(e,s.power*.1,b.id,true,true,"field")
					if b.id=="event_lock" and not e.boss and not e.anchor:e.slow=maxf(e.slow,.7)
		if b.id=="event_lock" and g.active:preload("res://scripts/union_system.gd").beam_pulse(g,b)
	g.beams=g.beams.filter(func(b):return b.age<b.life-.000001)
static func draw(w,g):
	for b in g.beams:
		var s=b.stats;var t=b.age;var flame=g.C.WEAPONS[b.id].get("beam_base",b.id)=="flametorch"
		var origin=w.screen(g.pos)+Vector2(0,-30)
		var envelope=minf(1,t/.1)*minf(1,(b.life-t)/.15)
		if envelope<.01:continue
		var end=origin+b.aim*(minf(s.range,b.target.p.distance_to(g.pos)) if g.C.WEAPONS[b.id].get("beam_base",b.id)=="plasma_tether" else s.range)
		if not flame and living_target(b.target):
			var hit=origin+(b.target.p-g.pos).limit_length(s.range)
			var r=15+sin(t*24+b.seed)*3
			w.draw_texture_rect(glow(),Rect2(hit-Vector2.ONE*r*1.8,Vector2.ONE*r*3.6),false,Color(.15,1,.76,.65*envelope))
			for j in range(7):
				var angle=t*5+j*TAU/7
				var p=hit+Vector2.from_angle(angle)*r*fposmod(t*3+j*.17,1)
				w.draw_line(hit,p,Color(.7,1,.9,.8*envelope),1.2)
		for i in range(12 if flame else 6):
			var u=fposmod(t*1.4+i*.083+b.seed,1)
			var p=origin+b.aim*(u*s.range)+b.aim.orthogonal()*sin(i*3.1+t*6)*s.width*u*.6
			if flame and b.has("path"):
				var index=minf(u*24,23.999)
				p=w.screen(b.path[int(index)].lerp(b.path[int(index)+1],fposmod(index,1)))+Vector2(0,-30)
			if not flame and g.C.WEAPONS[b.id].get("beam_base",b.id)=="plasma_tether":p=origin.lerp(end,u)+b.aim.orthogonal()*sin(i*3.1+t*6)*s.width*.2
			w.draw_circle(p,1.1+u,Color(.65,.83,.2,(1-u)*envelope) if b.id=="plague_furnace" else Color(1,.65,.15,(1-u)*envelope) if flame else Color(.6,1,.85,(1-u)*envelope))
