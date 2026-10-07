extends SceneTree
const E = preload("res://scripts/expedition.gd")
var failures = 0
func check(ok,message):
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures += 1
func game():
	var g = E.new()
	g.setup(2,"expedition",{},741)
	return g
func _initialize():
	var g = game()
	g.time = 310
	g.spawn_boss(1)
	g.add_gem(Vector2(20,0),10)
	g.kill(g.boss)
	check(g.portal!=null and g.depth==0 and not g.gems.is_empty(),"Boss leaves a portal and preserves biome and drops")
	g.choose(0)
	var base_threat = g.threat()
	g.linger = 60
	check(g.threat()>base_threat*2,"Lingering escalates enemy toughness")
	g.next_boss = 0
	g.invul = 10
	g.tick(0.1,Vector2.ZERO)
	check(g.boss==null and g.depth==0,"Next biome boss cannot spawn before portal entry")
	g.pos = g.portal
	if g.choosing: g.choose(0)
	g.portal_charge = g.PORTAL_CHARGE_SECONDS-0.01
	g.tick(0.05,Vector2.ZERO)
	check(g.depth==1 and g.portal==null and g.transition_time>0,"Walking into portal triggers protected biome transition")
	check(g.linger==0 and g.next_boss==600,"New biome keeps the ten-minute run-time boss milestone")
	g.depth = 1
	g.time = 1000
	g.portal = Vector2.ZERO
	g.enter_portal()
	check(g.next_boss==1045,"Late biome entry grants 45 seconds instead of delaying the boss five minutes")
	g = game()
	g.depth = 1
	for i in range(40):
		var e = g.spawn_enemy(false,Vector2.from_angle(i*TAU/40)*280,5)
		e.attack = 0
	for i in range(300):
		g.time += 1.0/30
		g.update_enemies(1.0/30)
	check(g.hostile_shots.size()>0 and g.hostile_shots.size()<=3,"Forty casters share at most three shots in ten seconds")
	check(g.hazards.is_empty(),"Spitters no longer generate green ground hazards")
	g = game()
	var brood = g.spawn_enemy(false,Vector2(100,0),8)
	g.kill(brood)
	g.update_enemies(0.01)
	check(g.enemies.size()==3 and g.enemies.all(func(e):return e.kind==8),"Oviraptor releases exactly three same-species juvenile hatchlings")
	var charger = g.spawn_enemy(false,Vector2(200,0),7)
	charger.attack = 0
	g.update_enemies(0.1)
	check(charger.get("charge_wait",0)>0 and charger.has("charge_dir"),"Pachyrhinosaurus telegraphs a committed charge")
	check(g.Bestiary.DATA.size()==19,"Nineteen distinct dinosaur species")
	g.spawn_boss(2)
	check(g.boss.max_hp==900000 and g.boss.identity=="basalt","T-rex preserves second-encounter health and stable ID")
	var encounter=preload("res://scripts/boss_encounters.gd")
	encounter.prepare(g)
	check(g.boss.move=="PREDATORY RUSH" and g.hazards[-1].kind=="line","T-rex opens with a committed physical rush")
	g.hazards.clear();encounter.prepare(g)
	check(g.boss.move=="CRUSHING BITE" and g.hazards[-1].kind=="cone","T-rex follows with a frontal bite tell")
	print("BIOME PASS / ",failures," failures")
	quit(failures)
