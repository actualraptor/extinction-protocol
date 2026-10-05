extends SceneTree
const E=preload("res://scripts/expedition.gd")
const A=preload("res://scripts/starter_attack.gd")
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func make(hero):
	var g=E.new();g.setup(hero,"expedition",{},11012)
	g.enemies.clear();g.pos=Vector2.ZERO
	for w in g.weapons.values():w.timer=0
	var e=g.spawn_enemy(false,Vector2(150,0),0);e.hp=1e9;e.max_hp=e.hp
	g.build_grid();return g
func _initialize():
	for hero in [0,2]:
		var id="revolver" if hero==0 else "lightning"
		var g=make(hero)
		var sounds=[];g.sound.connect(func(s):sounds.append(s))
		g.update_weapons(.001)
		check(not g.starter_attack.is_empty() and g.shots.is_empty() and g.strikes.is_empty(),"Starter begins painted windup before attack")
		check(not id in sounds,"Weapon sound waits for release")
		var a=g.starter_attack;var release_at=a.duration*A.IMPACT_PROGRESS
		check(release_at<=.2 if hero==0 else release_at<=.35,"Quick starter impact")
		g.time=release_at-.0001;A.update(g)
		check(not a.hit,"No early damage")
		var progress=A.progress(g);A.update(g)
		check(A.progress(g)==progress,"Paused simulation time freezes attack pose")
		# Original target dies before impact; cast follows the live replacement.
		g.enemies[0].dead=true;g.enemies[0].hp=0
		var replacement=g.spawn_enemy(false,Vector2(0,180),0);replacement.hp=1e9
		g.build_grid();g.pos=Vector2(10,0);g.time=release_at+.0001;A.update(g)
		check(a.hit and sounds.count(id)==1,"Exactly one impact sound")
		check(a.aim.y>.99,"Release retargets live foe from current moving position")
		check(g.ledger.casts[id]==1 and g.weapons[id].casts==1,"Exactly one cast and relic hook schedule")
		check(g.shots.size()==1 if hero==0 else replacement.hp<1e9,"Projectile/chain releases at impact")
		A.update(g);check(sounds.count(id)==1,"Repeat updates never duplicate release")
		g.starter_attack={};g.weapons[id].timer=0;g.update_weapons(.001)
		g.weapons.erase(id);g.time+=1;A.update(g)
		check(g.starter_attack.is_empty() and sounds.count(id)==1,"Union retirement cancels pending starter")
		# High haste and a coarse frame both resolve all due attacks before
		# replacing a pose, rather than skipping alternate shots.
		for dt in [.016,.20]:
			g=make(hero);g.passives.haste=100
			sounds=[];g.sound.connect(func(s):sounds.append(s))
			for i in range(150):
				g.time+=dt;g.update_weapons(dt);g.shots.clear();g.strikes.clear()
				check(g.starter_attack.size()<=9 and g.volleys.size()<=80,"Bounded starter/volley state")
			g.time+=1;A.update(g)
			check(sounds.count(id)==g.ledger.casts[id],"Every scheduled cast releases at high haste / %s / %s"%[hero,dt])
			check(g.ledger.casts[id]>2,"High haste produces sustained attacks")
		g=make(hero);g.update_weapons(.001);g.finish(false)
		check(g.starter_attack.is_empty(),"Run end cancels windup")
		g=make(hero);g.update_weapons(.001);g.portal={"p":g.pos};g.enter_portal()
		check(g.starter_attack.is_empty(),"Portal transition cancels windup")
	var gun=make(0);gun.passives.count=3;gun.update_weapons(.001)
	gun.time=.25;A.update(gun)
	check(not gun.volleys.is_empty(),"Extra rounds queued at release")
	gun.enemies[0].p=Vector2(0,180);gun.build_grid();gun.shots.clear()
	gun.update_weapons(.12)
	check(not gun.shots.is_empty() and gun.shots[0].v.y>absf(gun.shots[0].v.x),"Follow-up volley tracks live aim instead of stale windup direction")
	gun.time+=1;gun.weapons.revolver.timer=0;gun.update_weapons(.01)
	gun.time+=1;gun.update_weapons(1)
	check(is_equal_approx(A.progress(gun),.67),"Release pose survives scheduling the next cast on a coarse frame")
	var ordinary=make(1);ordinary.weapons={"revolver":{"level":1,"timer":0,"evolved":false}}
	ordinary.update_weapons(.001)
	check(ordinary.starter_attack.is_empty() and ordinary.shots.size()==1,"Other character gear stays automatic")
	print("STARTER ATTACK / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)

