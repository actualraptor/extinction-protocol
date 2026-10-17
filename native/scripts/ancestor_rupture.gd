extends RefCounted
## Private Ancestor's Wrath prototype: grounded impact followed by a rupture.
const Bodies=preload("res://scripts/army_collision.gd")
const Art=preload("res://scripts/kael_attack_animation.gd")
static func profile(stats,branch):
	var scale=maxf(.1,stats.radius/115.0)
	return {"impact":72.0*scale,"width":36.0*scale*(1.65 if branch=="broad" else 1.0),"length":240.0*scale*(1.2 if branch=="broad" else 1.0),"directions":2 if branch=="both" else 1,"power":stats.power}
static func impact(g,id,aim,stats,echo=false):
	var epoch=g.encounter_epoch
	var direction:Vector2=aim.normalized() if aim.length_squared()>.0001 else Vector2(-1 if g.facing<0 else 1,0)
	var origin:Vector2=Art.impact_point(g.pos,direction.x<0)
	var branch=g.weapons.get(id,{}).get("branches",{}).get("5","")
	var shape=profile(stats,branch)
	var seen={}
	for enemy in g.nearby(origin,shape.impact+100):
		if enemy.dead or Bodies.engagement_distance(enemy,origin)>shape.impact+Bodies.enemy_radius(enemy):continue
		seen[enemy.uid]=true;strike(g,enemy,id,shape.power,direction)
		if not g.active or g.encounter_epoch!=epoch:return
	# Shared victims prevent the local slam and either front hitting twice.
	for side in range(shape.directions):
		if g.ancestor_ruptures.size()>=32:break
		g.ancestor_ruptures.append({"id":id,"origin":origin,"head":origin,"aim":direction*(-1 if side==1 else 1),"distance":0.0,"length":shape.length,"width":shape.width,"power":shape.power,"seen":seen,"age":0.0,"stopped":false,"hit_limit":stats.get("hit_limit",0),"primary":side==0,"impact_radius":shape.impact})
	if not echo:g.sound.emit("club")
static func strike(g,enemy,id,power,direction):
	g.hit(enemy,power,id)
	if not enemy.dead and not enemy.boss and not enemy.anchor and not enemy.get("boss_prop",false) and not g.rooted(enemy):
		enemy.p=g.terrain.move(enemy.p,direction*45)
static func update(g,dt):
	for wave in g.ancestor_ruptures:
		wave.age+=dt
		if not g.weapons.has(wave.id):wave.stopped=true;continue
		if wave.stopped:continue
		var previous:Vector2=wave.head
		var remaining=minf(520.0*dt,wave.length-wave.distance)
		while remaining>.001:
			var step=minf(8.0,remaining)
			var intended:Vector2=wave.head+wave.aim*step
			# A committed fracture stops at rock; it never navigates around it.
			if not g.terrain.walkable(intended):wave.stopped=true;break
			wave.head=intended;wave.distance+=step;remaining-=step
		var center:Vector2=(previous+wave.head)*.5
		for enemy in g.nearby(center,previous.distance_to(wave.head)*.5+wave.width+100):
			if enemy.dead or wave.seen.has(enemy.uid):continue
			if wave.hit_limit>0 and wave.seen.size()>=wave.hit_limit:break
			var closest:Vector2=Geometry2D.get_closest_point_to_segment(enemy.p,previous,wave.head)
			if Bodies.engagement_distance(enemy,closest)>wave.width+Bodies.enemy_radius(enemy):continue
			wave.seen[enemy.uid]=true;strike(g,enemy,wave.id,wave.power,wave.aim)
		if wave.distance>=wave.length-.001:wave.stopped=true
	g.ancestor_ruptures=g.ancestor_ruptures.filter(func(w):return g.weapons.has(w.id) and w.age<maxf(.8,w.length/520.0+.35))
