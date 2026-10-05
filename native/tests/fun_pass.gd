extends SceneTree
const E = preload("res://scripts/expedition.gd")
const C = preload("res://scripts/catalog.gd")
var count = 0
var failures = 0
func check(ok,message):
	count += 1
	if not ok: failures += 1
	print("PASS / " if ok else "FAIL / ",message)
func game():
	var g = E.new()
	g.setup(2,"expedition",{},1927)
	return g
func _initialize():
	for speed in [460,2200]:
		for i in range(16):
			var g = game()
			var direction = Vector2.from_angle(i*TAU/16)
			var e = g.spawn_enemy(false,direction*83,0)
			e.size = 5
			e.hp = 1000
			g.build_grid()
			g.shoot("frost",Vector2.ZERO,direction,30,speed,2,1)
			for frame in range(10): g.update_shots(1.0/30)
			check(e.hp<1000,"Small-target swept frost / speed %s / angle %s"%[speed,i])
	var g = game()
	g.weapons.winter = {"level":1,"evolved":false,"timer":0.0}
	check(not C.Rules.can_add_weapon(g.weapons,C.WEAPONS,"pyre"),"Second offensive aura excluded")
	check(C.Rules.can_add_weapon(g.weapons,C.WEAPONS,"aegis") and C.Rules.can_add_weapon(g.weapons,C.WEAPONS,"orbital"),"Shield and orbitals retain distinct roles")
	for id in ["fire","frost","orbital"]: g.weapons[id] = {"level":1,"evolved":false,"timer":0}
	g.open_choices(false)
	check(g.weapons.size()==5 and g.options.all(func(o):return o.type!="weapon" or g.weapons.has(o.id)),"Full backpack only offers existing weapon upgrades")
	var old = g.options.duplicate(true)
	g.reroll_choices()
	check(g.rerolls==2 and g.options.all(func(o):return o not in old),"Reroll spends one charge and replaces choices")
	g.reroll_choices()
	g.reroll_choices()
	check(not g.reroll_choices() and g.rerolls==0,"Cannot overspend rerolls")
	var tiers = {}
	var valid = true
	for i in range(5000):
		var reward = g.Relics.roll_reward(g)
		var d = C.RELICS[reward.id]
		tiers[reward.rarity] = tiers.get(reward.rarity,0)+1
		valid = valid and C.Rules.eligible(g.weapons,C.WEAPONS,d.get("filter",{}))
	check(valid and tiers.size()==6,"All six tiers reachable; all rewards compatible")
	check(tiers.ARTIFACT<tiers.LEGENDARY and tiers.LEGENDARY<tiers.RARE,"Artifact is rarer than Legendary and Rare")
	print("RARITY SAMPLE / ",tiers)
	g.relics = ["flint","wrap","coil","lens","chronicle"]
	var repeat_seen=false
	for i in range(50):
		var reward=g.Relics.roll_reward(g)
		repeat_seen=repeat_seen or reward.id in g.relics
		check(not reward.is_empty(),"Owned relics remain eligible for tiered stacks")
	check(repeat_seen,"Repeated relic identity can roll again")
	g = game()
	g.relic_state.dry_chests = 4
	check(g.Relics.TIERS.find(g.Relics.roll_reward(g).rarity)>=2,"Fifth dry chest guarantees Rare or better")
	var e = g.spawn_enemy(false,Vector2(50,0),0)
	e.hp = 10000
	e.frozen = 1.0
	g.hit(e,100,"fire",false)
	check(e.frozen==0 and g.proc_queue.size()==1,"Fire consumes freeze for one thermal explosion")
	g.hit(e,100,"fire",false)
	check(g.proc_queue.size()==1,"Thermal shock cannot recursively retrigger")
	var initial = C.Rules.stats(g,"lightning")
	g.relics = ["prism","coil"]
	var enhanced = C.Rules.stats(g,"lightning")
	check(enhanced.count==initial.count+1 and enhanced.cooldown<initial.cooldown,"New relics affect actual projectile count and recharge")
	print("FUN PASS / ",count," checks / ",failures," failures")
	quit(failures)
