extends RefCounted
const EVENTS = [
	{"at":150.0,"duration":24.0,"name":"THE STAMPEDE","rate":38.0,"cap":1000,"health":0.55,"elite":false,"formation":"lane"},
	{"at":240.0,"duration":10.0,"name":"SKYBREAKER FLIGHT","rate":14.0,"cap":1000,"health":0.8,"elite":false,"formation":"flank","kinds":[2,9]},
	{"at":420.0,"duration":40.0,"name":"THE WORLD IS HUNGRY","rate":125.0,"cap":2200,"health":0.32,"elite":false,"formation":"ring"},
	{"at":540.0,"duration":14.0,"name":"IRONBACK PROCESSION","rate":12.0,"cap":1500,"health":0.85,"elite":false,"formation":"lane","kinds":[6,10]},
	{"at":720.0,"duration":32.0,"name":"APEX INVASION","rate":58.0,"cap":1700,"health":0.7,"elite":true,"formation":"ring"},
	{"at":840.0,"duration":10.0,"name":"THE RIFT HUNT","rate":22.0,"cap":1700,"health":1.0,"elite":false,"formation":"flank","kinds":[12,13]}]
var warned = {}
var started = {}
var current = {}
var budget = 0.0

func update(g,dt):
	current = {}
	for i in range(EVENTS.size()):
		var e = EVENTS[i]
		if g.time>=e.at+e.duration: continue
		if g.time>=e.at-5 and not warned.has(i):
			warned[i] = true
			g.banner.emit("HORDE INCOMING",e.name+" / FIND AN ESCAPE ROUTE")
			g.sound.emit("boss")
		if g.time>=e.at:
			current = e
			if not started.has(i):
				started[i] = true
				g.log_event("horde-start",{"name":e.name,"cap":e.cap})
				g.banner.emit(e.name,"DENSITY SURGE / HARVEST THE HORDE")
	if current.is_empty(): return
	budget = minf(12,budget+dt*current.rate)
	while budget>=1:
		budget -= 1
		if g.enemies.size()>=current.cap: continue
		var elite = current.elite and g.rng.randf()<0.045
		var kind = [0,0,4,4,2][g.rng.randi_range(0,4)] if not elite else -1
		if current.has("kinds"): kind = current.kinds[g.rng.randi_range(0,current.kinds.size()-1)]
		if g.map_id!="cradle":
			var pool=g.Maps.pool(g.map_id,g.depth,g.time)
			kind=pool[g.rng.randi_range(0,pool.size()-1)]
		var position = null
		var formation = current.get("formation","ring")
		if formation!="ring":
			var heading = Vector2.from_angle(float(int(current.at)%4)*PI/2)
			position = g.pos+heading*850+heading.orthogonal()*g.rng.randf_range(-450,450)
			if formation=="flank" and g.rng.randf()<0.5: position = g.pos*2-position
		var e = g.spawn_enemy(elite,position,kind,false)
		e.hp *= current.health
		e.max_hp = e.hp
		e.event_spawn = true
		e.speed *= 1.12

func cap(g): return int(current.get("cap",mini(1500,500+int(g.time))))
