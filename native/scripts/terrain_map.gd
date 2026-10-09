extends RefCounted
## Continuous seeded obstacle islands, authored regions and wide travel routes.
## Only nearby 64px cells are evaluated; one local flow field serves the horde.
const CELL = 64.0
const DIRS = [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
const FLOW_DIRS = [Vector2i(1,1),Vector2i(-1,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
var seed_value = 1
var layout = 0
var flow = {}
var cached = {}
var goal = Vector2i(99999,99999)
var arena = Vector2.INF
var arena_radius = 810.0
var refresh = 0.0
var clearance = {}
var sight = {}

func cell(p): return Vector2i(floori(p.x/CELL),floori(p.y/CELL))
func center(c): return Vector2(c)*CELL+Vector2.ONE*CELL*0.5
var stage = {}
var bounds = Rect2(-40000,-34000,80000,68000)
var depth = 0
var noise = FastNoiseLite.new()
var configured_seed = -2147483648

func configure(definition,biome_depth = 0):
	stage = definition
	bounds = stage.get("bounds",Rect2(-40000,-34000,80000,68000))
	depth = biome_depth
	noise.seed = seed_value
	noise.frequency = 0.0019
	noise.fractal_octaves = 2
	configured_seed = seed_value
	cached.clear(); clearance.clear(); flow.clear(); sight.clear()
	goal = Vector2i(99999,99999)
	refresh = 0.0

func region_at(p):
	var nearest = {}
	var best = INF
	for region in stage.get("regions",[]):
		var distance = p.distance_to(region.p)/region.radius
		if distance<1.35 and distance<best:
			nearest = region
			best = distance
	return nearest

func on_route(p):
	var start = stage.get("spawn",Vector2.ZERO)
	if p.distance_squared_to(start)<900*900: return true
	for target in stage.get("routes",[]):
		if Geometry2D.get_closest_point_to_segment(p,start,target).distance_squared_to(p)<230*230: return true
	for landmark in stage.get("landmarks",[]):
		if p.distance_squared_to(landmark.p)<320*320: return true
	return false

func kind(c):
	var p = center(c)
	if not bounds.has_point(p): return 1
	if arena!=Vector2.INF and p.distance_squared_to(arena)<arena_radius*arena_radius: return 0
	if configured_seed!=seed_value: configure(stage,depth)
	if cached.has(c): return cached[c]
	var result = 0
	if not on_route(p):
		# Smooth irregular islands never repeat at a district boundary.
		var n = noise.get_noise_2d(p.x,p.y)
		var region = region_at(p)
		var theme = region.get("kind","")
		var threshold = 0.49 if theme in ["ridge","ruins","grove","ice"] else 0.59+layout*0.015
		if n>threshold: result = 1
		elif theme=="marsh" and n>0.05: result = 2
		elif theme=="crater" and depth>0 and n>0.22: result = 3
	cached[c] = result
	return result

func walkable(p,radius = 14.0):
	if not bounds.grow(-radius-32).has_point(p): return false
	var a = Vector2i(floori((p.x-radius)/CELL),floori((p.y-radius)/CELL))
	var b = Vector2i(floori((p.x+radius)/CELL),floori((p.y+radius)/CELL))
	if kind(a)==1: return false
	if a==b: return true
	return kind(b)!=1 and kind(Vector2i(a.x,b.y))!=1 and kind(Vector2i(b.x,a.y))!=1

func move(p,delta,radius = 14.0):
	var end = p+delta
	if delta.length_squared()<400 and walkable(end,radius): return end
	# Substeps prevent tunnelling when a test or a slow frame supplies a large dt.
	var steps = maxi(1,ceili(delta.length()/20.0))
	var step = delta/steps
	for i in range(steps):
		var next = p+Vector2(step.x,0)
		if walkable(next,radius): p.x = next.x
		next = p+Vector2(0,step.y)
		if walkable(next,radius): p.y = next.y
	return p

func open_position(p):
	var safe = bounds.grow(-96)
	p = Vector2(clampf(p.x,safe.position.x,safe.end.x),clampf(p.y,safe.position.y,safe.end.y))
	if walkable(p,22): return p
	# Search the whole expanding ring, not only cardinal spokes. Never teleport
	# a distant objective to world origin on failure.
	for r in range(1,25):
		for x in range(-r,r+1):
			for y in [-r,r]:
				var candidate = center(cell(p)+Vector2i(x,y))
				if walkable(candidate,22): return candidate
		for y in range(-r+1,r):
			for x in [-r,r]:
				var candidate = center(cell(p)+Vector2i(x,y))
				if walkable(candidate,22): return candidate
	# Preserve locality even for a malformed solid region by clearing a small
	# landing pocket rather than returning an unrelated spawn coordinate.
	for x in range(-1,2):
		for y in range(-1,2): cached[cell(p)+Vector2i(x,y)] = 0
	return center(cell(p))

func update(dt,p):
	refresh -= dt
	var c:Vector2i = cell(p)
	if c==goal and refresh>0: return
	goal = c
	refresh = 0.5
	flow.clear()
	sight.clear()
	flow[c] = Vector2.ZERO
	var queue:Array[Vector2i] = [c]
	var cursor:int = 0
	while cursor<queue.size():
		var at:Vector2i = queue[cursor]
		cursor += 1
		for d in FLOW_DIRS:
			var next:Vector2i = at+d
			if absi(next.x-c.x)>20 or absi(next.y-c.y)>20 or flow.has(next) or kind(next)==1: continue
			if d.x!=0 and d.y!=0 and (kind(at+Vector2i(d.x,0))==1 or kind(at+Vector2i(0,d.y))==1): continue
			flow[next] = -Vector2(d)
			queue.append(next)
	if cached.size()>16000: cached.clear()

func direction(p,target,identity = 0):
	var c = cell(p)
	if c==goal: return (target-p).normalized()
	if not sight.has(c): sight[c] = line_clear(center(c),center(goal))
	if sight[c] and walkable(p+(target-p).normalized()*24,10): return (target-p).normalized()
	if flow.has(c):
		var next = center(c)+flow[c]*CELL
		if identity!=0: next += Vector2(posmod(identity*13,37)-18,posmod(identity*29,37)-18)
		return (next-p).normalized()
	return (target-p).normalized()

func line_clear(a,b):
	var steps = maxi(1,ceili(a.distance_to(b)/32))
	for i in range(1,steps+1):
		if not walkable(a.lerp(b,float(i)/steps),10): return false
	return true
