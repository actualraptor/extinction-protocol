extends SceneTree
const E = preload("res://scripts/expedition.gd")
func _initialize():
	var results = []
	for ids in [["fire","mortar"],["supernova"],["lightning","frost"],["whiteout"],["revolver","shotgun"],["lastword"],["club","spear"],["earthshaker"],["orbital","aegis"],["bastion"]]:
		var g = E.new()
		g.setup(2,"expedition",{},706)
		g.weapons.clear()
		for id in ids: g.weapons[id] = {"level":10,"evolved":true,"timer":0}
		g.passives = {"damage":5,"haste":5,"count":3,"area":5,"crit":5}
		g.augments = {"sorcery":4,"fork":3,"conductor":3,"combustion":3,"linger":3,"echo":2,"reach":3}
		var e = g.spawn_enemy(false,Vector2(170,0),0,false)
		e.hp = 100000000
		e.max_hp = e.hp
		e.size = 115
		e.boss = true
		g.build_grid()
		for i in range(600):
			g.time += 1.0/30
			g.update_weapons(1.0/30)
			g.update_shots(1.0/30)
			g.update_hazards(1.0/30)
			# Include ordinary burn ticks without movement or enemy attacks.
			e.burn_tick -= 1.0/30
			if e.burn>0 and e.burn_tick<=0:
				e.burn_tick = 0.5
				g.hit(e,e.get("burn_damage",0),e.get("burn_source","fire"),false,false)
		print("UNION PROBE / ",ids," / single large target DPS ",roundf(g.damage_total/20))
		results.append(g.damage_total/20)
	var failures = 0
	for pair in range(5):
		var ok = results[pair*2+1]>results[pair*2]
		print("PASS / " if ok else "FAIL / ","Union preserves ingredient pair's boss damage / ",pair)
		if not ok: failures += 1
	quit(failures)
