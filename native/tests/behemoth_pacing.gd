extends SceneTree
func _initialize():
	var g = preload("res://scripts/expedition.gd").new()
	g.setup(2,"expedition",{},192)
	g.time = 600
	g.depth = 1
	g.level = 53
	g.weapons = {"frost":{"level":8,"evolved":false,"timer":0},"pyre":{"level":10,"evolved":false,"timer":0},"fire":{"level":5,"evolved":false,"timer":0},"mortar":{"level":8,"evolved":true,"timer":0},"shotgun":{"level":4,"evolved":false,"timer":0}}
	g.passives = {"damage":2,"haste":2,"area":2,"count":1}
	g.relics = ["clock","wildfire","shatter","frost"]
	g.spawn_boss(2)
	for i in range(3600):
		if g.boss==null: break
		g.invul = 10
		g.tick(1.0/30,(g.boss.p+Vector2(0,110)-g.pos).normalized())
		if g.choosing: g.choose(0)
	print("BEHEMOTH PACING / video-inspired five-slot build / seconds=",g.boss_time," / defeated=",g.boss==null)
	quit(0 if g.boss==null and g.boss_time<90 else 1)
