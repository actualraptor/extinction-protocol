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
	for id in ["club","earthshaker"]:
		for cadence in [1.5,.4,.12,.04,.02]:
			var g=E.new();g.setup(1,"expedition",{},144)
			g.weapons.clear();g.weapons[id]={"level":1,"evolved":id=="earthshaker","timer":9999,"casts":0}
			g.enemies.clear()
			var e=g.spawn_enemy(false,g.pos+Vector2(60,0));e.hp=10000000;e.max_hp=e.hp
			g.build_grid()
			var s=g.Rules.stats(g,id);s.cooldown=cadence;s.repeat=0
			var impacts=[];g.sound.connect(func(sound):if sound=="club":impacts.append(g.time))
			var next=0.0;var casts=0
			for frame in range(600):
				g.time=frame/120.0
				Combat.update(g,1.0/120)
				if g.time>=next and casts<100:
					Slam.start(g,id,Vector2.RIGHT,s);casts+=1;next=g.time+cadence
				check(g.echoes.size()<=96,"Bounded pending fronts")
			# Drain remaining impact and rings without starting another attack.
			for frame in range(120):g.time+=1.0/120;Combat.update(g,1.0/120)
			check(impacts.size()==casts,"Every rapid attack impacts / "+id+" / "+str(cadence))
			check(e.hp<10000000,"Attacks still damage at extreme cadence")
			check(g.echoes.is_empty(),"No stranded damage fronts")
			g.kael_attack.clear();g.echoes.clear();g.enemies.clear();g.weapons.clear();g.boss=null
			for signal_name in ["sound","effect","banner","choice_requested","ended","discovered_content","voice_event"]:
				for connection in g.get_signal_connection_list(signal_name):g.disconnect(signal_name,connection.callable)
	var world=preload("res://scripts/world.gd").new()
	world.fx("ring",Vector2.ZERO,Color.WHITE,100)
	for i in range(500):world.fx("kael_slam_dirt_1_3_100",Vector2.ZERO,Color.WHITE,200)
	check(world.effects.size()==65,"64 Kael effects plus unrelated effect")
	check(world.effects[0].kind=="ring","Kael budget preserves other effects")
	check(is_equal_approx(world.effects[-1].life,.10),"Rapid effects use short lifetime")
	world.free()
	print("KAEL CADENCE / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
