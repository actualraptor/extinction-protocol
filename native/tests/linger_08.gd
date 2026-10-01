extends SceneTree
const E=preload("res://scripts/expedition.gd")
var failures=0
func check(ok,msg):
	if not ok: failures+=1
	print("PASS / " if ok else "FAIL / ",msg)
func _initialize():
	var g=E.new();g.setup(2,"expedition",{},88,"cradle")
	g.portal=Vector2(1000,0)
	g.linger=20
	check(g.linger_health()==1 and g.linger_damage()==1,"Twenty seconds to collect loot without extra pressure")
	g.linger=45
	check(is_equal_approx(g.linger_health(),2) and is_equal_approx(g.linger_damage(),2),"First pressure tier doubles health and damage")
	g.linger=120
	check(is_equal_approx(g.linger_health(),16) and is_equal_approx(g.linger_damage(),5),"Two minutes raises new enemy HP sixteenfold and damage fivefold")
	check(g.elite_interval()<10,"Lingering accelerates elite arrivals")
	g.linger=220;var a=g.linger_health();g.linger=320
	check(g.linger_health()>a*15,"Health pressure keeps growing beyond old cap")
	g.portal=null
	check(g.linger_health()==1 and g.linger_damage()==1,"Leaving the rift removes pressure")
	g.enemies.clear()
	var prop=g.spawn_enemy(false,Vector2(20,0),0,false);prop.breakable=true
	var hostile=g.spawn_enemy(false,Vector2(80,0),0,false)
	g.build_grid()
	check(g.nearest(g.pos)==hostile,"Auto-targeting prioritizes hostiles over nearby props")
	hostile.dead=true
	check(g.nearest(g.pos)==prop,"Weapons break props when no hostile remains")
	quit(1 if failures else 0)
