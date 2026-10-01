extends RefCounted
## Seeded, one-time breakables per district. No kills, XP or kill procs from props.
static func update(g,dt):
	g.breakable_clock-=dt
	if g.breakable_clock>0 or g.boss!=null: return
	g.breakable_clock=1.0
	var cell=Vector2i(floori(g.pos.x/384),floori(g.pos.y/384))
	var count=0
	for e in g.enemies:
		if not e.get("breakable",false): continue
		if e.p.distance_squared_to(g.pos)>1600*1600: e.dead=true
		elif not e.dead: count+=1
	for x in range(-2,3):
		for y in range(-2,3):
			if count>=20 or g.enemies.size()>=g.director.cap(g): return
			var c=cell+Vector2i(x,y)
			var key="%s/%s/%s"%[g.depth,c.x,c.y]
			if g.breakable_cells.has(key): continue
			g.breakable_cells[key]=true
			var h=absi(c.x*73856093 ^ c.y*19349663 ^ g.terrain.seed_value)
			if h%3!=0: continue
			var p=g.terrain.open_position(Vector2(c)*384+Vector2(100+h%180,100+(h/11)%180))
			var e=g.spawn_enemy(false,p,4,false)
			e.breakable=true;e.role="prop";e.size=20;e.hp=26+g.depth*12;e.max_hp=e.hp;e.speed=0;e.prop_art=(h/3)%3
			count+=1
static func destroy(g,e):
	g.effect.emit("impact",e.p,Color("f3c68b"),55)
	g.sound.emit("breakable")
	var roll=g.rng.randf()
	var id="amber" if roll<0.70 else "heal" if roll<0.90 else "magnet" if roll<0.95 else ["freeze","frenzy","surge","nuke"][g.rng.randi_range(0,3)]
	if g.pickups.size()<24: g.pickups.append({"id":id,"p":e.p,"life":65.0,"magnet":false})
	elif id=="amber": g.amber+=8
	g.log_event("breakable",{"drop":id})
