extends SceneTree
const E = preload("res://scripts/expedition.gd")
var failures = 0
var checks = 0
func check(ok,message):
	checks += 1
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures += 1
func game():
	var g = E.new()
	g.setup(2,"expedition",{},923)
	g.terrain.arena = Vector2.ZERO
	return g
func _initialize():
	var g = game()
	check(g.weapons.has("lightning"),"Mage starts with Stormbinder")
	for id in g.Evolutions.UNIONS:
		g = game()
		g.weapons.clear()
		for part in g.Evolutions.UNIONS[id].parts: g.weapons[part] = {"level":10,"evolved":true,"timer":0}
		g.open_choices(true)
		check(g.options[0].type=="fusion" and g.options[0].id==id,"Chest guarantees eligible union / "+id)
		g.choose(0)
		check(g.weapons.size()==1 and g.weapons.has(id),"Union consumes two weapons and frees exactly one slot / "+id)
		for trial in range(10):
			g.choosing = false
			g.open_choices(false)
			check(g.options.all(func(o):return o.type!="weapon" or (not g.C.WEAPONS[o.id].get("fusion",false) and o.id not in g.Evolutions.UNIONS[id].parts)),"Offers cannot duplicate a union or its consumed ingredients")
	g = game()
	g.weapons.frost = {"level":9,"evolved":false,"timer":0}
	g.weapons.lightning.level = 9
	check(g.Evolutions.ready(g).is_empty(),"Rank IX cannot prematurely fuse")
	g.weapons = {"whiteout":{"level":10,"evolved":true,"timer":0}}
	var e = g.spawn_enemy(false,Vector2(100,0),0)
	e.hp = 100000
	g.build_grid()
	g.hit(e,100,"whiteout",false)
	g.hit(e,100,"whiteout",false)
	check(e.frozen>0,"Whiteout freezes lesser enemies")
	g.hit(e,100,"whiteout",false)
	check(g.proc_queue.size()==1,"Whiteout detonates frozen prey")
	g.Relics.update(g,0.01)
	check(g.proc_queue.is_empty(),"Whiteout detonation cannot recursively spawn detonations")
	g = game()
	var normal = g.Relics.odds(g)
	check(absf(normal.reduce(func(a,b):return a+b,0.0)-100)<0.001,"Displayed chest odds total 100 percent")
	g.passives.luck = 5
	var lucky = g.Relics.odds(g)
	check(lucky[4]>normal[4] and lucky[5]>normal[5] and lucky[0]<normal[0],"Luck improves Legendary and Artifact odds, reducing Common")
	g.permanent_luck = 0.25
	check(g.Relics.odds(g)[5]>lucky[5],"Permanent Fortune further improves rarity odds")
	g.relic_state.dry_chests = 4
	var pity = g.Relics.odds(g)
	check(pity[0]==0 and pity[1]==0,"Displayed odds include fifth-chest Rare guarantee")
	g = game()
	e = g.spawn_enemy(true,Vector2(160,0),0)
	g.kill(e)
	g.kill(e)
	check(g.relic_chests.size()==1 and not g.choosing,"Mini-boss drops exactly one collectable chest")
	g.pos = g.relic_chests[0]
	g.update_objectives(0.01)
	check(g.choosing and g.option_is_relic and g.relic_chests.is_empty(),"Walking over mini-boss chest opens the reward reel")
	g = game()
	g.pos = Vector2(-160,-100)
	g.terrain.update(1,g.pos)
	e = g.spawn_enemy(false,Vector2(160,100),0)
	var old = e.p
	g.update_enemies(1.0/30)
	check(e.p.x<old.x and e.p.y<old.y,"Enemy moves diagonally toward player in open ground")
	g = game()
	g.pos = Vector2(-200,0)
	for i in range(24): g.spawn_enemy(false,Vector2(150,0),0)
	for frame in range(180):
		g.terrain.update(1.0/30,g.pos)
		g.update_enemies(1.0/30)
	var worst = 0
	for a in g.enemies:
		var close = 0
		for b in g.enemies:
			if a.uid!=b.uid and a.p.distance_to(b.p)<10: close += 1
		worst = maxi(worst,close)
	check(worst<4,"Overlapping spawn pack separates into bodies instead of a single stack; worst neighbours="+str(worst))
	g = game()
	e = g.spawn_enemy(false,Vector2(90,0),0)
	e.hp = 100000
	e.frozen = 10
	old = e.p
	g.build_grid()
	g.weapons = {"club":{"level":5,"evolved":true,"timer":0}}
	for frame in range(60):
		g.update_enemies(1.0/30)
		g.update_weapons(1.0/30)
	check(e.p==old,"Frozen enemies remain rooted through AI movement and melee knockback")
	e.frozen = 0
	g.update_enemies(1.0/30)
	check(e.p!=old,"Thawed enemy resumes movement")
	print("UNIONS 05 / ",checks," checks / ",failures," failures")
	quit(failures)
