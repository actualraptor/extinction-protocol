extends SceneTree
const E = preload("res://scripts/expedition.gd")
func _initialize():
	var failures = 0
	for hero in range(3):
		var g = E.new()
		g.setup(hero,"expedition",{},5729)
		for frame in range(1800):
			if not g.active: break
			if g.choosing: g.choose(0)
			var target = g.pos+Vector2.from_angle(g.time*0.3)*300
			var distance = INF
			for gem in g.gems:
				var d = gem.p.distance_squared_to(g.pos)
				if d<distance:
					distance = d
					target = gem.p
			var direction = (target-g.pos).normalized()
			var avoidance = Vector2.ZERO
			for enemy in g.nearby(g.pos,140):
				var delta = g.pos-enemy.p
				avoidance += delta.normalized()*maxf(0,1-delta.length()/140)
			if avoidance.length()>0.3: direction = (direction*0.4+avoidance*2).normalized()
			for angle in [0,0.7,-0.7,1.5,-1.5,PI]:
				var try_direction = direction.rotated(angle)
				if g.terrain.walkable(g.pos+try_direction*40):
					direction = try_direction
					break
			g.tick(1.0/30,direction)
		print("OPENING / hero=",hero," / alive=",g.active," / health=",g.hp," / level=",g.level," / kills=",g.kills," / time=",g.time)
		if not g.active or g.kills<20: failures += 1
	quit(failures)
