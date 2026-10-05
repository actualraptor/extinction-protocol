extends SceneTree
const E=preload("res://scripts/expedition.gd")
const Slam=preload("res://scripts/kael_slam.gd")
const Art=preload("res://scripts/kael_attack_animation.gd")
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():
	for map in ["cradle","frostbreak","observatory"]:
		for weapon in ["club","worldbreaker","earthshaker"]:
			var g=E.new();g.setup(1,"expedition",{},114,map);g.enemies.clear()
			var id="club" if weapon=="worldbreaker" else weapon
			g.weapons={id:{"level":1,"evolved":weapon!="club","timer":100}}
			var s=g.Rules.stats(g,id);s.radius=240;s.power=100;s.repeat=0
			var origin=Art.impact_point(g.pos,false)
			var foes=[]
			for distance in [25,115,225]:
				var e=g.spawn_enemy(false,origin+Vector2(distance,0),0);e.p=origin+Vector2(distance,0);e.hp=1e6;e.size=1;e.boss=true
				foes.append(e)
			g.build_grid();var effects=[];g.effect.connect(func(kind,p,c,r):effects.append(kind))
			Slam.impact(g,id,Vector2.RIGHT,s)
			check(foes[0].hp<1e6 and foes[1].hp==1e6 and foes[2].hp==1e6,"Near ring hits first / "+weapon)
			var near=foes[0].hp
			g.time+=.07;g.update_weapons(.07)
			check(foes[1].hp<1e6 and foes[2].hp==1e6,"Middle ring follows before outer")
			for i in range(3):g.time+=.07;g.update_weapons(.07)
			check(foes[2].hp<1e6 and foes[0].hp==near,"Outer propagation; no duplicate near damage")
			var prefix="kael_slam_"+("ice" if map=="frostbreak" else "stone" if map=="observatory" else "dirt")
			check(effects.filter(func(k):return k.begins_with(prefix)).size()==(3 if weapon=="club" else 4),"Biome material and evolved extra band")
			g.echoes.clear();Slam.impact(g,id,Vector2.RIGHT,s);g.weapons.clear();g.update_weapons(.3)
			check(g.echoes.is_empty(),"Retired weapon removes queued radial pulses")
	for id in ["club","earthshaker"]:
		var g=E.new();g.setup(1,"expedition",{},114);g.weapons={id:{"level":10,"evolved":true,"timer":0}}
		g.passives.haste=100
		var e=g.spawn_enemy(false,g.pos+Vector2(70,0),0);e.hp=1e12;e.boss=true;g.build_grid()
		var animated=false
		var sounds=[];g.sound.connect(func(sound):sounds.append(sound))
		for i in range(240):
			g.time+=.016;g.update_weapons(.016)
			animated=animated or not g.kael_attack.is_empty()
			check(g.echoes.size()<=96,"High-haste shock/echo work stays bounded")
		check(g.shots.is_empty(),"Rank-seven shockwave has no linear projectile")
		check(g.weapons[id].casts>2 and animated,"Starter and union keep painted animation")
		g.time+=1;Slam.update(g)
		check(sounds.count("club")==g.weapons[id].casts,"One existing slam sound per cast")
	print("KAEL RADIAL / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
