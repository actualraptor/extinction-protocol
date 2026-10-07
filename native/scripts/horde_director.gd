extends RefCounted
const EVENTS = [
	{"at":45.0,"duration":1.4,"name":"THE STAMPEDE","rate":170.0,"cap":1000,"health":1.0,"elite":false,"formation":"flow","kinds":[4]},
	{"at":240.0,"duration":10.0,"name":"SKYBREAKER FLIGHT","rate":14.0,"cap":1000,"health":0.8,"elite":false,"formation":"flank","kinds":[2,9]},
	{"at":420.0,"duration":40.0,"name":"THE WORLD IS HUNGRY","rate":125.0,"cap":2200,"health":0.32,"elite":false,"formation":"ring"},
	{"at":540.0,"duration":14.0,"name":"ARMORED PROCESSION","rate":12.0,"cap":1500,"health":0.85,"elite":false,"formation":"lane","roles":["armor"]},
	{"at":720.0,"duration":32.0,"name":"APEX INVASION","rate":58.0,"cap":1700,"health":0.7,"elite":true,"formation":"ring"},
	{"at":840.0,"duration":10.0,"name":"THE RIFT HUNT","rate":22.0,"cap":1700,"health":1.0,"elite":false,"formation":"flank","roles":["chase","phase","spit"]},
	{"at":660.0,"duration":1.4,"name":"THE STAMPEDE","rate":250.0,"cap":1700,"health":1.0,"elite":false,"formation":"flow","kinds":[4]}]
var warned = {}
var started = {}
var current = {}
var budget = 0.0
var respite_shift = 0.0
var flow_origin=Vector2.ZERO
var flow_direction=Vector2.RIGHT

func update(g,dt):
	var event_time=g.time-respite_shift
	current = {}
	for i in range(EVENTS.size()):
		var e = EVENTS[i]
		if event_time>=e.at+e.duration: continue
		if event_time>=e.at-(2 if e.formation=="flow" else 5) and not warned.has(i):
			warned[i] = true
			g.banner.emit("STAMPEDE INCOMING" if e.formation=="flow" else "HORDE INCOMING","CLEAR THE PATH OR GET OUT OF THE WAY" if e.formation=="flow" else e.name+" / FIND AN ESCAPE ROUTE")
			g.sound.emit("boss")
		if event_time>=e.at:
			current = e
			if not started.has(i):
				started[i] = true
				if e.formation=="flow":
					flow_origin=g.pos
					flow_direction=Vector2.RIGHT.rotated(g.rng.randi_range(0,3)*PI/2)
				g.log_event("horde-start",{"name":e.name,"cap":e.cap})
				g.banner.emit(e.name,"DENSITY SURGE / HARVEST THE HORDE")
	if current.is_empty(): return
	budget = minf(12,budget+dt*current.rate)
	while budget>=1:
		budget -= 1
		if g.enemies.size()>=current.cap: continue
		var elite = current.elite and g.rng.randf()<0.045
		var pool=g.Maps.pool(g.map_id,g.depth,g.time)
		if current.has("roles"):
			var matching=pool.filter(func(k):return g.Bestiary.DATA[k].role in current.roles)
			if not matching.is_empty():pool=matching
		var kind = pool[g.rng.randi_range(0,pool.size()-1)]
		if current.has("kinds"): kind = current.kinds[g.rng.randi_range(0,current.kinds.size()-1)]
		if current.name=="SKYBREAKER FLIGHT":
			var flyers=pool.filter(func(k):return g.Bestiary.DATA[k].role=="fly")
			kind=flyers[g.rng.randi_range(0,flyers.size()-1)] if not flyers.is_empty() else pool[0]
		var position = null
		var formation = current.get("formation","ring")
		if formation=="flow":
			var extent=absf(flow_direction.x)*g.spawn_view.x*.5+absf(flow_direction.y)*g.spawn_view.y*.5+180
			var wave=sin((event_time-current.at)*2.2)*24
			var lane=clampf(g.rng.randfn(0,44),-105,105)
			position=flow_origin-flow_direction*(extent+g.rng.randf_range(0,60))+flow_direction.orthogonal()*(wave+lane)
		elif formation!="ring":
			var heading = Vector2.from_angle(float(int(current.at)%4)*PI/2)
			position = g.pos+heading*850+heading.orthogonal()*g.rng.randf_range(-450,450)
			if formation=="flank" and g.rng.randf()<0.5: position = g.pos*2-position
		var e = g.spawn_enemy(elite,position,kind,false)
		e.hp *= current.health
		e.max_hp = e.hp
		e.event_spawn = true
		e.speed *= 1.12
		if formation=="flow":
			e.speed*=g.rng.randf_range(.98,1.02)
			preload("res://scripts/compy_stampede.gd").configure(g,e,flow_direction)

func cap(g): return int(current.get("cap",mini(1500,500+int(g.time))))
