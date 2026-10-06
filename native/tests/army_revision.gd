extends SceneTree
const E=preload("res://scripts/expedition.gd")
const R=preload("res://scripts/remnant_system.gd")
var checks=0
var failures=0
func check(ok,message):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():
	var g=E.new();g.setup(5,"expedition",{},87);g.enemies.clear();g.companions.units.clear()
	for id in ["u00","u03"]:g.weapons[id]={"level":1,"evolved":false,"timer":100}
	for identity in R.IDENTITIES:
		check(g.companions.raise_remnant(g,{"identity":identity,"p":g.pos}),"All six boss identities can coexist")
	check(not g.companions.raise_remnant(g,{"identity":"thorn","p":g.pos}),"No duplicate living boss identity")
	var boss=g.companions.units[0];boss.hp=0
	g.companions.update(g,.05)
	check(not g.companions.fallen_remnant.is_empty(),"Fallen boss starts soul restoration")
	var victim={"anchor":false,"boss":false,"elite":false,"unit_hit":false,"p":g.pos}
	for j in range(1999):g.companions.on_kill(g,victim)
	check(not g.companions.fallen_remnant.is_empty(),"Restoration does not trigger before cost")
	g.companions.on_kill(g,victim)
	check(g.companions.fallen_remnant.is_empty(),"Restoration triggers at 2000 new souls")
	check(g.companions.units.filter(func(u):return u.get("boss_form",false) and u.identity=="thorn").size()==1,"Restored boss returns once")
	g.companions.units.clear();g.companions.summon(g,"u00")
	var ally=g.companions.units[0];ally.p=g.pos+Vector2(400,0)
	g.gems=[{"p":ally.p+Vector2(70,0),"value":1.0,"magnet":false}];g.update_gems(.01)
	check(g.gems[0].magnet,"Minion attracts nearby XP to master")
	g.weapons.u03={"level":1,"evolved":false,"timer":100};g.companions.summon(g,"u03")
	var spirit=g.companions.units[-1];spirit.p=g.pos;spirit.attack=0
	var foe=g.spawn_enemy(false,g.pos+Vector2(90,0),0);foe.hp=100000;foe.max_hp=100000;g.build_grid()
	g.companions.update_wraith(g,spirit,.01)
	check(spirit.flight=="outbound","Wraith acquires outbound pass")
	for j in range(70):g.time+=.02;g.companions.update_wraith(g,spirit,.02)
	check(foe.hp<100000,"Wraith damages on swept pass")
	check(not spirit.has("swing"),"Wraith never uses melee swing")
	check(spirit.get("flight","") in ["orbit","outbound","return"],"Flight cycle remains valid")
	for id in g.C.WEAPONS:
		if g.C.WEAPONS[id].get("role","")!="chill":continue
		g.weapons[id]={"level":1,"evolved":false,"timer":0}
		var before=foe.hp
		g.companions.cast(g,id,g.Rules.stats(g,id))
		check(foe.hp<before and foe.slow>0,"Chill aura damages and slows enemies in range")
	var solid=g.companions.units[0];solid.p=g.pos;solid.hp=100000
	g.companions.collision.build(g.companions.units)
	var adjusted=g.companions.collision.block_enemy(foe,solid.p,solid.p)
	check(adjusted.distance_to(solid.p)>=g.companions.Contact.radius(solid)+g.companions.Contact.enemy_radius(foe),"Late positional overlap resolves outside enlarged summon body")
	g.weapons.u07={"level":10,"evolved":true,"timer":100};g.kills=14;g.companions.pending.clear()
	g.companions.on_kill(g,victim)
	check(g.companions.pending.size()==2,"Evolved reanimate queues two warriors")
	check(g.companions.pending.all(func(event):return event.get("lifetime",0)==18),"Evolved warriors last eighteen seconds")
	print("ARMY REVISION / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
