extends SceneTree
const E = preload("res://scripts/expedition.gd")
var failures = 0
func check(ok,message):
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures += 1
func game():
	var g = E.new()
	g.setup(2,"expedition",{},741)
	g.terrain.arena = Vector2.ZERO
	return g
func _initialize():
	var g = game()
	g.pos = g.shrine_pos
	g.update_objectives(5.9)
	check(not g.shrine_done,"Rift does not complete early")
	g.update_objectives(0.11)
	check(g.shrine_done,"Rift charges in six seconds")
	g = game()
	var e = g.spawn_enemy(false,Vector2(240,0),5)
	e.attack = 0
	g.update_enemies(0.01)
	check(e.get("spit_wait",0)>0 and g.hostile_shots.is_empty() and g.hazards.is_empty(),"Spitter telegraphs rather than dropping an instant ground attack")
	var aim = e.spit_dir
	g.pos = Vector2(0,110)
	g.update_enemies(0.7)
	check(g.hostile_shots.size()==1 and g.hostile_shots[0].v.normalized().is_equal_approx(aim),"Venom commits to its original aim and can be sidestepped")
	var hp = g.hp
	g.update_hostile_shots(1.0)
	check(g.hp==hp,"Sidestepping avoids the projectile")
	g.hostile_shots = [{"p":g.pos+Vector2(-120,0),"v":Vector2(500,0),"life":3.0,"damage":17}]
	g.update_hostile_shots(0.5)
	check(g.hp<hp and g.hostile_shots.is_empty(),"Swept venom collision hits once even during a slow frame")
	g = game()
	g.hostile_shots = [{"p":Vector2(90,0),"v":Vector2(270,0),"life":3.0,"damage":17}]
	g.buffs.freeze = 1
	g.update_hostile_shots(0.2)
	check(g.hostile_shots[0].p==Vector2(90,0),"Time-stop also freezes hostile projectiles")
	for step in [1.0/30,1.0/60,0.13]:
		g = game()
		g.weapons = {"thunderstorm":{"level":1,"evolved":false,"timer":0}}
		e = g.spawn_enemy(false,Vector2(120,0),0)
		e.hp = 100000
		g.build_grid()
		g.update_weapons(step)
		check(g.zones.size()==1,"Thunderstorm creates one targeted field")
		var zone = g.zones[0]
		g.weapons.thunderstorm.timer = 100
		for i in range(ceili(3.0/step)):
			g.time += step
			g.update_weapons(step)
		check(zone.pulse==4 and g.zones.is_empty(),"Two-second storm has exactly four strikes at timestep "+str(step))
		check(g.damage_by_weapon.get("thunderstorm",0)>0,"Storm deals real damage inside its field")
	g = game()
	g.weapons = {"thunderstorm":{"level":8,"evolved":false,"timer":0}}
	check(g.Rules.can_add_weapon(g.weapons,g.C.WEAPONS,"winter"),"Storm is a targeted field and may coexist with one aura")
	check(not g.Rules.eligible(g.weapons,g.C.WEAPONS,g.Rules.AUGMENTS.pierce.filter),"Storm does not offer irrelevant projectile piercing")
	g.augments.linger = 1
	check(g.Rules.stats(g,"thunderstorm").duration==1.5,"Duration augment extends storm")
	g.portal = Vector2.ZERO
	g.zones.append({"life":10})
	g.hostile_shots.append({"life":10})
	g.enter_portal()
	check(g.zones.is_empty() and g.hostile_shots.is_empty(),"Portal clears old-biome spell fields and venom")
	print("PATCH 05 / ",failures," failures")
	quit(failures)
