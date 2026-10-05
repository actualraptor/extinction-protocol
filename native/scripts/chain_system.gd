extends RefCounted
## Bounded work queue shared by weapons and proc effects. Each target is visited
## once, or at most twice when rechain triggers. No recursive chain spawning.
static func cast(g,origin,power,id,count,radius,falloff = 0.85,fork = 0.0,rechain = 0.0,initial_range_origin = Vector2.INF):
	var queue = [{"p":origin,"damage":power,"first":true}]
	var visits = {}
	var hits = 0
	var budget = mini(40,count+int(count*fork))
	while not queue.is_empty() and hits<budget:
		var source = queue.pop_front()
		var target = null
		var distance = 680.0 if source.first else radius
		var search_origin=initial_range_origin if source.first and initial_range_origin!=Vector2.INF else source.p
		var repeat_allowed = g.rng.randf()<rechain
		for e in g.nearby(search_origin,distance):
			var n = visits.get(e.uid,0)
			if n>=2 or (n>0 and not repeat_allowed) or e.p.distance_squared_to(source.p)<1: continue
			var d = search_origin.distance_to(e.p)
			if d<distance:
				distance = d
				target = e
		if target==null: continue
		visits[target.uid] = visits.get(target.uid,0)+1
		if g.strikes.size()<180: g.strikes.append({"a":source.p,"b":target.p,"life":0.24,"wait":minf(0.3,hits*0.028),"chain":true,"ice":id=="whiteout","color":Color("c9b3ff")})
		g.hit(target,source.damage,id)
		hits += 1
		if hits<count: queue.append({"p":target.p,"damage":source.damage*falloff,"first":false})
		if g.rng.randf()<fork: queue.append({"p":target.p,"damage":source.damage*falloff*0.8,"first":false})
	return hits
