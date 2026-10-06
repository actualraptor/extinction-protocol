extends SceneTree
const E=preload("res://scripts/expedition.gd")
var fails=0
var checks=0
func check(ok,msg):
	checks+=1
	if not ok:fails+=1;print("FAIL / ",msg)
func _initialize():
	var builds={}
	for seed_value in range(12):
		var a=E.new();a.setup(2,"daily",{"power":5},seed_value+771)
		var b=E.new();b.setup(2,"daily",{},seed_value+771)
		check(a.weapons==b.weapons and a.base_damage==1,"Equal start and no research")
		for lv in range(2,62):
			a.level=lv;b.level=lv
			a.rng.randf() # Combat RNG must not change reward RNG.
			a.open_choices(lv%7==0);b.open_choices(lv%7==0)
			check(a.choosing and b.choosing,"Rewards wait for reveal acknowledgement")
			a.choose(0);b.choose(0)
			check(not a.choosing and a.weapons.size()<=5 and a.relics.size()<=8,"Automatic rewards respect inventory")
			check(a.weapons==b.weapons and a.passives==b.passives and a.relics==b.relics,"Seeded rewards unaffected by combat RNG")
		builds[str(a.weapons.keys())]=true
	check(builds.size()>8,"Different seeds produce varied builds")
	var g=E.new();g.setup(2,"daily",{},888)
	var normal=E.new();normal.setup(g.hero,"expedition",{},99)
	normal.weapons=g.weapons.duplicate(true);normal.rng.seed=g.daily_reward_rng.seed
	normal.open_choices(false);g.open_choices(false)
	var roll=g.event_log.filter(func(e):return e.type=="daily-roll")[-1]
	check(roll.offered==normal.options,"Daily uses the normal three-choice generator")
	g.spawn_boss(3);g.kill(g.boss)
	check(g.active and g.portal!=null,"Daily meteor opens a portal rather than victory")
	g.choose(0)
	g.enter_portal()
	check(g.daily_loop==1 and g.depth==0 and g.boss_stage==0,"Portal starts a new circuit")
	var first_circuit=E.new();first_circuit.setup(g.hero,"daily",{},888);first_circuit.spawn_boss(1)
	g.spawn_boss(1);check(is_equal_approx(g.boss.max_hp,first_circuit.boss.max_hp*2),"Second circuit boss has doubled HP")
	var expedition=E.new();expedition.setup(2,"expedition",{},123);expedition.spawn_boss(3);expedition.kill(expedition.boss)
	check(expedition.won and not expedition.active,"Normal expedition still ends on meteor victory")
	print("DAILY 082 / ",checks," checks / ",fails," failures");quit(1 if fails else 0)
