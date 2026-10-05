extends SceneTree
const E=preload("res://scripts/expedition.gd")
var fail=0
func check(ok,msg):
	if not ok: fail+=1
	print("PASS / " if ok else "FAIL / ",msg)
func _initialize():
	var g=E.new();g.setup(2,"expedition",{},88,"frostbreak")
	check(is_equal_approx(g.crit_curve(1),1),"First 100 percent crit has no penalty")
	check(is_equal_approx(g.crit_curve(3)-g.crit_curve(2),.4),"Higher crit bands have diminishing returns")
	check(is_equal_approx(g.crit_curve(2),1.65),"Second band counts at 65 percent")
	check(is_equal_approx(g.crit_curve(4),2.45),"Next two bands count at 40 percent")
	check(is_equal_approx(g.crit_curve(8),3.45),"Further gains count at 25 percent")
	var doubles=0;var triples=0
	for i in range(10000):
		var tier=g.roll_crit_tier(2.5)
		if tier==2:doubles+=1
		elif tier==3:triples+=1
	check(doubles+triples==10000 and abs(triples-5000)<250,"250 percent yields guaranteed doubles and half triples")
	g.passives.crit=60
	check(g.crit_chance()>2.5,"An extreme crit build can exceed 250 percent")
	var enemy=g.spawn_enemy(false,Vector2(40,0),0,false);enemy.hp=10000
	var before=enemy.hp;g.hit(enemy,100,"revolver",true,false)
	check(enemy.last_crit_tier in [floori(g.crit_chance()),floori(g.crit_chance())+1] and is_equal_approx(before-enemy.hp,100*pow(1.9,enemy.last_crit_tier)),"Multi-crit damage follows multiplicative tiers")
	g.enemies.clear();g.depth=1;g.time=420
	g.director.update(g,0.1)
	for i in range(500):g.spawn_enemy(false,null,14,false)
	var charges=g.enemies.filter(func(e):return e.get("role","")=="charge")
	check(charges.size()<=6,"Explicit horde spawns respect charger cap")
	for e in charges:e.p=Vector2(200,0);e.attack=0
	g.terrain.arena=Vector2.ZERO;g.build_grid();g.update_enemies(0.1)
	check(charges.filter(func(e):return e.get("charge_wait",0)>0).size()==1,"Only one charger begins its windup together")
	quit(1 if fail else 0)

