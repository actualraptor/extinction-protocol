extends SceneTree
const E=preload("res://scripts/expedition.gd")
const A=preload("res://scripts/starter_attack.gd")
const Art=preload("res://scripts/hero_attack_animation.gd")
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():
	for map in ["cradle","frostbreak","observatory"]:
		for stage in [1,2,3]:
			var g=E.new();g.setup(1,"expedition",{},113,map);g.spawn_boss(stage)
			var b=g.boss;var original=b.p
			g.pos=b.p+Vector2(260,220);g.invul=100
			for i in range(30):g.update_enemies(1.0/30.0)
			check(b.p==original if stage==3 else b.p.distance_to(original)>30,"Only meteor remains stationary / %s / %s"%[map,stage])
			if stage<3:
				check(b.p.distance_to(g.pos)<original.distance_to(g.pos),"Recovery chases player")
				check(b.p.x!=original.x and b.p.y!=original.y,"Boss pursuit is diagonal")
				b.action="windup";original=b.p;g.update_enemies(.1)
				check(b.p==original,"Committed telegraph holds position")
				b.action="recover";b.reform=1;g.update_enemies(.1)
				check(b.p==original,"Reformation holds position")
			check(b.hp==b.max_hp,"Pursuit never changes health")
	for hero in [0,2]:
		for seasonal in [false,true]:
			for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
				var g=E.new();g.setup(hero,"expedition",{},113);g.halloween=seasonal
				g.enemies.clear();g.pos=Vector2(300,300)
				var enemy=g.spawn_enemy(false,g.pos+direction*300,0);enemy.p=g.pos+direction*300;enemy.hp=1e8
				g.build_grid()
				var id="revolver" if hero==0 else "lightning"
				A.start(g,id,direction,g.Rules.stats(g,id));g.time+=1;A.update(g)
				var expected=g.pos+Art.emission_offset(hero,seasonal,direction.x<0)
				check(expected.distance_to(g.pos)>30,"Real painted tip is separated from body center")
				if hero==0:
					check(g.shots[0].p.is_equal_approx(expected),"Bullet starts exactly at painted muzzle")
					check(g.shots[0].v.normalized().dot((enemy.p-expected).normalized())>.9999,"Bullet aims from muzzle to target in all directions")
					g.pos+=Vector2(25,15)
					A.volley(g,{"id":id,"dir":direction,"power":1,"velocity":500,"life":1,"pierce":1})
					check(g.shots[-1].p.is_equal_approx(g.pos+Art.emission_offset(hero,seasonal,enemy.p.x<g.pos.x)),"Follow-up muzzle follows moving player")
					check(is_equal_approx(A.progress(g),.67),"Follow-up shot displays release pose")
				else:
					check(g.strikes[0].a.is_equal_approx(expected),"Lightning begins exactly at painted crystal")
					check(g.strikes[0].b.is_equal_approx(enemy.p),"Lightning reaches live target")
	var edge=E.new();edge.setup(2,"expedition",{},3);edge.enemies.clear();edge.pos=Vector2.ZERO
	var enemy=edge.spawn_enemy(false,Vector2(0,675),0);enemy.p=Vector2(0,675);enemy.hp=1e8;edge.build_grid()
	A.start(edge,"lightning",Vector2.DOWN,edge.Rules.stats(edge,"lightning"));edge.time=1;A.update(edge)
	check(not edge.strikes.is_empty(),"Staff tip does not reduce ground targeting range")
	print("BOSS PURSUIT + EMISSION / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
