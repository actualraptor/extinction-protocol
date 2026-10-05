extends SceneTree
const E=preload("res://scripts/expedition.gd")
const Slam=preload("res://scripts/kael_slam.gd")
const Combat=preload("res://scripts/combat_engine.gd")
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():
	for cadence in [1.5,.4,.12]:
		var g=E.new();g.setup(1,"expedition",{},144)
		g.enemies.clear()
		var e=g.spawn_enemy(false,g.pos+Vector2(70,0));e.hp=100000;e.max_hp=e.hp
		g.build_grid()
		var s=g.Rules.stats(g,"club");s.cooldown=cadence;s.repeat=0
		var sounds=[];g.sound.connect(func(id):sounds.append(id))
		Slam.start(g,"club",Vector2.RIGHT,s)
		check(e.hp==100000,"No damage before impact")
		g.time=g.kael_attack.duration*.61;Slam.update(g)
		check(e.hp==100000,"Windup preserves health")
		g.pos+=Vector2(5,0);g.time=g.kael_attack.duration*.63;Slam.update(g)
		check(e.hp<100000 and sounds.count("club")==1,"Exactly one impact and sound / "+str(cadence))
		var hp=e.hp;Slam.update(g);check(e.hp==hp,"No duplicate impact at same timestamp")
		check(is_equal_approx(Slam.progress(g),.67),"Impact pose held briefly")
		g.time=cadence;Slam.update(g);check(g.kael_attack.is_empty(),"Recovery finishes before next attack")
		Slam.start(g,"club",Vector2.LEFT,s);g.weapons.erase("club");g.time+=cadence;Slam.update(g)
		check(g.kael_attack.is_empty() and e.hp==hp,"Removed weapon cancels pending slam")
	var g=E.new();g.setup(1,"expedition",{},55);g.spawn_boss(1);g.boss_time=4;g.boss.p=g.pos+Vector2(50,0)
	g.build_grid();var at=g.boss.p;var hp=g.boss.hp;Slam.impact(g,"club",Vector2.RIGHT,g.Rules.stats(g,"club"))
	check(g.boss.p==at and g.boss.hp<hp,"Slam damages bosses without moving them")
	var t=g.time;Slam.start(g,"club",Vector2.RIGHT,g.Rules.stats(g,"club"));g.choosing=true;g.tick(.2,Vector2.RIGHT)
	check(g.time==t and not g.kael_attack.hit,"Choices freeze simulation windup")
	print("KAEL SLAM / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
