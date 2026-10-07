extends SceneTree
const E=preload("res://scripts/expedition.gd")
const D=preload("res://scripts/discoveries.gd")
const P=preload("res://scripts/campaign.gd")
const M=preload("res://scripts/expedition_maps.gd")
var failures=0
var checks=0
func check(ok,message):
	checks+=1
	if not ok: failures+=1
	print("PASS / " if ok else "FAIL / ",message)
func _initialize():
	var profile={"runs":0,"amber":0,"records":[]}
	D.migrate(profile);P.ensure(profile)
	for hero in range(5):
		var g=E.new();g.setup(hero,"expedition",{},707);g.configure_content(profile)
		for id in D.KITS[hero]: check(g.content_allowed("weapons",id),"Starter kit allowed / %s / %s"%[hero,id])
		check(g.weapons.has(g.C.HEROES[hero].weapon),"Starter equipped / %s"%hero)
	check(not M.available(profile,"frostbreak"),"New maps initially locked")
	check(not D.allowed(profile,"weapons","glacier") and not D.allowed(profile,"weapons","sunbow"),"New weapons gated")
	profile.campaign.kills=250
	check("map_frost" in P.evaluate(profile) and M.available(profile,"frostbreak"),"250 kills opens Frostbreak")
	check(P.evaluate(profile).is_empty(),"Milestones grant only once")
	profile.campaign.bosses=1
	check("map_observatory" in P.evaluate(profile),"First boss opens Observatory")
	profile.campaign.map_kills.frostbreak=1000
	check("glacier" in P.evaluate(profile),"Map kills unlock Glacier Wheel")
	profile.campaign.map_kills.observatory=1500
	check("sunbow" in P.evaluate(profile),"Map kills unlock Helios Repeater")
	var restored=JSON.parse_string(JSON.stringify(profile))
	check(P.evaluate(restored).is_empty() and M.available(restored,"observatory"),"Serialized progression remains idempotent")
	var signatures=[]
	for map in M.DATA:
		var g=E.new();g.setup(2,"expedition",{},707,map);g.configure_content(profile)
		var signature=""
		for x in range(-16,17):
			for y in range(-16,17): signature+=str(g.terrain.kind(Vector2i(x,y)))
		signatures.append(hash(signature))
		for marker in g.landmarks:
			var reachable=true
			var distance=g.stage.spawn.distance_to(marker.p)
			for step in range(ceili(distance/64.0)+1):
				var point=g.stage.spawn.lerp(marker.p,minf(1,step*64.0/maxf(1,distance)))
				if not g.terrain.walkable(point,15):reachable=false;break
			check(reachable,"Authored route reaches discovery / %s / %s"%[map,marker.id])
		for depth in range(3):
			var pool=M.pool(map,depth,300)
			var habitat={"cradle":"grasslands","frostbreak":"frost","observatory":"jungle"}[map]
			check(4 not in pool and pool.all(func(kind):return g.Bestiary.DATA[kind].habitat==habitat),"Distinct biome dinosaurs; Compys event-only / %s / %s"%[map,depth])
			check(M.biome(map,depth).name.length()>0,"Named biome / %s / %s"%[map,depth])
		g.spawn_boss(1);g.kill(g.boss)
		check(g.campaign_bosses==1,"Boss kill recorded / "+map)
	check(signatures[0]!=signatures[1] and signatures[1]!=signatures[2],"Maps have distinct collision layouts")
	for id in ["harpoon","lantern","glacier","sunbow"]:
		var g=E.new();g.setup(2,"expedition",{},707)
		g.weapons={id:{"level":10,"evolved":false,"timer":0}}
		var target=g.spawn_enemy(false,Vector2(150,0),0,false)
		target.hp=100000;target.max_hp=100000;target.boss=true
		g.build_grid()
		for i in range(300):
			g.time+=1.0/30;g.update_weapons(1.0/30);g.update_shots(1.0/30)
		check(g.damage_total>100,"New weapon deals damage / "+id)
		g.passives[g.C.WEAPONS[id].requires]=2
		check({"type":"evolution","id":id} in g.Evolutions.ready(g),"Evolution offered at correct combination / "+id)
		g.open_choices(true)
		g.choose(0)
		check(g.weapons[id].evolved,"Chest evolves new weapon / "+id)
	print("FRONTIERS 07 / ",checks," checks / ",failures," failures")
	quit(failures)
