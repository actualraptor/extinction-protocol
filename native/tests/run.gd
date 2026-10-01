extends SceneTree

const Expedition = preload("res://scripts/expedition.gd")
const C = preload("res://scripts/catalog.gd")
var checks = 0
var failures = 0

func check(condition,text):
	checks += 1
	if condition: print("PASS / ",text)
	else:
		failures += 1
		printerr("FAIL / ",text)

func game(hero = 0,mode = "expedition"):
	var g = Expedition.new()
	g.setup(hero,mode,{},9127)
	return g

func _initialize():
	for i in range(3):
		var g = game(i)
		check(g.weapons.has(C.HEROES[i].weapon) and g.hp==C.HEROES[i].hp,"Character identity %s"%i)
	var a = game()
	var b = game()
	for i in range(25):
		a.spawn_enemy()
		b.spawn_enemy()
	check(a.enemies[15].p==b.enemies[15].p,"Seeded enemy placement")
	a.tick(1.0/60,Vector2.RIGHT)
	check(a.pos.x>0,"Movement")
	check(a.effective_damage(999,5)==5,"Damage stats exclude overkill")
	var daily = Expedition.new()
	daily.setup(0,"daily",{"vitality":5,"power":5},1)
	check(daily.max_hp==C.HEROES[daily.hero].hp and daily.base_damage==1,"Daily ignores permanent combat upgrades")
	var g = game()
	var e = g.spawn_enemy(false,Vector2(30,0),0)
	g.build_grid()
	g.hit(e,10000,"revolver",false)
	check(g.kills==1 and g.gems.size()==1 and g.damage_total==e.max_hp,"Kill and XP drop with accurate damage")
	g.update_gems(1)
	check(g.xp>0,"XP magnet pickup")
	for id in C.WEAPONS:
		if C.WEAPONS[id].delivery in ["shield","utility"]: continue
		g = game()
		g.weapons = {id:{"level":10,"evolved":true,"timer":0.0}}
		var target_radius = g.Rules.stats(g,id).radius if C.WEAPONS[id].delivery=="orbital" else 75.0
		e = g.spawn_enemy(false,Vector2(target_radius,0),0)
		e.hp = 100000
		e.max_hp = 100000
		g.build_grid()
		for j in range(180):
			g.time += 1.0/60
			g.update_weapons(1.0/60)
			g.update_shots(1.0/60)
			g.update_hazards(1.0/60)
		check(e.hp<100000,"Weapon damage / "+id)
	g = game()
	g.weapons.revolver.level = 8
	g.passives.crit = 2
	g.choosing = true
	g.options = [{"type":"evolution","id":"revolver"}]
	g.choose(0)
	check(g.weapons.revolver.evolved and not g.choosing,"Evolution applies and unpauses")
	g = game()
	g.relics.append("clock")
	g.hurt(90,"test")
	check(g.hp==g.max_hp and g.relic_timers.clock==25,"Hourglass negates one hit")
	g.invul = 0
	g.hurt(90,"test")
	check(g.hp<g.max_hp,"Hourglass cooldown prevents permanent invulnerability")
	check(g.hazard_contains({"kind":"line","p":Vector2.ZERO,"angle":0.0,"radius":30},Vector2(100,10)),"Line attack collision")
	check(not g.hazard_contains({"kind":"line","p":Vector2.ZERO,"angle":0.0,"radius":30},Vector2(100,50)),"Line attack dodge lane")
	g = game()
	g.spawn_boss(3)
	g.boss_time = 4
	var meteor = g.boss
	check(g.anchors.size()==3,"Meteor starts with three anchors")
	var dealt = g.hit(meteor,100,"revolver",false)
	check(is_equal_approx(dealt,12.0),"Meteor armor reduces damage by 88%")
	for anchor in g.anchors.duplicate(): g.hit(anchor,100000,"revolver",false)
	check(g.anchors.is_empty() and g.core_time==12,"Destroying anchors opens 12-second core window")
	g.hit(meteor,100000000,"revolver",false)
	check(g.phase==2 and is_equal_approx(meteor.hp,meteor.max_hp*0.67),"Burst cannot skip phase two")
	check(g.anchors.size()==3,"Phase two rebuilds anchors")
	var hp_before = meteor.hp
	g.hit(meteor,100000,"revolver",false)
	check(meteor.hp==hp_before,"Reformation prevents phase skipping")
	g.boss.reform = 0
	for anchor in g.anchors.duplicate(): g.hit(anchor,100000,"revolver",false)
	g.hit(meteor,100000000,"revolver",false)
	check(g.phase==3 and is_equal_approx(meteor.hp,meteor.max_hp*0.34),"Burst cannot skip phase three")
	g.boss.reform = 0
	for anchor in g.anchors.duplicate(): g.hit(anchor,100000,"revolver",false)
	g.hit(meteor,100000000,"revolver",false)
	check(g.won and not g.active,"Victory after all phases")
	g = game(2,"safari")
	g.boss_time = 210
	g.update_boss(0.01)
	check(not g.active and not g.won,"Extinction countdown defeats stalled build")
	g = game()
	g.pos = g.shrine_pos
	for i in range(13): g.update_objectives(1)
	check(g.shrine_done and g.choosing,"Shrine offers relic reward")
	g.choose(0)
	check(g.relics.size()==1,"Relic reward applied")
	g = game()
	for i in range(1000): g.add_gem(Vector2(i,0),1)
	check(g.gems.size()==800,"XP count bounded with merged excess value")
	var total = 0.0
	for gem in g.gems: total+=gem.value
	check(total==1000,"XP merging preserves value")
	if "--fast" in OS.get_cmdline_user_args():
		print("RUN FAST / %s checks / %s failures"%[checks,failures])
		quit(1 if failures else 0)
		return
	# A deterministic accelerated full expedition. Invulnerability is test-only.
	g = game(2)
	g.weapons = {}
	for id in ["frost","fire","lightning","orbital","mortar"]: g.weapons[id] = {"level":10,"evolved":true,"timer":0.1}
	g.passives = {"damage":5,"haste":5,"count":3,"area":4,"crit":5,"speed":2}
	var frame_count = 0
	var start = Time.get_ticks_msec()
	while g.active and frame_count<69000:
		g.hp = g.max_hp
		g.invul = 0.1
		if g.choosing: g.choose(0)
		var target = g.pos+Vector2.from_angle(g.time*0.13)*300
		if g.portal!=null: target = g.portal
		elif g.boss!=null:
			target = g.anchors[0].p+Vector2(0,75) if not g.anchors.is_empty() else g.boss.p+Vector2(0,130)
		g.tick(1.0/60,(target-g.pos).normalized())
		frame_count += 1
	check(g.boss_stage==3 and g.depth==2,"Full expedition reaches final biome and meteor")
	check(g.won,"Strong evolved build can destroy the meteor within the deadline")
	print("SOAK / %.1fs simulated / %s kills / %s peak enemies / %sms wall / boss fight %.1fs"%[g.time,g.kills,g.peak_enemies,Time.get_ticks_msec()-start,g.boss_time])
	# Stationary weak build must not win the finale.
	g = game()
	g.spawn_boss(3)
	g.time = 900
	for i in range(13000):
		if not g.active: break
		g.tick(1.0/60,Vector2.ZERO)
	check(not g.active and not g.won,"Weak stationary build loses meteor encounter")
	print("RESULT / %s checks / %s failures"%[checks,failures])
	quit(1 if failures else 0)
