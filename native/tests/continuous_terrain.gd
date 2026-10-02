extends SceneTree
const Terrain = preload("res://scripts/terrain_map.gd")
var failures = 0
func check(value,label):
	print("PASS / " if value else "FAIL / ",label)
	if not value: failures += 1
func _initialize():
	var t = Terrain.new()
	t.seed_value = 923
	var route = Vector2(20000,-17000)
	t.configure({"bounds":Rect2(-40000,-34000,80000,68000),"routes":[route],"regions":[{"p":Vector2(7000,0),"radius":6000.0,"kind":"ridge"}],"landmarks":[{"p":route}]},0)
	var clear = true
	for step in range(401): clear = clear and t.walkable(route*float(step)/400,32)
	check(clear,"Broad route connects distant objective to spawn")
	check(t.walkable(Vector2.ZERO,32) and t.walkable(route,32),"Spawn and landmark clearings remain navigable")
	check(not t.walkable(Vector2(41000,0)),"Finite world boundary blocks movement")
	var safe = t.open_position(Vector2(90000,22000))
	check(t.walkable(safe,22) and safe.x>39000 and safe.y>21000,"Out-of-bounds placement clamps locally instead of teleporting to origin")
	var changed = 0
	var walls = 0
	var first_wall = Vector2.INF
	for x in range(64,160):
		for y in range(-48,48):
			var c = Vector2i(x,y)
			if t.kind(c)==1:
				walls += 1
				first_wall = t.center(c)
			if t.kind(c)!=t.kind(c+Vector2i(16,0)): changed += 1
	check(walls>0 and walls<2000,"Terrain contains sparse obstacle islands with ample open space")
	check(changed>200,"Collision does not repeat every former1024px district")
	if first_wall!=Vector2.INF:
		var landing = t.open_position(first_wall)
		check(t.walkable(landing,22) and landing.distance_to(first_wall)<1600,"Blocked positions resolve to nearby safe ground")
		t.arena = first_wall
		check(t.kind(t.cell(first_wall))==0,"Boss arena overrides nearby obstacles")
	t.update(0.1,route)
	check(t.flow.size()<=1681,"Navigation remains local and bounded on large maps")
	print("Terrain samples / walls=",walls," changed=",changed," flow=",t.flow.size())
	var stages = preload("res://scripts/stage_definition.gd")
	for id in stages.DATA:
		var definition = stages.stage(id)
		t.configure(definition,0)
		var reachable = true
		for target in definition.routes:
			var steps = maxi(1,ceili(target.length()/128.0))
			for step in range(steps+1):
				if not t.walkable(target*float(step)/steps,32): reachable = false
		check(reachable,id+" authored objectives have continuous broad routes")
		check(stages.validate(id).is_empty(),id+" curated placement spacing validates")
	quit(failures)
