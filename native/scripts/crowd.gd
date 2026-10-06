extends RefCounted
## Small spatial buckets, bounded neighbour work, ground bodies respect walls.
var buckets: Dictionary = {}
func cell(p: Vector2) -> Vector2i: return Vector2i(floori(p.x/48),floori(p.y/48))
func airborne(e: Dictionary) -> bool: return e.get("role","") in ["fly","phase"]
func radius(e: Dictionary) -> float: return clampf(e.size*0.7,11,32)
func build(enemies):
	buckets.clear()
	for e in enemies:
		if e.dead: continue
		var key: Vector2i = cell(e.p)
		if not buckets.has(key): buckets[key] = []
		# Compact contact snapshots avoid repeated large Dictionary reads and
		# searches/removals while thousands of creatures cross bucket edges.
		buckets[key].append(Vector4(e.p.x,e.p.y,radius(e),e.uid))
func move(g,e: Dictionary,delta: Vector2,dt: float) -> Vector2:
	var origin: Vector2 = e.p
	var key: Vector2i = cell(origin)
	# Reuse contact normals for two 30 Hz steps. Bodies still collide every
	# step; only the neighbour search is staggered across the horde.
	if e.has("crowd_normals") and (g.enemy_frame+e.uid)%3!=0:
		for normal in e.crowd_normals:
			var into: float = delta.dot(normal)
			if into<0: delta -= normal*into
		return finish_move(g,e,key,delta+e.crowd_push.limit_length(120*dt))
	var push: Vector2 = Vector2.ZERO
	var normals: Array[Vector2] = []
	var travel_length: float = delta.length()
	var budget: int = 12
	var body_radius: float = radius(e)
	for offset_cell in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN,Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
		if budget<=0: break
		var bucket: Array = buckets.get(key+offset_cell,[])
		for offset in range(mini(bucket.size(),6)):
			if budget<=0: break
			var other: Vector4 = bucket[(offset+g.enemy_frame*7+e.uid)%bucket.size()]
			if int(other.w)==e.uid: continue
			budget -= 1
			var gap: Vector2 = origin-Vector2(other.x,other.y)
			var spacing: float = body_radius+other.z
			if gap.length_squared()>(spacing+travel_length)*(spacing+travel_length): continue
			var distance: float = gap.length()
			var away: Vector2 = gap/distance if distance>0.01 else Vector2.from_angle((mini(e.uid,int(other.w))*2.399))*(1 if e.uid>other.w else -1)
			if distance<spacing: push += away*(spacing-distance)*0.55
			# Cancel motion into an occupied body, retaining tangential sliding.
			var into: float = delta.dot(away)
			if distance<spacing+2:
				normals.append(away)
				if into<0: delta -= away*into
	e.crowd_normals = normals
	e.crowd_push = push
	var movement: Vector2 = delta+push.limit_length(120*dt)
	return finish_move(g,e,key,movement)

func finish_move(g,e,_key,movement):
	var result: Vector2 = e.p+movement if airborne(e) else g.terrain.move(e.p,movement,10)
	if g.boss!=null and not e.boss and not e.anchor:
		var gap: Vector2 = result-g.boss.p
		var spacing: float = g.boss.size*1.15+radius(e)+18
		if gap.length_squared()<spacing*spacing:
			result=g.boss.p+(gap.normalized() if gap.length_squared()>0.01 else Vector2.from_angle(e.uid*2.399))*spacing
	if g.companions!=null:result=g.companions.collision.block_enemy(e,e.p,result)
	return result
