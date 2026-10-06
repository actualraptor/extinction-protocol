extends SceneTree
const Contact=preload("res://scripts/army_collision.gd")
const E=preload("res://scripts/expedition.gd")
var checks=0
var failures=0
func check(ok,why):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",why)
func _initialize():
	var c=Contact.new()
	var u={"p":Vector2.ZERO,"hp":100.0,"role":"colossus","uid":1,"champion":false}
	var e={"p":Vector2(-120,0),"size":22.0,"boss":false,"uid":2}
	c.build([u])
	for end in [Vector2(-10,0),Vector2(120,0),Vector2(-100,80)]:
		var p=c.block_enemy(e,e.p,end)
		check(p.distance_to(u.p)>=Contact.radius(u)+Contact.enemy_radius(e),"Enemy stays outside minion body")
		if end.x>0:check(p.x<0,"Charge cannot tunnel through a minion")
	u.hp=0;c.build([u]);check(c.block_enemy(e,e.p,Vector2(120,0))==Vector2(120,0),"Dead minions stop blocking immediately")
	u.hp=100;c.build([u]);check(c.block_enemy(e,Vector2.ZERO,Vector2.ZERO).length()>50,"Existing overlap resolves deterministically")
	var g=E.new();g.setup(5,"expedition",{},42);g.enemies.clear();g.companions.units.clear()
	var foe=g.spawn_enemy(false,g.pos+Vector2(30,0),0);foe.hp=100000;foe.max_hp=100000;g.build_grid()
	u.p=g.pos;u.role="warrior";u.uid=1
	var moved=Contact.move_minion(g,u,foe.p)
	check(moved.distance_to(foe.p)>=Contact.radius(u)+Contact.enemy_radius(foe),"Minion movement respects enemy body")
	g.weapons.u00={"level":1,"evolved":false,"timer":0.0};g.companions.summon(g,"u00")
	var ally=g.companions.units[0];ally.p=g.pos;ally.hp=100000;ally.attack=0;ally.search=0
	g.companions.update(g,.05)
	check(ally.has("swing"),"Collision still permits melee attacks at contact")
	check(ally.hp<100000,"Contact can still injure summons")
	u.p=Vector2.ZERO;u.hp=100;c.build([u]);e.boss=true
	var end=Vector2(120,0)
	check(c.block_enemy(e,Vector2(-120,0),end)==end,"Boss charge preserves full movement")
	check(u.p.distance_to(Vector2.ZERO)>Contact.radius(u)+Contact.enemy_radius(e),"Boss shoves minion beside swept path")
	e.boss=false
	var bodies=[]
	for i in range(64):bodies.append({"p":Vector2(i%8*55,i/8*55),"hp":100.0,"role":"warrior","uid":i+1,"champion":false})
	c.build(bodies)
	var start=Time.get_ticks_usec()
	for i in range(2000):
		var p=Vector2((i%50)*30-200,(i/50)*30-200)
		e.uid=i+1;c.block_enemy(e,p,p+Vector2(10,0))
	print("CONTACT / 2000 bodies vs 64 summons / ",(Time.get_ticks_usec()-start)/1000.0," ms")
	print("ARMY CONTACT / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
