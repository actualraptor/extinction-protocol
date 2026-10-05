extends SceneTree
const E=preload("res://scripts/expedition.gd")
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():
	var g=E.new();g.setup(1,"expedition",{},114)
	for luck in [0.0,.1,.84,1.0,10.0]:
		g.permanent_luck=luck
		var odds=g.Relics.odds(g,false)
		check(is_equal_approx(odds.reduce(func(a,b):return a+b,0.0),100),"Odds normalize")
		check(is_equal_approx(odds[5],.3*pow(1+luck,5)/rarity_total(luck)*100),"Artifact uses exact additive roll bonus")
		for value in odds:check(value>=0 and value<=100,"Valid probability")
		if luck==.1:check(is_equal_approx(odds[0],40.0/rarity_total(.1)*100),"Ten percent Luck uses original weights")
		g.relic_state.dry_chests=4
		var pity=g.Relics.odds(g,true)
		check(pity[0]==0 and pity[1]==0 and is_equal_approx(pity.reduce(func(a,b):return a+b,0.0),100),"Pity still normalizes Rare+")
		g.relic_state.dry_chests=0
	g.permanent_luck=0
	g.gems.clear();g.pos=Vector2.ZERO
	g.add_gem(Vector2(1800,0),10)
	g.pickups=[{"id":"frenzy","p":Vector2(1500,0),"life":65.0,"magnet":false}]
	g.Pickups.activate(g,"magnet")
	check(g.buffs.magnet==5 and g.gems[0].magnet,"Magnet starts five-second window")
	g.Pickups.update(g,4.9);g.add_gem(Vector2(1700,0),20)
	check(g.gems[-1].magnet,"New XP follows active magnet")
	check(g.pickups.size()==1 and g.pickups[0].p==Vector2(1500,0),"Magnet leaves dropped buff alone")
	g.Pickups.update(g,.11);g.add_gem(Vector2(1600,0),30)
	check(not g.gems[-1].magnet,"Window expires for new XP")
	check(g.gems[0].magnet,"Previously swept XP remains in transit")
	var b=E.new();b.setup(1,"expedition",{},114);b.enemies.clear();b.gems.clear();b.pos=Vector2.ZERO
	b.add_gem(Vector2(1800,0),10);b.spawn_boss(1);b.kill(b.boss)
	check(b.gems.all(func(gem):return gem.magnet),"Boss sweeps existing XP")
	check(b.buffs.get("magnet",0)==0,"Boss grants no timed magnet")
	b.add_gem(Vector2(1900,0),10)
	check(not b.gems[-1].magnet,"Boss sweep excludes subsequent drops")
	for map in ["cradle","frostbreak","observatory"]:
		for stage in [1,2,3]:
			b.spawn_boss(stage)
			check(b.boss.hp==[90000.0,900000.0,30000000.0][stage-1],"Meteor fivefold; other bosses tenfold")
	print("FORTUNE + VACUUM 0114 / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)

func rarity_total(luck):
	var sum=0.0
	for tier in range(6):sum+=[40.0,30.0,18.0,9.0,2.7,0.3][tier]*pow(1+luck,tier)
	return sum
