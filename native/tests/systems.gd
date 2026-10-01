extends SceneTree
const E = preload("res://scripts/expedition.gd")
const C = preload("res://scripts/catalog.gd")
const R = preload("res://scripts/combat_rules.gd")
const P = preload("res://scripts/world_pickups.gd")
const Chain = preload("res://scripts/chain_system.gd")
var checks = 0
var failures = 0
func check(ok,message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL / ",message)
	else: print("PASS / ",message)
func game():
	var g = E.new()
	g.setup(0,"expedition",{},2143)
	return g
func _initialize():
	for group in [C.WEAPONS,C.RELICS,C.PASSIVES,C.AUGMENTS]:
		for id in group: check(not group[id].tags.is_empty(),"Tagged content / "+id)
	var g = game()
	check(not R.eligible({"club":{}},C.WEAPONS,C.AUGMENTS.velocity.filter),"Sword cannot roll projectile velocity")
	check(not R.eligible({"aegis":{}},C.WEAPONS,C.PASSIVES.count.filter),"Shield cannot roll projectile count")
	check(not R.eligible({"fire":{}},C.WEAPONS,C.AUGMENTS.pierce.filter),"Detonating projectiles cannot roll ineffective piercing")
	g = game()
	g.augments = {"velocity":1,"pierce":2,"homing":1,"bounce":1}
	var projectile_stats = R.stats(g,"revolver")
	check(projectile_stats.velocity>800 and projectile_stats.pierce==3,"Projectile speed and pierce change actual attack stats")
	var spent = g.spawn_enemy(false,Vector2(60,-22),0)
	var fresh = g.spawn_enemy(false,Vector2(100,100),0)
	g.build_grid()
	g.shoot("revolver",Vector2.ZERO,Vector2.RIGHT,1,100,2,3)
	g.shots[0].hit.append(spent.uid)
	g.update_shots(0.1)
	check(g.shots[0].target==fresh and g.shots[0].v.y>0,"Homing bends toward prey it has not already pierced")
	g = game()
	g.augments = {"bounce":1}
	var first = g.spawn_enemy(false,Vector2(50,0),0)
	g.spawn_enemy(false,Vector2(110,110),0)
	g.build_grid()
	g.shoot("revolver",Vector2.ZERO,Vector2.RIGHT,1,100,2,1)
	g.update_shots(0.6)
	check(not g.shots.is_empty() and g.shots[0].bounce==0 and g.shots[0].v.y>0,"Spent projectile ricochets toward another target")
	for id in C.WEAPONS:
		g = game()
		g.weapons = {id:{"level":10,"evolved":true,"timer":0.0}}
		var e = g.spawn_enemy(false,Vector2(80,0),0)
		if C.WEAPONS[id].delivery=="orbital": e.p = Vector2(R.stats(g,id).radius,0)
		e.hp = 100000
		e.max_hp = 100000
		g.build_grid()
		for j in range(180):
			g.time += 1.0/60
			g.update_weapons(1.0/60)
			g.update_shots(1.0/60)
			g.update_hazards(1.0/60)
		var worked = e.hp<100000
		if C.WEAPONS[id].delivery=="shield": worked = g.shield>0
		if C.WEAPONS[id].delivery=="utility": worked = g.buffs.get("freeze",0)>0
		check(worked,"Integrated combat behavior / "+id)
	g = game()
	g.weapons = {"aegis":{"level":1,"evolved":false,"timer":0.0}}
	for i in range(40):
		g.choosing = false
		g.open_choices(false)
		for o in g.options:
			if o.type=="augment": check(R.matches(C.WEAPONS.aegis.tags,C.AUGMENTS[o.id].filter),"Compatible defensive offers")
	g = game()
	g.weapons.revolver.level = 10
	g.passives.crit = 2
	var offered = false
	for i in range(30):
		g.choosing = false
		g.open_choices(true)
		for o in g.options:
			if o.id=="revolver" and o.type=="evolution": offered = true
	check(offered,"Rank ten retains chest evolution opportunity")
	g = game()
	for i in range(12): g.spawn_enemy(false,Vector2(100+i*25,0),0).hp=100000
	g.build_grid()
	var n = Chain.cast(g,Vector2.ZERO,10,"lightning",7,150,0.85,0.5,0.2)
	check(n>=7 and n<=10 and g.strikes.size()==n,"Bounded branching chaining with visible links")
	g = game()
	var e = g.spawn_enemy(false,Vector2(100,0),0)
	g.build_grid()
	P.activate(g,"freeze")
	var before = e.p
	g.update_enemies(1)
	check(e.p==before,"Time pickup freezes ordinary enemies")
	g.spawn_boss(1)
	var boss_before = g.boss.p
	g.update_boss(1)
	check(g.boss.p!=boss_before,"Boss resists time stop")
	g = game()
	g.add_gem(Vector2(800,0),50)
	g.pickups.append({"id":"heal","p":Vector2(700,0),"life":60.0,"magnet":false})
	P.activate(g,"magnet")
	check(g.gems[0].magnet and not g.pickups[0].magnet,"Magnet attracts XP and leaves world pickups")
	g.hp = 10
	P.activate(g,"heal")
	check(g.hp>40,"Healing pickup")
	P.activate(g,"immune")
	before = g.hp
	g.hurt(90,"test")
	check(g.hp==before,"Immunity pickup")
	g = game()
	g.spawn_boss(1)
	var normal = g.spawn_enemy(false,Vector2(50,0),0)
	g.build_grid()
	before = g.boss.hp
	P.activate(g,"nuke")
	check(normal.dead and g.boss.hp>before*0.97,"Nuke kills normal foes without trivializing boss")
	g = game()
	g.shield = 30
	g.hurt(20,"test")
	check(g.hp==g.max_hp and g.shield==10,"Barrier absorbs damage")
	P.activate(g,"frenzy")
	check(R.stats(g,"revolver").cooldown<C.WEAPONS.revolver.cooldown/1.5,"Frenzy changes attack cadence")
	P.activate(g,"surge")
	g.add_gem(g.pos,10)
	g.update_gems(0.1)
	check(g.xp==20,"XP surge multiplier")
	g = game()
	g.relics = ["shatter","reaper","garden","momentum","apex"]
	g.weapons.winter = {"level":8,"evolved":false,"timer":0}
	var victim = g.spawn_enemy(false,Vector2(60,0),0)
	victim.frozen = 2
	victim.last_critical = true
	g.weapons.revolver.timer = 2
	g.kill(victim)
	check(g.proc_queue.size()==1 and g.weapons.revolver.timer<2 and g.relic_state.get("aura_growth",0)>0,"Shatter, critical cooldown and aura growth interact")
	g.velocity = Vector2(100,0)
	g.Relics.update(g,8)
	check(g.relic_state.momentum==8,"Movement momentum reaches cap")
	g.spawn_boss(1)
	before = g.max_hp
	g.kill(g.boss)
	check(g.max_hp==before+20 and g.base_damage>1,"Boss relic grants lasting in-run growth")
	g = game()
	g.relics = ["volley","cyclone","laststand","branch"]
	var cast_stats = R.stats(g,"revolver")
	var original_count = cast_stats.count
	g.Relics.on_cast(g,C.WEAPONS.revolver,5,cast_stats)
	check(cast_stats.count==original_count+5,"Fifth projectile attack gains spread")
	g.weapons.club = {"level":1,"evolved":false,"timer":0.0}
	cast_stats = R.stats(g,"club")
	g.Relics.on_cast(g,C.WEAPONS.club,3,cast_stats)
	check(cast_stats.arc==TAU,"Third melee attack becomes full-circle")
	before = R.stats(g,"club").cooldown
	g.hp = 10
	check(R.stats(g,"club").cooldown<before/1.4,"Low-health relic increases cadence")
	g.weapons.lightning = {"level":1,"evolved":false,"timer":0.0}
	check(R.stats(g,"lightning").fork>=0.3,"Chain relic supplies generic fork modifier")
	g = game()
	g.relics = ["reaper"]
	g.weapons.revolver.timer = 2
	for i in range(20):
		var v = g.spawn_enemy(false,Vector2(80,0),0)
		v.last_critical = true
		g.kill(v)
	check(is_equal_approx(g.weapons.revolver.timer,1.85),"Critical cooldown relic cannot reset all weapons in one mass kill")
	g = game()
	g.relics = C.RELICS.keys().slice(0,8)
	g.open_choices(true)
	check(g.choosing and g.option_is_relic and g.options.size()==1,"Full eight-relic satchel keeps a single RNG chest reward")
	g = game()
	var poison_target = g.spawn_enemy(false,Vector2(80,0),0)
	poison_target.hp=10000
	poison_target.max_hp=10000
	for i in range(8): g.hit(poison_target,10,"miasma",false)
	check(poison_target.poison==6,"Toxic aura stacks are bounded")
	before=poison_target.hp
	g.update_enemies(0.6)
	check(poison_target.hp<before and g.damage_by_weapon.miasma>80,"Poison ticks damage and retains source attribution")
	var burning = g.spawn_enemy(false,Vector2(90,0),0)
	burning.hp=10000
	g.hit(burning,10,"fire",false)
	for i in range(8): g.update_enemies(0.5)
	check(burning.burn==0,"Damage-over-time cannot refresh itself forever")
	g = game()
	var t = g.terrain
	check(t.walkable(Vector2.ZERO),"Safe starting clearing")
	var wall = t.center(Vector2i(5,5))
	check(not t.walkable(wall),"Terrain blocks movement")
	var moved = t.move(wall-Vector2(80,0),Vector2(160,0))
	check(moved.x<wall.x-30,"Fast movement cannot tunnel through wall")
	t.update(1,Vector2.ZERO)
	var route = wall+Vector2(110,0)
	for i in range(1200): route = t.move(route,t.direction(route,Vector2.ZERO)*2,10)
	check(route.length()<70,"Shared navigation routes around solid terrain")
	var connected = true
	for x in range(-14,15):
		for y in range(-14,15):
			var c = Vector2i(x,y)
			if t.kind(c)!=1 and not t.flow.has(c): connected=false
	check(connected,"Designed terrain has no isolated walkable pockets")
	var flyer = g.spawn_enemy(false,wall-Vector2(20,0),2)
	check(flyer.p==wall-Vector2(20,0),"Flyers can spawn across obstacle geometry")
	g = game()
	g.time = 415
	g.director.update(g,0.01)
	var hungry_index = -1
	for i in range(g.director.EVENTS.size()):
		if g.director.EVENTS[i].at==420: hungry_index = i
	check(g.director.warned.has(hungry_index) and g.director.current.is_empty(),"Seven-minute horde warns five seconds early")
	g.time = 420
	g.director.update(g,0.1)
	check(g.director.current.cap==2200 and g.enemies.size()>0 and g.enemies[0].event_spawn,"Seven-minute horde spawns weak mass enemies")
	for at in [150,720]:
		g.time = at
		g.director.update(g,0.1)
		check(g.director.current.at==at,"Scheduled event at %ss"%at)
	for stage in [1,2,3]:
		g = game()
		g.time = stage*300-0.01
		g.next_boss = stage*300
		g.boss_stage = stage-1
		g.tick(0.02,Vector2.ZERO)
		check(g.boss_stage==stage and g.boss!=null,"Boss timing %s:00"%(stage*5))
	g = game()
	g.spawn_boss(2)
	g.hit(g.boss,100000000,"revolver",false)
	check(g.boss!=null and g.phase==2 and g.boss.hp==g.boss.max_hp*0.5,"Basalt carapace prevents burst from skipping its second phase")
	g.update_boss(0.01)
	check(g.hazards.size()>=2 and g.hazards.size()<=4 and g.boss.reform>0,"Basalt phase break telegraphs one readable pattern during temporary armor")
	# Worst-case swarm, no damage, 2200 ground enemies and full navigation.
	g = game()
	g.time = 425
	g.next_boss = 600
	g.weapons.clear()
	g.director.update(g,0)
	for i in range(2200): g.spawn_enemy(false,Vector2.from_angle(i*2.399)*float(100+i%850),4)
	var start = Time.get_ticks_usec()
	var worst = 0
	for i in range(120):
		g.invul = 10
		var frame = Time.get_ticks_usec()
		g.tick(1.0/60,Vector2.RIGHT)
		worst = maxi(worst,Time.get_ticks_usec()-frame)
	var elapsed = (Time.get_ticks_usec()-start)/120000.0
	print("HORDE BENCH / ",g.enemies.size()," enemies / mean ",elapsed," ms / worst ",worst/1000.0," ms; simulation only")
	check(g.enemies.size()<=2200 and g.peak_enemies==2200,"Horde population remains bounded")
	print("SYSTEMS RESULT / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
