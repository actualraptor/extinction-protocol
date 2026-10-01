extends SceneTree
const E=preload("res://scripts/expedition.gd")
const Copy=preload("res://scripts/upgrade_copy.gd")
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1
	print("PASS / " if ok else "FAIL / ",msg)
func game(hero=2,research={}):
	var g=E.new();g.setup(hero,"expedition",research,808);return g
func equip(g,id,rank=1):g.weapons[id]={"level":rank,"evolved":false,"timer":0.0}
func _initialize():
	var g=game()
	g.weapons={};equip(g,"lightning");equip(g,"fire");equip(g,"thorns")
	check(Copy.affected(g,{"type":"passive","id":"area"})==["fire","thorns"],"Area icons match area-tagged gear")
	check(Copy.affected(g,{"type":"augment","id":"conductor"})==["lightning"],"Chain upgrade affects Stormbinder only")
	check(Copy.affected(g,{"type":"passive","id":"armor"})==["thorns"],"Armor explicitly affects Ironbriar")
	check(Copy.affected(g,{"type":"augment","id":"ward"}).is_empty(),"Shield upgrades do not falsely improve thorns")
	for rank in [1,4,5,9,10]:
		g.weapons.lightning.level=rank
		check(g.Rules.stats(g,"lightning").count==3+int(rank>=5)+int(rank>=10),"Stormbinder chain milestone / %s"%rank)
	g=game();g.weapons={};equip(g,"frost",10);equip(g,"lightning",1)
	check({"type":"fusion","id":"whiteout"} not in g.Evolutions.ready(g),"Rank-one partner cannot merge")
	g.weapons.lightning.level=10
	check({"type":"fusion","id":"whiteout"} in g.Evolutions.ready(g),"Both max weapons merge")
	g.weapons.erase("lightning");check({"type":"evolution","id":"frost"} in g.Evolutions.ready(g),"Max weapon evolves without passive requirements")
	g.weapons.frost.level=9;check(g.Evolutions.ready(g).is_empty(),"Rank nine does not evolve")
	g=game(1);g.weapons={};equip(g,"thorns")
	var before=g.Rules.stats(g,"thorns").power;g.armor+=10
	check(g.Rules.stats(g,"thorns").power>before,"Armor increases thorn damage")
	g.armor=25;before=g.Rules.stats(g,"thorns").power;g.armor=100
	check(is_equal_approx(g.Rules.stats(g,"thorns").power,before),"Thorns armor conversion is bounded")
	var target=g.spawn_enemy(false,Vector2(75,0),0,false);target.hp=10000;g.build_grid()
	g.update_weapons(0.1);check(target.hp<10000,"Thorns attacks without taking damage")
	before=target.hp;g.invul=0;g.hurt(20,"test");check(target.hp<before,"Incoming hit triggers retaliation")
	before=target.hp;g.invul=0;g.hurt(20,"test");check(target.hp==before,"Retaliation cooldown prevents hit spam")
	g.weapons.thorns.level=10;equip(g,"club",10)
	check({"type":"fusion","id":"thornking"} in g.Evolutions.ready(g),"Thorn union needs both max weapons")
	check(g.Rules.can_add_weapon(g.weapons,g.C.WEAPONS,"winter"),"Thorns leaves aura slot available")
	g=game(0,{"vitality":2,"reroll":3,"power":2,"greed":2,"luck":4,"projectiles":2,"chains":1,"revive":1,"growth":3,"magnet":4,"armor":2,"recovery":2})
	check(g.max_hp==130 and g.armor==3 and g.rerolls==6,"Permanent health armor rerolls applied")
	check(is_equal_approx(g.fortune,1.1) and is_equal_approx(g.permanent_luck,0.04),"Luck and amber research are separate")
	check(g.Rules.stats(g,"revolver").count==3,"Permanent projectiles applied")
	equip(g,"lightning");check(g.Rules.stats(g,"lightning").count==4,"Permanent chains applied separately")
	g.hurt(10000,"test");check(g.active and g.hp==g.max_hp*0.5 and g.revives==0,"Cheat death revives once")
	g.invul=0;g.buffs.immune=0;g.hurt(10000,"test");check(not g.active,"Second lethal hit ends run")
	for hero in range(5):
		g=game(hero);var initial=g.damage_scale(g.C.HEROES[hero].weapon);var initial_speed=g.speed();var initial_stats=g.Rules.stats(g,g.C.HEROES[hero].weapon)
		g.level=31
		match hero:
			0: check(g.Rules.stats(g,"revolver").count==initial_stats.count+3,"Voss level projectile bonus capped at three")
			1: check(g.damage_scale("club")>initial,"Kael gains physical damage")
			2: check(g.damage_scale("lightning")>initial,"Vesper gains spell damage")
			3: check(g.speed()>initial_speed,"Iona gains movement")
			4: check(g.Rules.stats(g,"lantern").cooldown<initial_stats.cooldown,"Orin gains arcane attack speed")
		check(g.trait_text().length()>10,"Visible trait text / %s"%hero)
	for seed_value in [808,809,810,811,812]:
		g=E.new();g.setup(0,"daily",{"power":99,"revive":99},seed_value)
		check(g.research_ranks.is_empty() and g.revives==0,"Daily ignores research / %s"%seed_value)
		for level in range(2,61):
			g.level=level;g.open_choices(false);g.choose(0)
			if level%8==0:g.open_choices(true);g.choose(0)
		check(not g.choosing and g.weapons.size()<=5,"Automatic daily build stays within slots / %s"%seed_value)
		check(g.Daily.plan(seed_value)==g.daily_plan,"Daily gear is deterministic / %s"%seed_value)
	g=game();g.Breakables.update(g,1)
	var props=g.enemies.filter(func(e):return e.get("breakable",false));check(props.size()>0 and props.size()<=20,"Breakables spawn with a bound")
	var before_count=props.size();g.Breakables.update(g,1);check(g.enemies.size()==before_count,"Visited districts do not duplicate props")
	var drops={}
	for i in range(1000):
		g.pickups.clear();var e=g.spawn_enemy(false,Vector2(80,0),4,false);e.breakable=true;g.kill(e)
		var id=g.pickups[0].id;drops[id]=drops.get(id,0)+1
	check(g.kills==0 and g.gems.is_empty(),"Props give no kill credit or XP")
	check(drops.amber>drops.heal and drops.heal>drops.magnet,"Amber more common than health, health more than magnets")
	check(drops.amber>620 and drops.amber<780,"Amber drop frequency near 70 percent")
	g=game();g.weapons={};equip(g,"mortar");var e=g.spawn_enemy(false,Vector2(250,0),0,false);e.hp=10000;g.build_grid();g.update_weapons(0.1)
	check(g.hazards.size()>0 and g.hazards[0].launch==Vector2.ZERO,"Mortar shell launches at player")
	g.update_hazards(0.3);check(e.hp==10000,"Mortar does not hit before landing")
	g.update_hazards(0.5);check(e.hp<10000,"Mortar explodes at landing")
	g=game();g.spawn_boss(1);e=g.spawn_enemy(false,g.boss.p,0,false);var p=g.crowd.finish_move(g,e,Vector2i.ZERO,Vector2.ZERO)
	check(p.distance_to(g.boss.p)>=g.boss.size,"Small mobs are displaced outside boss body")
	print("POLISH 08 / %s checks / %s failures"%[checks,failures]);quit(1 if failures else 0)
