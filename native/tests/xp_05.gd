extends SceneTree
const E = preload("res://scripts/expedition.gd")
var failures = 0
func check(ok,message):
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures += 1
func total(g):
	return g.gems.reduce(func(sum,gem):return sum+gem.value,0.0)+g.xp
func _initialize():
	var g = E.new()
	g.setup(2,"expedition",{},923)
	g.depth = 1
	for i in range(800): g.add_gem(Vector2(3000+i*5,2000),1.3)
	var banked = total(g)
	for i in range(100):
		var e = g.spawn_enemy(false,g.pos+Vector2(40,0),0)
		g.kill(e)
		g.update_gems(0.1)
	check(g.xp>100,"Biome two kills keep giving nearby XP at the 800-gem cap")
	check(absf(total(g)-(banked+130))<0.001,"Compaction preserves every point of XP")
	check(g.gems.size()<=800,"XP entity count stays bounded")
	var before = total(g)
	g.Pickups.activate(g,"magnet")
	for i in range(100):
		g.add_gem(Vector2(100,0),1.3)
		g.update_gems(0.1)
	check(absf(total(g)-(before+130))<0.001,"Kills during gravity pickup preserve all XP")
	check(g.gems.all(func(gem):return gem.p.distance_to(g.pos)<200) and g.xp>1000,"Gravity collects all consolidated distant XP; later drops retain normal pickup range")
	print("XP 05 / ",failures," failures")
	quit(failures)
