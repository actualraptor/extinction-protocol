extends SceneTree
const E=preload("res://scripts/expedition.gd")
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():
	for map_id in ["cradle","frostbreak","observatory"]:
		for stage in [1,2,3]:
			var g=E.new();g.setup(1,"expedition",{},77,map_id);g.spawn_boss(stage)
			check(g.boss.hp==[90000.0,900000.0,30000000.0][stage-1] and g.boss.hp==g.boss.max_hp,"Tenfold roaming / fivefold meteor HP / "+map_id+str(stage))
			g.boss_time=4;g.anchors.clear();g.core_time=0
			var damage=g.hit(g.boss,100,"revolver",false,false)
			check(is_equal_approx(damage,[50.0,40.0,30.0][stage-1]),"Innate DR still applies once")
			g.daily_loop=2;g.spawn_boss(stage)
			check(g.boss.max_hp==[90000.0,900000.0,30000000.0][stage-1]*4,"Daily circuit scaling preserved")
	var g=E.new();g.setup(1,"expedition",{},88);g.spawn_boss(3)
	check(g.anchors.size()==3 and g.anchors[0].hp==3750,"Anchors remain breakable weak points")
	print("BOSS HEALTH / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
