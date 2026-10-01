extends SceneTree

const Expedition = preload("res://scripts/expedition.gd")
func _initialize():
	for strong in [false,true]:
		var g = Expedition.new()
		g.setup(2,"safari",{},9127)
		g.weapons.clear()
		for id in (["frost","fire","lightning","orbital","mortar"] if strong else ["frost","fire","revolver"]):
			g.weapons[id] = {"level":10 if strong else 3,"evolved":strong,"timer":0.1}
		g.passives = {"damage":5,"haste":5,"count":3,"area":4,"crit":5,"speed":2} if strong else {"damage":2,"haste":2}
		var frames = 0
		while g.active and frames<13000:
			g.hp = g.max_hp
			g.invul = 1
			var target = g.anchors[0].p+Vector2(0,85) if not g.anchors.is_empty() else g.boss.p+Vector2(0,145)
			g.tick(1.0/60,(target-g.pos).normalized())
			frames+=1
		print("BALANCE / strong=%s / won=%s / seconds=%.1f / health_remaining=%.0f / actual_damage=%.0f"%[strong,g.won,g.boss_time,0 if g.boss==null else g.boss.hp,g.damage_total])
		if strong and not g.won:
			quit(1)
			return
		if not strong and g.won:
			quit(2)
			return
	quit(0)
