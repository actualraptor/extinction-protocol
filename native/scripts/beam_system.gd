extends RefCounted
const Prototype=preload("res://scripts/beam_prototype.gd")
static var next_visual=0
static var glow_texture
const FLAME_SPEED=360.0
static func flame_path(b,sample_age=-1.0):
	var points=PackedVector2Array()
	if sample_age<0:sample_age=b.age
	var length=minf(b.stats.range,sample_age*FLAME_SPEED)
	for i in range(25):
		var distance=length*i/24.0
		var time=maxf(0,sample_age-distance/FLAME_SPEED)
		var sample=b.history[0]
		for h in b.history:
			if h.t>time:
				var weight=clampf((time-sample.t)/maxf(.000001,h.t-sample.t),0,1)
				sample={"p":sample.p.lerp(h.p,weight),"aim":sample.aim.slerp(h.aim,weight)}
				break
			sample=h
		points.append(sample.p+sample.aim*distance)
	return points
static func glow():
	if glow_texture==null:
		var gradient=Gradient.new();gradient.colors=PackedColorArray([Color(1,1,1,.7),Color(1,1,1,0)])
		glow_texture=GradientTexture2D.new();glow_texture.gradient=gradient;glow_texture.width=64;glow_texture.height=64;glow_texture.fill=GradientTexture2D.FILL_RADIAL;glow_texture.fill_from=Vector2(.5,.5);glow_texture.fill_to=Vector2(1,.5)
	return glow_texture
static func cast(g,id,s):
	var targets=g.nearby(g.pos,s.range).filter(func(e):return e.hp>0)
	if targets.is_empty():return false
	targets.sort_custom(func(a,b):return a.p.distance_squared_to(g.pos)<b.p.distance_squared_to(g.pos))
	for i in range(s.count):
		var target=targets[i%targets.size()]
		next_visual+=1
		var aim=(target.p-g.pos).normalized()
		g.beams.append({"visual_id":next_visual,"id":id,"target":target,"aim":aim,"age":0.0,"life":s.duration,"tick":0.0,"stats":s.duplicate(),"seed":i*1.7,"history":[{"t":0.0,"p":g.pos,"aim":aim}],"last_origin":g.pos})
	return true
static func update(g,dt):
	for b in g.beams:
		var elapsed=minf(dt,b.life-b.age)
		if elapsed<=0:continue
		var s=b.stats
		var flame=b.id=="flametorch"
		if b.target.hp<=0 or b.target.p.distance_to(g.pos)>s.range:
			var targets=g.nearby(g.pos,s.range).filter(func(e):return e.hp>0)
			if not targets.is_empty():
				targets.sort_custom(func(a,c):return a.p.distance_squared_to(g.pos)<c.p.distance_squared_to(g.pos))
				b.target=targets[0]
		if b.target.hp>0:
			var desired=(b.target.p-g.pos).normalized()
			b.aim=desired if b.id=="plasma_tether" else b.aim.slerp(desired,1-exp(-4*elapsed)).normalized()
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
			b.path[0]=g.pos
		var length=minf(s.range,b.target.p.distance_to(g.pos)) if b.id=="plasma_tether" else s.range
		while b.tick>=.1-0.000001:
			b.tick-=.1
			var hit_aim=b.aim
			var path=flame_path(b,b.age-b.tick) if flame else PackedVector2Array([g.pos,g.pos+hit_aim*length])
			var query_radius=s.range+100.0
			for p in path:query_radius=maxf(query_radius,g.pos.distance_to(p)+s.width+100)
			for e in g.nearby(g.pos,query_radius):
				var touches=false
				for j in range(1,path.size()):
					if Prototype.intersects(path[j-1],path[j]-path[j-1],path[j].distance_to(path[j-1]),s.width,e.p,preload("res://scripts/army_collision.gd").enemy_radius(e)):
						touches=true;break
				if e.hp>0 and touches:
					g.hit(e,s.power*.1,b.id,true,true,"field")
	g.beams=g.beams.filter(func(b):return b.age<b.life-.000001)
static func draw(w,g):
	for b in g.beams:
		var s=b.stats;var t=b.age;var flame=b.id=="flametorch"
		var origin=w.screen(g.pos)+Vector2(0,-30)
		var envelope=minf(1,t/.1)*minf(1,(b.life-t)/.15)
		if envelope<.01:continue
		var end=origin+b.aim*(minf(s.range,b.target.p.distance_to(g.pos)) if b.id=="plasma_tether" else s.range)
		if not flame and b.target.hp>0:
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
			if not flame and b.id=="plasma_tether":p=origin.lerp(end,u)+b.aim.orthogonal()*sin(i*3.1+t*6)*s.width*.2
			w.draw_circle(p,1.1+u,Color(1,.65,.15,(1-u)*envelope) if flame else Color(.6,1,.85,(1-u)*envelope))
