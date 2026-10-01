extends SceneTree
const E = preload("res://scripts/expedition.gd")
var failures = 0
func check(value,label):
	print("PASS / " if value else "FAIL / ",label)
	if not value: failures += 1
func _initialize():
	for evolved in [false,true]:
		var g = E.new()
		g.setup(2,"expedition",{},426)
		g.weapons = {"mortar":{"level":1,"evolved":evolved,"timer":0.0}}
		if not evolved: g.augments = {"linger":1}
		g.passives = {"count":2}
		var target = g.spawn_enemy(false,Vector2(180,0),0,false)
		target.hp = 100000
		g.build_grid()
		g.update_weapons(0.01)
		check(g.zones.size()>=3,"Mortar creates persistent ground for "+("evolution" if evolved else "Scorched Earth"))
		for i in range(g.zones.size()):
			check(g.zones[i].scorched and is_equal_approx(g.zones[i].radius,g.hazards[i].radius),"Visible crater uses impact damage footprint")
			check(is_equal_approx(g.zones[i].wait,0.74+i*0.12),"Crater waits for its own shell")
		g.weapons.clear()
		g.zones = [{"p":Vector2(180,0),"radius":60.0,"id":"mortar","damage":10.0,"wait":0.5,"life":1.5,"duration":1.5,"age":0.0,"scorched":true}]
		g.passives.clear()
		g.augments.clear()
		g.modifier_cache.clear()
		target.size = 10
		var outside = g.spawn_enemy(false,Vector2(270,0),0,false)
		outside.hp = 100000
		outside.size = 10
		g.build_grid()
		var old = target.hp
		g.update_weapons(0.4)
		check(target.hp==old,"No ground damage before shell lands")
		for frame in range(63): g.update_weapons(1.0/30)
		check(target.hp<old,"Visible burning ground damages occupants")
		check(outside.hp==100000,"No damage outside crater footprint")
		check(g.zones.is_empty(),"Crater expires without invisible lingering damage")
		old = target.hp
		g.update_weapons(1.0)
		check(target.hp==old,"Expired crater cannot damage")
	var g = E.new()
	g.setup(2,"expedition",{},427)
	var boss = g.spawn_enemy(false,Vector2(180,0),0,false)
	boss.boss = true
	boss.hp = 100000
	g.build_grid()
	var field_hit = g.hit(boss,10,"mortar",false,true,"field")
	var shell_hit = g.hit(boss,100,"mortar",false)
	check(field_hit>0 and shell_hit>field_hit,"Weak ground tick cannot discard strong shell impact")
	check(g.hit(boss,10,"mortar",false,true,"field")==0,"Overlapping mortar fields retain boss repeat cap")
	check(g.hit(boss,100,"mortar",false)==0,"Overlapping shell impacts retain boss repeat cap")
	check(g.hit(boss,5,"mortar",false,false)>0,"Burn ticks have independent bounded cadence")
	check(g.hit(boss,5,"mortar",false,false)==0,"Status damage remains bounded")
	quit(failures)
