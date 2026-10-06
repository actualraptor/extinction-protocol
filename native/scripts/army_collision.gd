extends RefCounted
## Ground-space bodies, separate from tall painted sprite silhouettes.
const CELL=128.0
var buckets={}
static func radius(u):
	if u.get("boss_form",false):return 60.0
	if u.role=="colossus":return 65.0
	return 32.0 if u.get("champion",false) else 26.0
static func enemy_radius(e):return minf(100,e.size*.75) if e.boss else clampf(e.size*.7,11,32)
func build(units):
	buckets.clear()
	for u in units:
		if u.hp<=0 or u.role=="wraith":continue
		var cell=Vector2i(floori(u.p.x/CELL),floori(u.p.y/CELL))
		if not buckets.has(cell):buckets[cell]=[]
		buckets[cell].append(u)
func block_enemy(e,origin,destination):
	if e.get("immovable",false):origin=e.anchor_p;destination=e.anchor_p
	var reach=enemy_radius(e)+65.0
	var lo=Vector2i(floori((minf(origin.x,destination.x)-reach)/CELL),floori((minf(origin.y,destination.y)-reach)/CELL))
	var hi=Vector2i(floori((maxf(origin.x,destination.x)+reach)/CELL),floori((maxf(origin.y,destination.y)+reach)/CELL))
	var obstacles=[]
	for y in range(lo.y,hi.y+1):
		for x in range(lo.x,hi.x+1):
			for u in buckets.get(Vector2i(x,y),[]):
				if u.hp<=0:continue
				var spacing=radius(u)+enemy_radius(e)
				if e.boss:
					var closest=Geometry2D.get_closest_point_to_segment(u.p,origin,destination)
					var away=u.p-closest
					if away.length_squared()<spacing*spacing:
						var travel=destination-origin
						var normal=away.normalized() if away.length_squared()>.01 else travel.orthogonal().normalized() if travel.length_squared()>.01 else Vector2.from_angle(u.uid*2.399)
						u.p=closest+normal*(spacing+.5)
				else:obstacles.append({"p":u.p,"radius":spacing,"seed":e.uid+u.uid})
	if e.boss:return destination
	return move(origin,destination,obstacles)
static func move(origin,destination,obstacles):
	var result=destination
	for sweep in range(4):
		for body in obstacles:
			var gap=origin-body.p;var r=body.radius;var travel=result-origin
			# Swept circle contact prevents charges and long frames tunnelling.
			var length2=travel.length_squared()
			if length2>.0001 and gap.length_squared()>=r*r:
				var b=gap.dot(travel);var disc=b*b-length2*(gap.length_squared()-r*r)
				if b<0 and disc>=0:
					var t=(-b-sqrt(disc))/length2
					if t>=0 and t<=1:
						var contact=origin+travel*t;var normal=(contact-body.p).normalized()
						var remaining=travel*(1-t)
						remaining-=normal*minf(0,remaining.dot(normal))
						result=contact+normal*.05+remaining
			var separation=result-body.p
			if separation.length_squared()<r*r:
				var normal=separation.normalized() if separation.length_squared()>.0001 else Vector2.from_angle(body.seed*2.399)
				result=body.p+normal*(r+.05)
		var unresolved=false
		for body in obstacles:
			if result.distance_squared_to(body.p)<body.radius*body.radius:
				unresolved=true;break
		if not unresolved:break
	return result
static func move_minion(g,u,destination):
	var obstacles=[]
	var reach=radius(u)+u.p.distance_to(destination)+100
	for e in g.nearby(u.p,reach):
		if e.dead or e.get("breakable",false):continue
		var spacing=radius(u)+enemy_radius(e)
		if Geometry2D.get_closest_point_to_segment(e.p,u.p,destination).distance_squared_to(e.p)>spacing*spacing:continue
		obstacles.append({"p":e.p,"radius":spacing,"seed":u.uid+e.uid})
	return move(u.p,destination,obstacles)
