extends SceneTree
const E = preload("res://scripts/expedition.gd")
const D = preload("res://scripts/discoveries.gd")
const Ledger = preload("res://scripts/combat_ledger.gd")
var count = 0
var failures = 0
func check(ok,text):
	count += 1
	print("PASS / " if ok else "FAIL / ",text)
	if not ok: failures += 1
func game():
	var g = E.new()
	g.setup(2,"expedition",{},6133)
	return g
func _initialize():
	var save = {"amber":500,"runs":0,"records":[],"research":{"power":3}}
	D.migrate(save)
	check(D.hero_open(save,2) and not D.hero_open(save,0),"Fresh profile starts with mage")
	check(not D.purchase(save,"mara") and save.amber==500,"Cannot buy undiscovered content")
	save.discoveries.append("mara")
	check(D.purchase(save,"mara") and save.amber==320 and D.hero_open(save,0),"Discover then buy survivor with amber")
	check(not D.purchase(save,"mara") and save.amber==320,"Cannot buy same unlock twice")
	var old = {"amber":8247,"runs":1,"wins":1,"records":[],"research":{"power":5}}
	D.migrate(old)
	check(old.amber==8247 and old.research.power==5 and old.wins==1,"Migration preserves currency, wins and research")
	check(D.allowed(old,"weapons","mortar") and D.hero_open(old,0),"Returning players keep original catalog and survivors")
	check(not D.allowed(old,"weapons","ricochet") and not D.allowed(old,"weapons","return"),"New gear remains discoverable for returning players")
	var g = game()
	g.configure_content(save)
	var locked = g.upgrade_pool()
	check(not locked.any(func(o):return o.type=="weapon" and o.id=="mortar"),"Locked weapons do not leak into offers")
	check(not locked.any(func(o):return o.type=="augment" and o.id=="homing"),"Locked augments do not leak into offers")
	var signals = []
	g.discovered_content.connect(func(id):signals.append(id))
	g.pos = g.landmarks.filter(func(marker):return marker.id=="ballistics")[0].p
	g.update_exploration()
	g.update_exploration()
	check(signals.size()==1 and "ballistics" in g.discovered,"Exploration records each discovery once")
	check(g.explored[0].size()>10 and g.explored[1].is_empty(),"Fog is revealed locally and independently per biome")
	check(not g.content_allowed("weapons","mortar"),"Discovery alone does not grant unpurchased equipment")
	for depth in range(3):
		g = game()
		g.depth = depth
		g.relics = ["flint","wrap","coil","lens","blood","shell","boots","magnet"]
		g.open_choices(true)
		check(g.choosing and g.option_is_relic and g.options.size()==1,"Full satchel retains one reel in biome "+str(depth+1))
		check(is_equal_approx(g.relic_state.chest_odds.reduce(func(a,b):return a+b,0.0),100.0),"Chest odds sum to 100 in biome "+str(depth+1))
		var before = g.relics.size()
		g.choose(0)
		check(g.relics.size()==before,"Full-satchel reward cannot exceed eight relics")
	g = game()
	g.relics = ["wrap"]
	g.max_hp += 20
	g.hp = g.max_hp
	g.Relics.modifiers(g)
	g.options = [{"type":"relic","id":"flint","replace":"wrap"}]
	g.choosing = true
	g.choose(0)
	check(g.max_hp==85 and g.hp<=g.max_hp and g.Relics.modifiers(g).damage>0,"Replacing relic removes old health and invalidates cached modifiers")
	g = game()
	g.relics = ["blood"]
	g.hp = 10
	for i in range(300):
		var e = g.spawn_enemy(false,Vector2(500,500),0,false)
		g.kill(e)
	check(is_equal_approx(g.hp,14),"300 simultaneous kills heal only once")
	g.time = 2
	for i in range(30): g.kill(g.spawn_enemy(false,Vector2(500,500),0,false))
	check(is_equal_approx(g.hp,18),"Chalice becomes available again after two seconds")
	g = game()
	g.time = 720
	for i in range(100):
		var e = g.spawn_enemy(true,Vector2(500,500),0,false)
		e.event_spawn = true
		g.kill(e)
	check(g.relic_chests.size()<=1,"Invasion mutations share a chest cooldown")
	g = game()
	for i in range(8): g.kill(g.spawn_enemy(true,Vector2(500,500),0,false))
	check(g.relic_chests.size()==4,"Uncollected relic boxes stay capped at four")
	g = game()
	g.weapons = {"return":{"level":1,"evolved":false,"timer":0}}
	var e = g.spawn_enemy(false,Vector2(100,0),0,false)
	e.hp = 10000
	g.build_grid()
	g.shoot("return",Vector2.ZERO,Vector2.RIGHT,10,440,2.2,8)
	for i in range(45): g.update_shots(1.0/60)
	check(g.shots.size()==1 and g.shots[0].returning and g.shots[0].v.x<0,"Sun Chaser reverses toward the moving survivor")
	for i in range(60): g.update_shots(1.0/60)
	check(g.shots.is_empty() and e.hp<9985,"Returning blade hits both passes and is caught")
	g = game()
	g.weapons = {"return":{"level":10,"evolved":true,"timer":0}}
	g.augments = {"pierce":2,"homing":3}
	g.shoot("return",Vector2.ZERO,Vector2.RIGHT,20,440,2.2,8)
	check(g.shots[0].pierce==10,"Pierce augment increases Sun Chaser penetration")
	g.shots[0].age = 0.7
	g.shots[0].p = Vector2(300,0)
	g.shots[0].target = g.spawn_enemy(false,Vector2(600,300),0,false)
	g.update_shots(0.01)
	check(g.shots[0].v.x<0 and is_zero_approx(g.shots[0].v.y),"Homing cannot steer a returning crescent away from its owner")
	check(is_equal_approx(g.shots[0].damage,25) and g.shots[0].pierce==10,"Second Dawn's return hits 25 percent harder and retains penetration upgrades")
	check(not g.Rules.eligible({"ricochet":{}},g.C.WEAPONS,g.C.AUGMENTS.pierce.filter),"Prism Skipper cannot roll an ineffective Pierce augment")
	g = game()
	g.weapons = {"ricochet":{"level":1,"evolved":false,"timer":0}}
	g.shoot("ricochet",Vector2.ZERO,Vector2.RIGHT,20,570,1.6,1)
	check(g.shots[0].bounce==2,"Prism Skipper has innate ricochets")
	for i in range(100): g.shoot("ricochet",Vector2.ZERO,Vector2.RIGHT,20,570,1.6,1)
	check(g.shots.size()==60,"Per-weapon active projectile cap is enforced")
	g = game()
	g.weapons.frost = {"level":10,"evolved":true,"timer":0}
	g.shoot("frost",Vector2.ZERO,Vector2.RIGHT,20,460,1.5,3)
	check(g.shots[0].homing>=2,"Evolved Winterglass's promised seeking affects actual projectiles")
	g.weapons = {"whiteout":{"level":10,"evolved":true,"timer":0}}
	g.spawn_enemy(false,Vector2(200,0),0,false)
	g.build_grid()
	g.update_weapons(0.1)
	check(g.shots.filter(func(s):return s.id=="whiteout").size()==3,"Whiteout's secondary lances survive non-projectile weapon caps")
	g = game()
	g.weapons.fire = {"level":10,"evolved":true,"timer":0}
	g.passives = {"damage":5,"area":5,"haste":5,"count":3}
	g.augments = {"sorcery":4,"linger":3}
	var stats = g.Rules.stats(g,"fire")
	check(stats.count<=12 and stats.radius<=300 and stats.duration<=5,"Endgame size, count and lingering duration are capped")
	g.spawn_enemy(false,Vector2(200,0),0,false)
	g.build_grid()
	g.update_weapons(0.01)
	check(g.volleys.size()>0,"Multi-shot volleys stagger shots instead of spawning an opaque fan")
	var l = Ledger.new()
	l.cast("frost",10)
	l.record("frost",500,11)
	l.record("frost",100,12)
	check(is_equal_approx(l.recent("frost",12),120),"Five-second DPS measures effective damage")
	l.retired.frost = 16
	check(is_equal_approx(l.average("frost",100),100),"Union history average stops when weapon is retired")
	check(is_zero_approx(l.recent("frost",100)),"Old damage leaves rolling DPS window")
	for i in range(500): l.record("fire",1,i)
	check(l.buckets.fire.size()<=6,"Telemetry memory stays bounded")
	g = game()
	g.armor = 100
	g.hurt(30,"collapse",true)
	check(is_equal_approx(g.hp,55),"Collapse damage ignores flat armor")
	print("PATCH 06 / ",count," checks / ",failures," failures")
	quit(failures)
